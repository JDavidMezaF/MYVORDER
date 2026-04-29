const express = require('express');
const router = express.Router();
const { getMesasByRestaurante, crearMesa, eliminarMesa } = require('../controllers/mesas.controllers');

router.get('/:idRestaurante', getMesasByRestaurante);
router.post('/', crearMesa);
router.delete('/:id', eliminarMesa);

module.exports = router;
