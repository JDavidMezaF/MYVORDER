const express = require('express');
const router = express.Router();
const controller = require('../controllers/tickets.controllers');

router.get('/:email', controller.obtenerTicketsPorRestaurante);
router.put('/:id/estado', controller.actualizarEstadoTicket);

module.exports = router;
