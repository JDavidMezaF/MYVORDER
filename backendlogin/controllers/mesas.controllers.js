const db = require('../config/db');

// GET /api/mesas/:idRestaurante — listar mesas de un restaurante
exports.getMesasByRestaurante = async (req, res) => {
  try {
    const { idRestaurante } = req.params;

    const [rows] = await db.query(
      `SELECT 
        MesaID,
        RestauranteID,
        NumeroMesa,
        Capacidad,
        Estado
      FROM mesa
      WHERE RestauranteID = ?
      ORDER BY NumeroMesa ASC`,
      [idRestaurante]
    );

    res.json(rows);
  } catch (error) {
    console.error('ERROR al obtener mesas:', error);
    res.status(500).json({ message: error.message });
  }
};

// POST /api/mesas — crear nueva mesa
exports.crearMesa = async (req, res) => {
  try {
    const { RestauranteID, NumeroMesa, Capacidad, Estado } = req.body;

    if (!RestauranteID || !NumeroMesa || !Capacidad) {
      return res.status(400).json({ message: 'RestauranteID, NumeroMesa y Capacidad son obligatorios' });
    }

    const estadoFinal = Estado || 'disponible';

    const [result] = await db.query(
      `INSERT INTO mesa (RestauranteID, NumeroMesa, Capacidad, Estado) VALUES (?, ?, ?, ?)`,
      [RestauranteID, NumeroMesa, Capacidad, estadoFinal]
    );

    res.status(201).json({
      message: 'Mesa creada correctamente',
      MesaID: result.insertId,
      RestauranteID,
      NumeroMesa,
      Capacidad,
      Estado: estadoFinal,
    });
  } catch (error) {
    console.error('ERROR al crear mesa:', error);
    res.status(500).json({ message: error.message });
  }
};

// DELETE /api/mesas/:id — eliminar mesa
exports.eliminarMesa = async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await db.query(
      'DELETE FROM mesa WHERE MesaID = ?',
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Mesa no encontrada' });
    }

    res.json({ message: 'Mesa eliminada correctamente' });
  } catch (error) {
    console.error('ERROR al eliminar mesa:', error);
    res.status(500).json({ message: error.message });
  }
};