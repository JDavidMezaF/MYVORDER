const db = require('../config/db');

// POST /api/pedidos — crear pedido completo con detalles y ticket
exports.crearPedido = async (req, res) => {
  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();

    const { MesaID, platillos } = req.body;
    // platillos = [{ MenuID, Nombre, Cantidad, PrecioUnitario }]

    if (!MesaID || !platillos || platillos.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({ message: 'MesaID y platillos son obligatorios' });
    }

    // 1. Calcular total
    const total = platillos.reduce((sum, p) => sum + p.PrecioUnitario * p.Cantidad, 0);

    // 2. Insertar en tabla pedido
    const [pedidoResult] = await connection.query(
      `INSERT INTO pedido (MesaID, FechaHora, Estado) VALUES (?, NOW(), 'pendiente')`,
      [MesaID]
    );
    const pedidoID = pedidoResult.insertId;

    // 3. Insertar cada detalle
    for (const p of platillos) {
      const subtotal = p.PrecioUnitario * p.Cantidad;
      await connection.query(
        `INSERT INTO detallepedido (PedidoID, MenuID, Cantidad, PrecioUnitario, Subtotal)
         VALUES (?, ?, ?, ?, ?)`,
        [pedidoID, p.MenuID, p.Cantidad, p.PrecioUnitario, subtotal]
      );
    }

    // 4. Insertar ticket
    const [ticketResult] = await connection.query(
      `INSERT INTO ticket (PedidoID, MesaID, FechaHora, Total, Estado)
       VALUES (?, ?, NOW(), ?, 'pendiente')`,
      [pedidoID, MesaID, total]
    );

    await connection.commit();
    connection.release();

    res.status(201).json({
      message: 'Pedido creado correctamente',
      PedidoID: pedidoID,
      TicketID: ticketResult.insertId,
      Total: total,
    });

  } catch (error) {
    await connection.rollback();
    connection.release();
    console.error('ERROR al crear pedido:', error);
    res.status(500).json({ message: error.message });
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
