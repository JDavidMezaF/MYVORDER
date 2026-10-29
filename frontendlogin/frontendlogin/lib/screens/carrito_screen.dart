import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CarritoScreen extends StatefulWidget {
  final String restaurante;
  final String mesa;        // nombre visible ej. "Mesa 1"
  final int mesaID;         // ID real de la BD (MesaID)
  final List<Map<String, dynamic>> platillosCarrito;
  // Cada platillo debe tener: { 'idMenu', 'nombre', 'precio', 'cantidad' }
  final int capacidad;                  // capacidad de la mesa
  final Map<String, dynamic> usuario;   // usuario que inició sesión

  const CarritoScreen({
    super.key,
    required this.restaurante,
    required this.mesa,
    required this.mesaID,
    required this.platillosCarrito,
    required this.capacidad,
    required this.usuario,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _enviando = false;
  bool _buscando = false;

  final TextEditingController _correoController = TextEditingController();

  // Personas en la mesa: { 'UsuarioID', 'Nombre', 'EMail' }
  final List<Map<String, dynamic>> _integrantes = [];

  int get _miID => widget.usuario['UsuarioID'] as int;

  @override
  void initState() {
    super.initState();
    // Quien hace el pedido siempre es el primer integrante
    _integrantes.add({
      'UsuarioID': _miID,
      'Nombre': (widget.usuario['Nombre'] ?? 'Tú').toString(),
      'EMail': (widget.usuario['EMail'] ?? '').toString(),
    });
    // Por defecto cada platillo se divide entre todos
    for (final item in widget.platillosCarrito) {
      item.remove('asignados');
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  void _mensaje(String texto, {Color color = Colors.redAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  // ── CANTIDADES ──

  void _sumarItem(int index) {
    setState(() {
      widget.platillosCarrito[index]['cantidad']++;
    });
  }

  void _restarItem(int index) {
    setState(() {
      if (widget.platillosCarrito[index]['cantidad'] > 1) {
        widget.platillosCarrito[index]['cantidad']--;
      } else {
        widget.platillosCarrito.removeAt(index);
      }
    });
  }

  // ── INTEGRANTES DE LA MESA ──

  Future<void> _agregarIntegrante() async {
    final correo = _correoController.text.trim();
    if (correo.isEmpty) return;

    if (_integrantes.length >= widget.capacidad) {
      _mensaje('La mesa solo admite ${widget.capacidad} personas');
      return;
    }

    final yaEsta = _integrantes.any(
      (i) => i['EMail'].toString().toLowerCase() == correo.toLowerCase(),
    );
    if (yaEsta) {
      _mensaje('Esa persona ya está en la mesa');
      return;
    }

    setState(() => _buscando = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/usuarios/buscar?email=${Uri.encodeQueryComponent(correo)}',
        ),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final u = jsonDecode(response.body);
        if (_integrantes.any((i) => i['UsuarioID'] == u['UsuarioID'])) {
          _mensaje('Esa persona ya está en la mesa');
        } else {
          setState(() {
            _integrantes.add({
              'UsuarioID': u['UsuarioID'],
              'Nombre': u['Nombre'],
              'EMail': u['EMail'],
            });
            _correoController.clear();
          });
        }
      } else if (response.statusCode == 404) {
        _mensaje('No hay ningún usuario registrado con ese correo');
      } else {
        _mensaje('No se pudo buscar al usuario. Intenta de nuevo.');
      }
    } catch (e) {
      _mensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _quitarIntegrante(int usuarioID) {
    if (usuarioID == _miID) return;
    setState(() {
      _integrantes.removeWhere((i) => i['UsuarioID'] == usuarioID);
      for (final item in widget.platillosCarrito) {
        (item['asignados'] as Set<int>?)?.remove(usuarioID);
      }
    });
  }

  // ── ASIGNACIÓN DE PLATILLOS ──

  // IDs de quienes pagan este platillo, en el mismo orden que los integrantes
  List<int> _idsAsignados(Map<String, dynamic> item) {
    final guardados = item['asignados'] as Set<int>?;
    return _integrantes
        .map((i) => i['UsuarioID'] as int)
        .where((id) => guardados == null || guardados.contains(id))
        .toList();
  }

  void _toggleAsignado(Map<String, dynamic> item, int usuarioID) {
    final actuales = _idsAsignados(item).toSet();
    if (!actuales.remove(usuarioID)) actuales.add(usuarioID);
    setState(() => item['asignados'] = actuales);
  }

  // Cuánto paga cada persona, en centavos. Misma regla que el servidor:
  // cada platillo se divide en partes iguales y los centavos que sobran
  // van de 1 en 1 a las primeras personas.
  Map<int, int> _centavosPorPersona() {
    final totales = <int, int>{
      for (final i in _integrantes) (i['UsuarioID'] as int): 0,
    };
    for (final item in widget.platillosCarrito) {
      final asignados = _idsAsignados(item);
      if (asignados.isEmpty) continue;

      final total =
          ((item['precio'] as double) * 100).round() * (item['cantidad'] as int);
      final base = total ~/ asignados.length;
      final sobrante = total - base * asignados.length;

      for (int k = 0; k < asignados.length; k++) {
        totales[asignados[k]] =
            totales[asignados[k]]! + base + (k < sobrante ? 1 : 0);
      }
    }
    return totales;
  }

  String _dinero(int centavos) => '\$${(centavos / 100).toStringAsFixed(2)}';

  // ── ENVIAR PEDIDO ──

  String? _validar() {
    for (final item in widget.platillosCarrito) {
      if (_idsAsignados(item).isEmpty) {
        return 'Asigna al menos una persona a "${item['nombre']}"';
      }
    }
    return null;
  }

  Future<void> _confirmarPedido() async {
    if (widget.platillosCarrito.isEmpty) return;

    final errorValidacion = _validar();
    if (errorValidacion != null) {
      _mensaje(errorValidacion);
      return;
    }

    setState(() => _enviando = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/pedidos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'MesaID': widget.mesaID,
          'integrantes': _integrantes.map((i) => i['UsuarioID']).toList(),
          'platillos': widget.platillosCarrito
              .map((item) => {
                    'MenuID': item['idMenu'],
                    'Cantidad': item['cantidad'],
                    'asignados': _idsAsignados(item),
                  })
              .toList(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List tickets = data['Tickets'] ?? [];
        widget.platillosCarrito.clear();

        if (!mounted) return;
        await _mostrarTickets(tickets);
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        final error = jsonDecode(response.body);
        _mensaje('Error: ${error['message'] ?? 'No se pudo enviar el pedido'}');
      }
    } catch (e) {
      _mensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _mostrarTickets(List tickets) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¡Pedido enviado a la cocina!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket de cada persona:',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            ...tickets.map((t) {
              final integrante = _integrantes.firstWhere(
                (i) => i['UsuarioID'] == t['UsuarioID'],
                orElse: () => <String, dynamic>{'Nombre': 'Integrante'},
              );
              final total = double.tryParse(t['Total'].toString()) ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(integrante['Nombre'].toString())),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (var item in widget.platillosCarrito) {
      total += (item['precio'] * item['cantidad']);
    }

    final totales = _centavosPorPersona();
    final miParte = totales[_miID] ?? 0;
    final variasPersonas = _integrantes.length > 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Tu Pedido'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: widget.platillosCarrito.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu carrito está vacío',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [

                // ENCABEZADO RESTAURANTE Y MESA
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurante,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.table_restaurant,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text(
                            'Mesa: ${widget.mesa}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // INTEGRANTES + LISTA DE PLATILLOS (todo se desplaza junto)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _seccionIntegrantes(totales),
                      ...List.generate(
                        widget.platillosCarrito.length,
                        (index) => _itemCarrito(index, variasPersonas),
                      ),
                    ],
                  ),
                ),

                // RESUMEN Y BOTÓN CONFIRMAR
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total de la mesa:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (variasPersonas) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tu parte:',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.black54),
                            ),
                            Text(
                              _dinero(miParte),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: _enviando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline,
                                  color: Colors.white),
                          label: Text(
                            _enviando ? 'Enviando...' : 'Confirmar Pedido',
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _enviando ? null : _confirmarPedido,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Tarjeta "¿Quiénes están en la mesa?"
  Widget _seccionIntegrantes(Map<int, int> totales) {
    final lleno = _integrantes.length >= widget.capacidad;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.deepOrange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '¿Quiénes están en la mesa?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                '${_integrantes.length}/${widget.capacidad}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: lleno ? Colors.red : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ..._integrantes.map((i) {
            final int id = i['UsuarioID'] as int;
            final bool soyYo = id == _miID;
            final String nombre = i['Nombre'].toString();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.deepOrange.withValues(alpha: 0.12),
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          soyYo ? '$nombre (tú)' : nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          i['EMail'].toString(),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  if (_integrantes.length > 1)
                    Text(
                      _dinero(totales[id] ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  if (!soyYo)
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 20, color: Colors.redAccent),
                      tooltip: 'Quitar de la mesa',
                      onPressed: () => _quitarIntegrante(id),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          if (!lleno)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _agregarIntegrante(),
                    decoration: InputDecoration(
                      hintText: 'Correo de la persona a agregar',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      prefixIcon: const Icon(Icons.email_outlined,
                          size: 20, color: Colors.deepOrange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _buscando ? null : _agregarIntegrante,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _buscando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Agregar'),
                  ),
                ),
              ],
            )
          else
            const Text(
              'La mesa está llena',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
        ],
      ),
    );
  }

  // Un platillo del carrito, con selector de quién lo paga
  Widget _itemCarrito(int index, bool variasPersonas) {
    final item = widget.platillosCarrito[index];
    final double subtotal = item['precio'] * item['cantidad'];
    final asignados = _idsAsignados(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              // ÍCONO
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fastfood,
                    color: Colors.deepOrange, size: 24),
              ),

              const SizedBox(width: 12),

              // NOMBRE Y PRECIO UNITARIO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${item['precio'].toStringAsFixed(2)} c/u',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),

              // CONTROLES + SUBTOTAL
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _botonControl(
                        icono: Icons.remove,
                        onTap: () => _restarItem(index),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${item['cantidad']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _botonControl(
                        icono: Icons.add,
                        onTap: () => _sumarItem(index),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ¿QUIÉN PAGA ESTE PLATILLO?
          if (variasPersonas) ...[
            const Divider(height: 20),
            Text(
              asignados.isEmpty
                  ? 'Elige al menos a una persona'
                  : 'Lo pagan (${asignados.length}):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: asignados.isEmpty ? Colors.red : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: _integrantes.map((i) {
                final int id = i['UsuarioID'] as int;
                final String nombre = i['Nombre'].toString().split(' ').first;
                return FilterChip(
                  label: Text(id == _miID ? 'Tú' : nombre),
                  selected: asignados.contains(id),
                  selectedColor: Colors.deepOrange.withValues(alpha: 0.2),
                  checkmarkColor: Colors.deepOrange,
                  onSelected: (_) => _toggleAsignado(item, id),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _botonControl(
      {required IconData icono, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.deepOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, size: 16, color: Colors.deepOrange),
      ),
    );
  }
}