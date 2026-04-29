const db = require('../config/db');

// Obtener tickets de un restaurante por email
exports.obtenerTicketsPorRestaurante = async (req, res) => {
  try {
    const { email } = req.params;

    // 1. Obtener RestauranteID desde el email
    const [restRows] = await db.query(
      "SELECT RestauranteID FROM restaurante WHERE email = ?",
      [email]
    );

    if (restRows.length === 0) {
      return res.status(404).json({ message: "Restaurante no encontrado" });
    }

    const restauranteID = restRows[0].RestauranteID;

    // 2. Obtener tickets con info de mesa
    const [tickets] = await db.query(
      `SELECT 
        t.TicketID,
        t.UsuarioID,
        t.PedidoID,
        t.MesaID,
        t.FechaHora,
        t.Total,
        t.Estado,
        m.NumeroMesa,
        m.Capacidad
      FROM ticket t
      INNER JOIN mesa m ON t.MesaID = m.MesaID
      WHERE m.RestauranteID = ?
      ORDER BY t.FechaHora DESC`,
      [restauranteID]
    );

    // 3. Para cada ticket, obtener el detalle de platillos
    for (const ticket of tickets) {
      const [detalles] = await db.query(
        `SELECT 
          dp.DetalleID,
          dp.Cantidad,
          dp.PrecioUnitario,
          dp.Subtotal,
          mn.Nombre as nombrePlatillo,
          mn.Categoria as categoria
        FROM detallepedido dp
        INNER JOIN menu mn ON dp.MenuID = mn.MenuID
        WHERE dp.PedidoID = ?`,
        [ticket.PedidoID]
      );
      ticket.detalles = detalles;
    }

    res.json({ restauranteID, tickets });

  } catch (error) {
    console.error("ERROR al obtener tickets:", error);
    res.status(500).json({ message: error.message });
  }
};

// Actualizar estado de un ticket (Pendiente → Pagado)
exports.actualizarEstadoTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return res.status(400).json({ message: "El estado es obligatorio" });
    }

    const [result] = await db.query(
      "UPDATE ticket SET Estado = ? WHERE TicketID = ?",
      [estado, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Ticket no encontrado" });
    }

    res.json({ message: "Estado actualizado correctamente" });

  } catch (error) {
    console.error("ERROR al actualizar ticket:", error);
    res.status(500).json({ message: error.message });
  }
};
