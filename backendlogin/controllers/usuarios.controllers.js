const db = require('../config/db');
const bcrypt = require('bcrypt');

// OBTENER USUARIOS
exports.obtenerUsuarios = async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM usuario");
    res.json(rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};

// CREAR USUARIO
exports.crearUsuario = async (req, res) => {
  try {
    const { Nombre, EMail, Password } = req.body;

    // Si no envían rol, asignamos uno por defecto
    const Rol = 'cliente';

    const hashedPassword = await bcrypt.hash(Password, 10);

    const sql = `
      INSERT INTO usuario (Nombre, EMail, Password, Rol)
      VALUES (?, ?, ?, ?)
    `;

    await db.query(sql, [Nombre, EMail, hashedPassword, Rol]);

    res.json({ message: 'Usuario creado correctamente' });

  } catch (error) {
    console.error(error); // ← importante para ver el error real
    res.status(500).json({ error: error.message });
  }
};

// LOGIN
exports.login = async (req, res) => {
  try {
    const { EMail, Password } = req.body;

    const [rows] = await db.query(
      "SELECT * FROM usuario WHERE EMail = ?",
      [EMail]
    );

    console.log("EMAIL ENVIADO:", EMail);
    console.log("PASSWORD ENVIADA:", Password);

    if (rows.length === 0) {
      console.log("NO SE ENCONTRÓ EL USUARIO");
      return res.status(401).json({ error: "Usuario no encontrado" });
    }

    const usuario = rows[0];

    console.log("HASH EN DB:", usuario.Password);

    const coincide = await bcrypt.compare(
      Password,
      usuario.Password
    );

    console.log("RESULTADO COMPARE:", coincide);

    if (!coincide) {
      return res.status(401).json({ error: "Contraseña incorrecta" });
    }

    res.json({
      message: "Login exitoso",
      usuario
    });

  } catch (error) {
    console.error("ERROR LOGIN:", error);
    res.status(500).json({ error: error.message });
  }
};

// ELIMINAR USUARIO
exports.eliminarUsuario = async (req, res) => {
  try {
    const { UsuarioID } = req.body;

    await db.query("DELETE FROM usuario WHERE UsuarioID = ?", [UsuarioID]);

    res.json({ message: "Usuario eliminado" });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

