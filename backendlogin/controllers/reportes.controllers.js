const ExcelJS = require('exceljs');
const db = require('../config/db');

// ── ZONA HORARIA ──────────────────────────────────────────────────────────
// Las fechas de la BD se guardan con NOW() del servidor MySQL (Railway usa UTC).
// El reporte se muestra y se filtra en hora de Monterrey (UTC-6, sin horario de verano).
// Si tu BD guardara hora local en vez de UTC, cambia OFFSET_BD a '-06:00'.
const OFFSET_BD = '+00:00';
const OFFSET_LOCAL = '-06:00';

// Fecha efectiva del ticket en hora local: cuándo se pagó (o, si no hay dato, cuándo se creó)
const FECHA_LOCAL = `CONVERT_TZ(COALESCE(t.FechaPago, t.FechaHora), '${OFFSET_BD}', '${OFFSET_LOCAL}')`;

class ErrorReporte extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

const esFechaValida = (texto) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(texto)) return false;
  const d = new Date(`${texto}T00:00:00Z`);
  return !isNaN(d) && d.toISOString().slice(0, 10) === texto;
};

// "2026-10-29 20:30:00" (hora local) -> Date cuyos números son esos mismos,
// para que Excel muestre exactamente esa hora sin convertirla.
const aFechaExcel = (texto) => new Date(texto.replace(' ', 'T') + 'Z');

const centavos = (valor) => Math.round(Number(valor) * 100);

// ── DATOS DEL REPORTE (los usan el JSON y el Excel) ───────────────────────
const obtenerDatosReporte = async (email, desde, hasta) => {
  if ((desde && !esFechaValida(desde)) || (hasta && !esFechaValida(hasta))) {
    throw new ErrorReporte('Las fechas deben ser válidas y tener el formato AAAA-MM-DD', 400);
  }
  if (desde && hasta && desde > hasta) {
    throw new ErrorReporte('La fecha inicial no puede ser posterior a la final', 400);
  }

  const [restRows] = await db.query(
    'SELECT RestauranteID, Nombre FROM restaurante WHERE email = ?',
    [email]
  );
  if (restRows.length === 0) throw new ErrorReporte('Restaurante no encontrado', 404);
  const restaurante = restRows[0];

  // Filtros: las fechas llegan como días locales; "hasta" incluye todo ese día
  const condiciones = ['m.RestauranteID = ?', "t.Estado = 'Pagado'"];
  const params = [restaurante.RestauranteID];
  if (desde) {
    condiciones.push(`${FECHA_LOCAL} >= ?`);
    params.push(`${desde} 00:00:00`);
  }
  if (hasta) {
    condiciones.push(`${FECHA_LOCAL} < DATE_ADD(?, INTERVAL 1 DAY)`);
    params.push(`${hasta} 00:00:00`);
  }

  const [filas] = await db.query(
    `SELECT t.TicketID, t.PedidoID, t.MesaID, t.UsuarioID, t.Total,
            m.NumeroMesa,
            u.Nombre AS Cliente,
            u.EMail AS EmailCliente,
            DATE_FORMAT(${FECHA_LOCAL}, '%Y-%m-%d %H:%i:%s') AS Fecha
     FROM ticket t
     INNER JOIN mesa m ON t.MesaID = m.MesaID
     LEFT JOIN usuario u ON t.UsuarioID = u.UsuarioID
     WHERE ${condiciones.join(' AND ')}
     ORDER BY ${FECHA_LOCAL} DESC, t.TicketID DESC`,
    params
  );

  // Detalle de platillos de todos los tickets, en solo 2 consultas
  const asignPorTicket = new Map();   // "PedidoID-UsuarioID" -> platillos de ESA persona
  const completoPorPedido = new Map(); // PedidoID -> pedido completo (tickets anteriores a la división de cuenta)

  const pedidoIDs = [...new Set(filas.map((f) => f.PedidoID))];
  if (pedidoIDs.length > 0) {
    const [asignaciones] = await db.query(
      `SELECT dp.PedidoID, da.UsuarioID,
              mn.Nombre AS platillo, mn.Categoria AS categoria,
              dp.Cantidad AS cantidad, da.Monto AS monto,
              (SELECT COUNT(*) FROM detalle_asignacion x WHERE x.DetalleID = da.DetalleID) AS entre
       FROM detalle_asignacion da
       INNER JOIN detallepedido dp ON da.DetalleID = dp.DetalleID
       INNER JOIN menu mn ON dp.MenuID = mn.MenuID
       WHERE dp.PedidoID IN (?)
       ORDER BY dp.DetalleID`,
      [pedidoIDs]
    );
    for (const a of asignaciones) {
      const llave = `${a.PedidoID}-${a.UsuarioID}`;
      if (!asignPorTicket.has(llave)) asignPorTicket.set(llave, []);
      asignPorTicket.get(llave).push({
        platillo: a.platillo,
        categoria: a.categoria,
        cantidad: Number(a.cantidad),
        entre: Number(a.entre),
        monto: Number(a.monto),
      });
    }

    const [completos] = await db.query(
      `SELECT dp.PedidoID, mn.Nombre AS platillo, mn.Categoria AS categoria,
              dp.Cantidad AS cantidad, dp.Subtotal AS monto
       FROM detallepedido dp
       INNER JOIN menu mn ON dp.MenuID = mn.MenuID
       WHERE dp.PedidoID IN (?)
       ORDER BY dp.DetalleID`,
      [pedidoIDs]
    );
    for (const c of completos) {
      if (!completoPorPedido.has(c.PedidoID)) completoPorPedido.set(c.PedidoID, []);
      completoPorPedido.get(c.PedidoID).push({
        platillo: c.platillo,
        categoria: c.categoria,
        cantidad: Number(c.cantidad),
        entre: 1,
        monto: Number(c.monto),
      });
    }
  }

  // Armar tickets y resumen (los montos se suman en centavos para no arrastrar decimales)
  let totalCent = 0;
  const porDia = new Map();

  const tickets = filas.map((f) => {
    const totalC = centavos(f.Total);
    totalCent += totalC;

    const fecha = String(f.Fecha || '');
    const dia = fecha.slice(0, 10);
    const acumulado = porDia.get(dia) || { fecha: dia, tickets: 0, totalC: 0 };
    acumulado.tickets += 1;
    acumulado.totalC += totalC;
    porDia.set(dia, acumulado);

    const detalles =
      asignPorTicket.get(`${f.PedidoID}-${f.UsuarioID}`) ||
      completoPorPedido.get(f.PedidoID) ||
      [];

    return {
      TicketID: f.TicketID,
      PedidoID: f.PedidoID,
      MesaID: f.MesaID,
      NumeroMesa: f.NumeroMesa,
      Cliente: f.Cliente || 'Sin registrar',
      EmailCliente: f.EmailCliente || '',
      Fecha: fecha,
      Total: totalC / 100,
      detalles,
    };
  });

  const cantidad = tickets.length;

  return {
    restaurante: { RestauranteID: restaurante.RestauranteID, Nombre: restaurante.Nombre },
    desde: desde || null,
    hasta: hasta || null,
    resumen: {
      cantidadTickets: cantidad,
      totalVendido: totalCent / 100,
      ticketPromedio: cantidad > 0 ? Math.round(totalCent / cantidad) / 100 : 0,
      porDia: [...porDia.values()]
        .sort((a, b) => a.fecha.localeCompare(b.fecha))
        .map((d) => ({ fecha: d.fecha, tickets: d.tickets, total: d.totalC / 100 })),
    },
    tickets,
  };
};

const responderError = (res, error) => {
  if (error.status) return res.status(error.status).json({ message: error.message });
  console.error('ERROR en reporte de ventas:', error);
  res.status(500).json({ message: error.message });
};

// GET /api/tickets/:email/reporte?desde=2026-10-01&hasta=2026-10-31
exports.reporteJSON = async (req, res) => {
  try {
    const datos = await obtenerDatosReporte(req.params.email, req.query.desde, req.query.hasta);
    res.json(datos);
  } catch (error) {
    responderError(res, error);
  }
};

// GET /api/tickets/:email/reporte/excel?desde=2026-10-01&hasta=2026-10-31
exports.reporteExcel = async (req, res) => {
  try {
    const { desde, hasta } = req.query;
    const datos = await obtenerDatosReporte(req.params.email, desde, hasta);

    const MONEDA = '"$"#,##0.00';
    const FECHA_HORA = 'yyyy-mm-dd hh:mm';
    const COLOR_ENCABEZADO = 'FFFF5722';

    const estiloEncabezado = (fila) => {
      fila.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      fila.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: COLOR_ENCABEZADO } };
      fila.alignment = { vertical: 'middle' };
    };

    const wb = new ExcelJS.Workbook();
    wb.creator = 'MyvOrder';
    wb.created = new Date();

    // ── Hoja 1: Resumen ──
    const hr = wb.addWorksheet('Resumen');
    hr.columns = [{ width: 24 }, { width: 22 }, { width: 18 }];

    hr.addRow(['Reporte de ventas']).font = { bold: true, size: 16 };
    hr.addRow(['Restaurante', datos.restaurante.Nombre]);
    hr.addRow([
      'Periodo',
      desde || hasta ? `${desde || 'inicio'} al ${hasta || 'hoy'}` : 'Todo el historial',
    ]);
    hr.addRow([]);

    hr.addRow(['Tickets pagados', datos.resumen.cantidadTickets]).getCell(1).font = { bold: true };
    const filaTotal = hr.addRow(['Total vendido', datos.resumen.totalVendido]);
    filaTotal.getCell(1).font = { bold: true };
    filaTotal.getCell(2).numFmt = MONEDA;
    const filaProm = hr.addRow(['Ticket promedio', datos.resumen.ticketPromedio]);
    filaProm.getCell(1).font = { bold: true };
    filaProm.getCell(2).numFmt = MONEDA;
    hr.addRow([]);

    hr.addRow(['Ventas por día']).font = { bold: true, size: 13 };
    estiloEncabezado(hr.addRow(['Fecha', 'Tickets', 'Total']));
    for (const d of datos.resumen.porDia) {
      const fila = hr.addRow([aFechaExcel(`${d.fecha} 00:00:00`), d.tickets, d.total]);
      fila.getCell(1).numFmt = 'yyyy-mm-dd';
      fila.getCell(1).alignment = { horizontal: 'left' };
      fila.getCell(3).numFmt = MONEDA;
    }

    // ── Hoja 2: Tickets (una fila por ticket) ──
    const ht = wb.addWorksheet('Tickets');
    ht.columns = [
      { header: 'Ticket #', key: 'ticket', width: 10 },
      { header: 'Pedido #', key: 'pedido', width: 10 },
      { header: 'Fecha y hora', key: 'fecha', width: 18 },
      { header: 'Mesa', key: 'mesa', width: 8 },
      { header: 'Cliente', key: 'cliente', width: 26 },
      { header: 'Correo', key: 'correo', width: 30 },
      { header: 'Platillos', key: 'platillos', width: 60 },
      { header: 'Total', key: 'total', width: 14 },
    ];
    estiloEncabezado(ht.getRow(1));

    for (const t of datos.tickets) {
      const texto = t.detalles
        .map((d) => `${d.platillo} x${d.cantidad}${d.entre > 1 ? ` (entre ${d.entre})` : ''}`)
        .join(', ');
      const fila = ht.addRow({
        ticket: t.TicketID,
        pedido: t.PedidoID,
        fecha: t.Fecha ? aFechaExcel(t.Fecha) : null,
        mesa: t.NumeroMesa,
        cliente: t.Cliente,
        correo: t.EmailCliente,
        platillos: texto,
        total: t.Total,
      });
      fila.getCell('fecha').numFmt = FECHA_HORA;
      fila.getCell('total').numFmt = MONEDA;
      fila.getCell('platillos').alignment = { wrapText: true, vertical: 'top' };
    }

    const n = datos.tickets.length;
    const filaSuma = ht.addRow({
      cliente: 'TOTAL',
      total: { formula: n > 0 ? `SUM(H2:H${n + 1})` : '0', result: datos.resumen.totalVendido },
    });
    filaSuma.font = { bold: true };
    filaSuma.getCell('total').numFmt = MONEDA;

    ht.views = [{ state: 'frozen', ySplit: 1 }];
    if (n > 0) ht.autoFilter = { from: 'A1', to: 'H1' };

    // ── Hoja 3: Detalle (una fila por platillo, ideal para tablas dinámicas) ──
    const hd = wb.addWorksheet('Detalle');
    hd.columns = [
      { header: 'Ticket #', key: 'ticket', width: 10 },
      { header: 'Fecha y hora', key: 'fecha', width: 18 },
      { header: 'Mesa', key: 'mesa', width: 8 },
      { header: 'Cliente', key: 'cliente', width: 26 },
      { header: 'Platillo', key: 'platillo', width: 30 },
      { header: 'Categoría', key: 'categoria', width: 16 },
      { header: 'Cantidad', key: 'cantidad', width: 10 },
      { header: 'Compartido entre', key: 'entre', width: 16 },
      { header: 'Monto', key: 'monto', width: 14 },
    ];
    estiloEncabezado(hd.getRow(1));

    for (const t of datos.tickets) {
      for (const d of t.detalles) {
        const fila = hd.addRow({
          ticket: t.TicketID,
          fecha: t.Fecha ? aFechaExcel(t.Fecha) : null,
          mesa: t.NumeroMesa,
          cliente: t.Cliente,
          platillo: d.platillo,
          categoria: d.categoria || '',
          cantidad: d.cantidad,
          entre: d.entre,
          monto: d.monto,
        });
        fila.getCell('fecha').numFmt = FECHA_HORA;
        fila.getCell('monto').numFmt = MONEDA;
      }
    }
    hd.views = [{ state: 'frozen', ySplit: 1 }];
    if (hd.rowCount > 1) hd.autoFilter = { from: 'A1', to: 'I1' };

    // ── Enviar archivo ──
    const nombreArchivo = `reporte-ventas_${desde || 'inicio'}_${hasta || 'hoy'}.xlsx`;
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader('Content-Disposition', `attachment; filename="${nombreArchivo}"`);
    await wb.xlsx.write(res);
    res.end();
  } catch (error) {
    if (res.headersSent) return res.end();
    responderError(res, error);
  }
};