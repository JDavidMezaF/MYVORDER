const express = require('express');
const router = express.Router();
const controller = require('../controllers/tickets.controllers');
const reportes = require('../controllers/reportes.controllers');

router.get('/:email', controller.obtenerTicketsPorRestaurante);
router.get('/:email/reporte', reportes.reporteJSON);
router.get('/:email/reporte/excel', reportes.reporteExcel);
router.put('/:id/estado', controller.actualizarEstadoTicket);

module.exports = router;
