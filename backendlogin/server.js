const express = require('express');
const cors = require('cors');
require('dotenv').config();
console.log("VERSION NUEVA RESTAURANTES");

const app = express();

app.use(cors());
app.use(express.json());

// Rutas
app.use('/api/usuarios', require('./routes/usuarios.routes'));
app.use('/api/restaurantes', require('./routes/restaurantes.routes'));
app.use('/api/menu', require('./routes/menu.routes'));
//app.use('/api/mesas', require('./routes/mesas.routes'));
//app.use('/api/pedidos', require('./routes/pedidos.routes'));

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor corriendo en puerto ${PORT}`);
});