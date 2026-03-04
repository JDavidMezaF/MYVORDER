const db = require('../config/db'); // ajusta si tu conexión se llama diferente

// Crear restaurante
exports.crearRestaurante = async (req, res) => {
  try {
    const { nombre, logo } = req.body;

    if (!nombre) {
      return res.status(400).json({ message: "El nombre es obligatorio" });
    }

    const [result] = await db.query(
      "INSERT INTO Restaurante (nombre, logo) VALUES (?, ?)",
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

exports.obtenerRestaurantes = async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM restaurante");
    res.json(rows);
  } catch (error) {
    console.error("ERROR REAL:", error);  // 👈 agrega esto
    res.status(500).json({ message: error.message });
  }
};