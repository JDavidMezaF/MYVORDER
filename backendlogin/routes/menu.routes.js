const express = require('express');
const router = express.Router();
const controller = require('../controllers/menu.controllers');

router.get('/:idRestaurante', controller.obtenerMenu);
router.post('/', controller.crearPlatillo);
router.delete('/:idMenu', controller.eliminarPlatillo);

module.exports = router;
