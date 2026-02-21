const express = require('express');
const router = express.Router();
const controllers = require('../controllers/usuarios.controllers');

router.get('/', controllers.obtenerUsuarios);
router.post('/', controllers.crearUsuario);

//PARTE AÑADIDA PARA LOGIN
router.post('/login', controllers.login);
router.post('/id', controllers.eliminarUsuario);

module.exports = router;