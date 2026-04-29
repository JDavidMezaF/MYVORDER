const db = require('../config/db');

// GET /api/mesas/:idRestaurante — listar mesas de un restaurante
const getMesasByRestaurante = (req, res) => {
  const { idRestaurante } = req.params;
  const sql = 'SELECT * FROM mesa WHERE RestauranteID = ? ORDER BY NumeroMesa ASC';
  db.query(sql, [idRestaurante], (err, results) => {
    if (err) {
      console.error('Error al obtener mesas:', err);
      return res.status(500).json({ error: 'Error al obtener mesas' });
    }
    res.json(results);
  });
};

// POST /api/mesas — crear nueva mesa
const crearMesa = (req, res) => {
  const { RestauranteID, NumeroMesa, Capacidad, Estado } = req.body;

  if (!RestauranteID || !NumeroMesa || !Capacidad) {
    return res.status(400).json({ error: 'RestauranteID, NumeroMesa y Capacidad son obligatorios' });
  }

  const estadoFinal = Estado || 'disponible';
  const sql = 'INSERT INTO mesa (RestauranteID, NumeroMesa, Capacidad, Estado) VALUES (?, ?, ?, ?)';

  db.query(sql, [RestauranteID, NumeroMesa, Capacidad, estadoFinal], (err, result) => {
    if (err) {
      console.error('Error al crear mesa:', err);
      return res.status(500).json({ error: 'Error al crear mesa' });
    }
    res.status(201).json({
      message: 'Mesa creada correctamente',
      MesaID: result.insertId,
      RestauranteID,
      NumeroMesa,
      Capacidad,
      Estado: estadoFinal,
    });
  });
};

// DELETE /api/mesas/:id — eliminar mesa
const eliminarMesa = (req, res) => {
  const { id } = req.params;
  const sql = 'DELETE FROM mesa WHERE MesaID = ?';
  db.query(sql, [id], (err, result) => {
    if (err) {
      console.error('Error al eliminar mesa:', err);
      return res.status(500).json({ error: 'Error al eliminar mesa' });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Mesa no encontrada' });
    }
    res.json({ message: 'Mesa eliminada correctamente' });
  });
};

module.exports = { getMesasByRestaurante, crearMesa, eliminarMesa };
