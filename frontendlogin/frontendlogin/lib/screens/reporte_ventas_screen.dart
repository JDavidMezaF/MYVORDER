import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class ReporteVentasScreen extends StatefulWidget {
  final String email; // correo del restaurante (así lo identifica el backend)
  final String nombreRestaurante;

  const ReporteVentasScreen({
    super.key,
    required this.email,
    required this.nombreRestaurante,
  });

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  // 'hoy' | 'semana' | 'mes' | 'todo' | 'rango'
  String _periodo = 'mes';
  DateTime? _desde;
  DateTime? _hasta;

  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _datos;

  @override
  void initState() {
    super.initState();
    _aplicarPeriodo('mes');
  }

  // ── FECHAS ──

  // El backend interpreta las fechas como días de Monterrey (UTC-6),
  // así que "hoy" se calcula con esa misma referencia, sin depender del celular.
  DateTime _hoyMonterrey() {
    final ahora = DateTime.now().toUtc().subtract(const Duration(hours: 6));
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  String _dos(int n) => n.toString().padLeft(2, '0');

  // 2026-10-29 (formato que entiende el backend)
  String _fmtApi(DateTime d) => '${d.year}-${_dos(d.month)}-${_dos(d.day)}';

  // 29/10/2026 (para mostrar)
  String _fmtMostrar(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

  // "2026-10-29 20:30:00" -> "29/10/2026 20:30"
  String _fechaCorta(String f) {
    if (f.length < 16) return f;
    return '${f.substring(8, 10)}/${f.substring(5, 7)}/${f.substring(0, 4)} ${f.substring(11, 16)}';
  }

  String _textoPeriodo() {
    if (_desde == null && _hasta == null) return 'Todo el historial';
    if (_desde != null && _hasta != null) {
      if (_fmtApi(_desde!) == _fmtApi(_hasta!)) return _fmtMostrar(_desde!);
      return '${_fmtMostrar(_desde!)} al ${_fmtMostrar(_hasta!)}';
    }
    return _desde != null
        ? 'Desde ${_fmtMostrar(_desde!)}'
        : 'Hasta ${_fmtMostrar(_hasta!)}';
  }

  // $12,345.50
  String _dinero(num valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '\$$entero.${partes[1]}';
  }

  // ── PERIODO Y CARGA ──

  Future<void> _aplicarPeriodo(String periodo) async {
    final hoy = _hoyMonterrey();

    if (periodo == 'rango') {
      final rango = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: hoy,
        initialDateRange: (_desde != null && _hasta != null)
            ? DateTimeRange(start: _desde!, end: _hasta!)
            : null,
        helpText: 'Selecciona el periodo',
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.deepOrange),
          ),
          child: child!,
        ),
      );
      if (rango == null) return; // canceló: se queda el periodo anterior
      _desde = rango.start;
      _hasta = rango.end;
    } else if (periodo == 'hoy') {
      _desde = hoy;
      _hasta = hoy;
    } else if (periodo == 'semana') {
      _desde = DateTime(hoy.year, hoy.month, hoy.day - 6);
      _hasta = hoy;
    } else if (periodo == 'mes') {
      _desde = DateTime(hoy.year, hoy.month, 1);
      _hasta = hoy;
    } else {
      _desde = null;
      _hasta = null;
    }

    if (!mounted) return;
    setState(() => _periodo = periodo);
    await _cargar();
  }

  // ?desde=2026-10-01&hasta=2026-10-29 (solo lo que tenga valor)
  String _query() {
    final partes = <String>[];
    if (_desde != null) partes.add('desde=${_fmtApi(_desde!)}');
    if (_hasta != null) partes.add('hasta=${_fmtApi(_hasta!)}');
    return partes.isEmpty ? '' : '?${partes.join('&')}';
  }

  String get _urlBase =>
      '${ApiConfig.baseUrl}/api/tickets/${Uri.encodeComponent(widget.email)}/reporte';

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('$_urlBase${_query()}'));
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _datos = jsonDecode(response.body));
      } else {
        String mensaje = 'No se pudo cargar el reporte';
        try {
          mensaje = jsonDecode(response.body)['message'] ?? mensaje;
        } catch (_) {}
        setState(() => _error = mensaje);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _descargarExcel() async {
    final url = Uri.parse('$_urlBase/excel${_query()}');
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la descarga'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Reporte de ventas'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
          ),
        ],
      ),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_datos == null && _cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
    }

    if (_datos == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _error ?? 'No se pudo cargar el reporte',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final resumen = _datos!['resumen'] as Map<String, dynamic>;
    final tickets = (_datos!['tickets'] as List?) ?? [];
    final porDia = (resumen['porDia'] as List?) ?? [];

    // Todo lo que va antes de la lista de tickets
    final encabezado = <Widget>[
      if (_cargando)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: LinearProgressIndicator(color: Colors.deepOrange),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      Text(
        widget.nombreRestaurante,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      _filtros(),
      const SizedBox(height: 10),
      Text(
        'Periodo: ${_textoPeriodo()}',
        style: const TextStyle(color: Colors.black54, fontSize: 13),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          _tarjetaResumen(
            Icons.receipt_long,
            'Tickets pagados',
            '${resumen['cantidadTickets']}',
          ),
          const SizedBox(width: 8),
          _tarjetaResumen(
            Icons.attach_money,
            'Total vendido',
            _dinero(resumen['totalVendido'] as num),
          ),
          const SizedBox(width: 8),
          _tarjetaResumen(
            Icons.trending_up,
            'Ticket promedio',
            _dinero(resumen['ticketPromedio'] as num),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: tickets.isEmpty ? null : _descargarExcel,
          icon: const Icon(Icons.download, color: Colors.white),
          label: const Text(
            'Descargar Excel',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (porDia.isNotEmpty) _seccionPorDia(porDia),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          'Tickets pagados (${tickets.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      if (tickets.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Text(
              'No hay tickets pagados en este periodo',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
        ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: encabezado.length + tickets.length,
      itemBuilder: (context, i) {
        if (i < encabezado.length) return encabezado[i];
        return _tarjetaTicket(tickets[i - encabezado.length] as Map<String, dynamic>);
      },
    );
  }

  Widget _filtros() {
    Widget chip(String valor, String texto) {
      return ChoiceChip(
        label: Text(texto),
        selected: _periodo == valor,
        selectedColor: Colors.deepOrange.withValues(alpha: 0.2),
        onSelected: (_) => _aplicarPeriodo(valor),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        chip('hoy', 'Hoy'),
        chip('semana', '7 días'),
        chip('mes', 'Este mes'),
        chip('rango', 'Elegir fechas'),
        chip('todo', 'Todo'),
      ],
    );
  }

  Widget _tarjetaResumen(IconData icono, String titulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icono, color: Colors.deepOrange, size: 22),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valor,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionPorDia(List porDia) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas por día',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Del día más reciente al más antiguo
          ...porDia.reversed.map((d) {
            final String fecha = d['fecha'].toString();
            final int cantidad = d['tickets'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${fecha.substring(8, 10)}/${fecha.substring(5, 7)}/${fecha.substring(0, 4)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '$cantidad ${cantidad == 1 ? 'ticket' : 'tickets'}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _dinero(d['total'] as num),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tarjetaTicket(Map<String, dynamic> t) {
    final detalles = (t['detalles'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Ticket #${t['TicketID']} · Mesa ${t['NumeroMesa']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _dinero(t['Total'] as num),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${_fechaCorta(t['Fecha'].toString())} · ${t['Cliente']}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          children: [
            ...detalles.map((d) {
              final int entre = (d['entre'] ?? 1) as int;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${d['platillo']} x${d['cantidad']}${entre > 1 ? ' (entre $entre)' : ''}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      _dinero(d['monto'] as num),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}