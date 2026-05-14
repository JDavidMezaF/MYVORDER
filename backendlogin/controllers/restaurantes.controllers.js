const db = require('../config/db');
const bcrypt = require('bcrypt');
const crypto = require('crypto');

// ─── Utilidades ───────────────────────────────────────────────

// Genera el email base desde el nombre del restaurante
// Ej: "Tacos Pepe" → "tacospepe@test.com"
const generarEmailBase = (nombre) => {
  return nombre
    .toLowerCase()
    .replace(/\s+/g, '')        // quita espacios
    .replace(/[^a-z0-9]/g, '') // quita caracteres especiales
    + '@gmail.com';
};

// Manejo de duplicados: tacospepe@test.com → tacospepe2@test.com → tacospepe3@test.com
const generarEmailUnico = async (nombre) => {
  const emailBase = generarEmailBase(nombre);
  const usuario = emailBase.replace('@gmail.com', '');

  let email = emailBase;
  let contador = 2;

  while (true) {
    const [rows] = await db.query(
      'SELECT RestauranteID FROM restaurante WHERE email = ?',
      [email]
    );
    if (rows.length === 0) break; // email disponible ✅
    email = `${usuario}${contador}@gmail.com`;
    contador++;
  }

  return email;
};

// Genera contraseña aleatoria segura de 10 caracteres
const generarPassword = () => {
  return crypto.randomBytes(10).toString('base64').slice(0, 10);
};

// ─── Controladores ────────────────────────────────────────────

// Crear restaurante
exports.crearRestaurante = async (req, res) => {
  try {
    const { nombre, logo } = req.body;

    if (!nombre) {
      return res.status(400).json({ message: "El nombre es obligatorio" });
    }

    // 1. Generar credenciales
    const email = await generarEmailUnico(nombre);
    const passwordPlano = generarPassword();
    const passwordHash = await bcrypt.hash(passwordPlano, 10);

    // 2. Guardar en tabla restaurante
    const [result] = await db.query(
      "INSERT INTO restaurante (nombre, logo, email, password_hash) VALUES (?, ?, ?, ?)",
      [nombre, logo || null, email, passwordHash]
    );

    // 3. Crear usuario en tabla usuario con rol "restaurante"
    await db.query(
      "INSERT INTO usuario (Nombre, EMail, Password, Rol) VALUES (?, ?, ?, ?)",
      [nombre, email, passwordHash, "restaurante"]
    );

    // 4. Responder con credenciales UNA SOLA VEZ
    res.status(201).json({
      message: "Restaurante creado correctamente",
      idRestaurante: result.insertId,
      credenciales: {
        email: email,
        password: passwordPlano
      }
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
        logo,
        email
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

    res.json({ message: "Restaurante y todos sus datos asociados eliminados con éxito" });

  } catch (error) {
    console.error("ERROR al eliminar:", error);
    res.status(500).json({ message: error.message });
  }
};