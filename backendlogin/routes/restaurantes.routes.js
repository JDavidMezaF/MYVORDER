const express = require('express');
const router = express.Router();
const controller = require('../controllers/restaurantes.controllers');

router.get('/', controller.obtenerRestaurantes);
router.post('/', controller.crearRestaurante);

module.exports = router;