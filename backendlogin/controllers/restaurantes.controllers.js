const db = require('../config/db');

// Crear restaurante
exports.crearRestaurante = async (req, res) => {
  try {
    const { nombre, logo } = req.body;

    if (!nombre) {
      return res.status(400).json({ message: "El nombre es obligatorio" });
    }

    const [result] = await db.query(
      "INSERT INTO restaurante (nombre, logo) VALUES (?, ?)",
      [nombre, logo || null]
    );

    res.status(201).json({
      message: "Restaurante creado correctamente",
      idRestaurante: result.insertId
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Error al crear restaurante" });
  }
};

// Obtener restaurantes
exports.obtenerRestaurantes = async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT 
        RestauranteID as id,
        Nombre as nombre,
        logo
      FROM restaurante
    `);
    res.json(rows);
  } catch (error) {
    console.error("ERROR REAL:", error);
    res.status(500).json({ message: error.message });
  }
};

// Editar restaurante
exports.editarRestaurante = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, logo } = req.body;

    if (!nombre) {
      return res.status(400).json({ message: "El nombre es obligatorio" });
    }

    const [result] = await db.query(
      "UPDATE restaurante SET Nombre = ?, logo = ? WHERE RestauranteID = ?",
      [nombre, logo || null, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Restaurante no encontrado" });
    }

    res.json({ message: "Restaurante actualizado correctamente" });

  } catch (error) {
    console.error("ERROR al editar restaurante:", error);
    res.status(500).json({ message: error.message });
  }
};

// Eliminar restaurante
exports.eliminarRestaurante = async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await db.query(
      "DELETE FROM restaurante WHERE RestauranteID = ?",
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Restaurante no encontrado" });
    }

    res.json({ message: "Restaurante eliminado correctamente" });

  } catch (error) {
    console.error("ERROR al eliminar:", error);
    res.status(500).json({ message: error.message });
  }
};