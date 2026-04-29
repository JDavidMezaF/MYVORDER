const express = require('express');
const router = express.Router();
const controller = require('../controllers/pedidos.controllers');

router.post('/', controller.crearPedido);
router.get('/:mesaID', controller.obtenerPedidosPorMesa);

module.exports = router;
