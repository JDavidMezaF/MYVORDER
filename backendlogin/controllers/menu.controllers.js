const db = require('../config/db');

// Obtener platillos de un restaurante
exports.obtenerMenu = async (req, res) => {
  try {
    const { idRestaurante } = req.params;

    const [rows] = await db.query(
      `SELECT 
        MenuID as idMenu,
        RestauranteID as idRestaurante,
        Nombre as nombre,
        Descripcion as descripcion,
        Precio as precio,
        Categoria as categoria,
        Disponibilidad as disponibilidad
      FROM menu
      WHERE RestauranteID = ?`,
      [idRestaurante]
    );

    res.json(rows);
  } catch (error) {
    console.error("ERROR al obtener menú:", error);
    res.status(500).json({ message: error.message });
  }
};

// Crear platillo
exports.crearPlatillo = async (req, res) => {
  try {
    const { idRestaurante, nombre, descripcion, precio, categoria, disponibilidad } = req.body;

    if (!idRestaurante || !nombre || !precio) {
      return res.status(400).json({ message: "idRestaurante, nombre y precio son obligatorios" });
    }

    const [result] = await db.query(
      `INSERT INTO menu (RestauranteID, Nombre, Descripcion, Precio, Categoria, Disponibilidad)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        idRestaurante,
        nombre,
        descripcion || null,
        precio,
        categoria || null,
        disponibilidad !== undefined ? disponibilidad : 1
      ]
    );

    res.status(201).json({
      message: "Platillo creado correctamente",
      idMenu: result.insertId
    });

  } catch (error) {
    console.error("ERROR al crear platillo:", error);
    res.status(500).json({ message: error.message });
  }
};

// Eliminar platillo
exports.eliminarPlatillo = async (req, res) => {
  try {
    const { idMenu } = req.params;

    const [result] = await db.query(
      "DELETE FROM menu WHERE MenuID = ?",
      [idMenu]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Platillo no encontrado" });
    }

    res.json({ message: "Platillo eliminado correctamente" });

  } catch (error) {
    console.error("ERROR al eliminar platillo:", error);
    res.status(500).json({ message: error.message });
  }
};