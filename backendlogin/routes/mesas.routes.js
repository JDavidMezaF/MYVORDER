const express = require('express');
const router = express.Router();
const controller = require('../controllers/mesas.controllers');
 
router.get('/:idRestaurante', controller.getMesasByRestaurante);
router.post('/', controller.crearMesa);
router.delete('/:id', controller.eliminarMesa);
 
module.exports = router;
 