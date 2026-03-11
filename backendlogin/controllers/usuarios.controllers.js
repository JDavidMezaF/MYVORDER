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
    const { Nombre, EMail, Password, Rol } = req.body;

    if (!Nombre || !EMail || !Password) {
      return res.status(400).json({ error: "Faltan datos obligatorios" });
    }

    const hashedPassword = await bcrypt.hash(Password, 10);

    await db.query(
      "INSERT INTO usuario (Nombre, EMail, Password, Rol) VALUES (?, ?, ?, ?)",
      [Nombre, EMail, hashedPassword, Rol || "cliente"]
    );

    res.status(201).json({
      message: "Usuario creado correctamente"
    });

  } catch (error) {
    console.error(error);
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

