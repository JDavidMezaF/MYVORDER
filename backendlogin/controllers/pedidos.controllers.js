const db = require('../config/db');

// Reparte `centavos` en partes iguales entre n personas.
// Si sobran centavos, se reparten de 1 en 1 a las primeras personas.
const repartirEnCentavos = (centavos, n) => {
  const base = Math.floor(centavos / n);
  const sobrante = centavos - base * n;
  return Array.from({ length: n }, (_, i) => base + (i < sobrante ? 1 : 0));
};

class ErrorValidacion extends Error {
  constructor(message) {
    super(message);
    this.status = 400;
  }
}

const esIdValido = (id) => Number.isInteger(id) && id > 0;

// POST /api/pedidos
// Body: {
//   MesaID: 3,
//   integrantes: [12, 15, 20],                       // UsuarioID de cada persona en la mesa
//   platillos: [
//     { MenuID: 5, Cantidad: 2, asignados: [12, 15] } // quiénes pagan este platillo
//   ]
// }
exports.crearPedido = async (req, res) => {
  const { MesaID, integrantes, platillos } = req.body;
  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    if (!MesaID || !Array.isArray(integrantes) || integrantes.length === 0 ||
        !Array.isArray(platillos) || platillos.length === 0) {
      throw new ErrorValidacion('MesaID, integrantes y platillos son obligatorios');
    }

    // 1. La mesa existe
    const [mesas] = await connection.query(
      'SELECT MesaID, RestauranteID, Capacidad FROM mesa WHERE MesaID = ?',
      [MesaID]
    );
    if (mesas.length === 0) throw new ErrorValidacion('Mesa no encontrada');
    const mesa = mesas[0];

    // 2. Integrantes: entre 1 y la capacidad de la mesa, sin repetidos, todos existen
    const idsIntegrantes = [...new Set(integrantes.map(Number))];
    if (!idsIntegrantes.every(esIdValido)) {
      throw new ErrorValidacion('Integrantes inválidos');
    }
    if (mesa.Capacidad != null && idsIntegrantes.length > mesa.Capacidad) {
      throw new ErrorValidacion(`La mesa solo admite ${mesa.Capacidad} personas`);
    }
    const [usuarios] = await connection.query(
      'SELECT UsuarioID FROM usuario WHERE UsuarioID IN (?)',
      [idsIntegrantes]
    );
    if (usuarios.length !== idsIntegrantes.length) {
      throw new ErrorValidacion('Alguno de los integrantes no existe');
    }

    // 3. Platillos: precio SIEMPRE desde la BD, nunca del cliente
    const idsMenu = [...new Set(platillos.map((p) => Number(p.MenuID)))];
    if (!idsMenu.every(esIdValido)) throw new ErrorValidacion('Platillos inválidos');

    const [menus] = await connection.query(
      'SELECT MenuID, Nombre, Precio, Disponibilidad FROM menu WHERE RestauranteID = ? AND MenuID IN (?)',
      [mesa.RestauranteID, idsMenu]
    );
    const menuPorId = new Map(menus.map((m) => [m.MenuID, m]));

    const lineas = [];
    for (const p of platillos) {
      const menu = menuPorId.get(Number(p.MenuID));
      if (!menu) throw new ErrorValidacion(`El platillo ${p.MenuID} no existe en este restaurante`);
      if (Number(menu.Disponibilidad) === 0) {
        throw new ErrorValidacion(`"${menu.Nombre}" no está disponible`);
      }

      const cantidad = Number(p.Cantidad);
      if (!Number.isInteger(cantidad) || cantidad <= 0) {
        throw new ErrorValidacion(`Cantidad inválida para "${menu.Nombre}"`);
      }

      const asignados = [...new Set((p.asignados || []).map(Number))];
      if (asignados.length === 0) {
        throw new ErrorValidacion(`Asigna al menos una persona a "${menu.Nombre}"`);
      }
      if (!asignados.every((id) => idsIntegrantes.includes(id))) {
        throw new ErrorValidacion(`"${menu.Nombre}" está asignado a alguien que no está en la mesa`);
      }

      const precio = Number(menu.Precio);
      lineas.push({
        MenuID: menu.MenuID,
        cantidad,
        precio,
        subtotalCentavos: Math.round(precio * 100) * cantidad,
        asignados,
      });
    }

    // 4. Insertar pedido
    const [pedidoResult] = await connection.query(
      `INSERT INTO pedido (MesaID, FechaHora, Estado) VALUES (?, NOW(), 'pendiente')`,
      [MesaID]
    );
    const pedidoID = pedidoResult.insertId;

    // 5. Insertar integrantes
    for (const usuarioID of idsIntegrantes) {
      await connection.query(
        'INSERT INTO pedido_integrante (PedidoID, UsuarioID) VALUES (?, ?)',
        [pedidoID, usuarioID]
      );
    }

    // 6. Insertar detalle y repartir cada platillo entre sus asignados
    const totalPorUsuario = new Map(idsIntegrantes.map((id) => [id, 0])); // en centavos
    let totalPedido = 0;

    for (const l of lineas) {
      const [detalleResult] = await connection.query(
        `INSERT INTO detallepedido (PedidoID, MenuID, Cantidad, PrecioUnitario, Subtotal)
         VALUES (?, ?, ?, ?, ?)`,
        [pedidoID, l.MenuID, l.cantidad, l.precio, l.subtotalCentavos / 100]
      );
      const detalleID = detalleResult.insertId;

      const partes = repartirEnCentavos(l.subtotalCentavos, l.asignados.length);
      for (let i = 0; i < l.asignados.length; i++) {
        await connection.query(
          'INSERT INTO detalle_asignacion (DetalleID, UsuarioID, Monto) VALUES (?, ?, ?)',
          [detalleID, l.asignados[i], partes[i] / 100]
        );
        totalPorUsuario.set(l.asignados[i], totalPorUsuario.get(l.asignados[i]) + partes[i]);
      }
      totalPedido += l.subtotalCentavos;
    }

    // 7. Un ticket personal por cada integrante que tenga algo que pagar
    const tickets = [];
    for (const [usuarioID, centavos] of totalPorUsuario) {
      if (centavos === 0) continue;
      const [ticketResult] = await connection.query(
        `INSERT INTO ticket (UsuarioID, PedidoID, MesaID, FechaHora, Total, Estado)
         VALUES (?, ?, ?, NOW(), ?, 'pendiente')`,
        [usuarioID, pedidoID, MesaID, centavos / 100]
      );
      tickets.push({ TicketID: ticketResult.insertId, UsuarioID: usuarioID, Total: centavos / 100 });
    }

    await connection.commit();

    res.status(201).json({
      message: 'Pedido creado correctamente',
      PedidoID: pedidoID,
      Total: totalPedido / 100,
      Tickets: tickets,
    });

  } catch (error) {
    await connection.rollback().catch(() => {});
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    console.error('ERROR al crear pedido:', error);
    res.status(500).json({ message: error.message });
  } finally {
    connection.release();
  }
};

// GET /api/pedidos/:mesaID — obtener pedidos activos de una mesa
exports.obtenerPedidosPorMesa = async (req, res) => {
  try {
    const { mesaID } = req.params;

    const [rows] = await db.query(
      `SELECT p.PedidoID, p.MesaID, p.FechaHora, p.Estado
       FROM pedido p
       WHERE p.MesaID = ? AND p.Estado = 'pendiente'
       ORDER BY p.FechaHora DESC`,
      [mesaID]
    );

    res.json(rows);
  } catch (error) {
    console.error('ERROR al obtener pedidos:', error);
    res.status(500).json({ message: error.message });
  }
};