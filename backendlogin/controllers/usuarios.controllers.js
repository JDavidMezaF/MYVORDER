const db = require('../config/db');

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

    const hashedPassword = await bcrypt.hash(Password, 10);

    const sql = `
      INSERT INTO usuario (Nombre, EMail, Password, Rol)
      VALUES (?, ?, ?, ?)
    `;

    await db.query(sql, [Nombre, EMail, hashedPassword, Rol]);

    res.json({ message: 'Usuario creado correctamente' });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// LOGIN
exports.login = async (req, res) => {
  try {
    const { EMail, Password } = req.body;

    const [rows] = await db.query(
      "SELECT * FROM usuario WHERE EMail = ? AND Password = ?",
      [EMail, Password]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    res.json({
      message: 'Inicio de sesión exitoso',
      usuario: rows[0]
    });

  } catch (error) {
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

