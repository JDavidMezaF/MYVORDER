import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../widgets/soporte_boton.dart';
import 'login_screen.dart';

class RestauranteHomeScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const RestauranteHomeScreen({super.key, required this.usuario});

  @override
  State<RestauranteHomeScreen> createState() => _RestauranteHomeScreenState();
}

class _RestauranteHomeScreenState extends State<RestauranteHomeScreen> {
  List<dynamic> _tickets = [];
  bool _cargando = true;
  Set<int> _expandidos = {};

  @override
  void initState() {
    super.initState();
    _cargarTickets();
  }

  Future<void> _cargarTickets() async {
    setState(() => _cargando = true);
    try {
      final email = Uri.encodeComponent(widget.usuario['EMail'] ?? '');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/tickets/$email'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _tickets = data['tickets'] ?? []);
      }
    } catch (e) {
      print("Error al cargar tickets: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _actualizarEstado(int ticketID, String nuevoEstado) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/tickets/$ticketID/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );
      if (response.statusCode == 200) {
        _cargarTickets();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket marcado como $nuevoEstado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error al actualizar estado: $e");
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.access_time;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.usuario["Nombre"] ?? "Restaurante";

    return Scaffold(
      // ── BOTÓN SOPORTE FIJO EN LA PARTE INFERIOR ──
      bottomNavigationBar: const SoporteBoton(),
      body: Stack(
        children: [

          // FONDO
          SizedBox.expand(
            child: Image.asset(
              'assets/images/fondoadmin.png',
              fit: BoxFit.cover,
            ),
          ),

          Container(color: Colors.white.withOpacity(0.18)),

          SafeArea(
            child: Column(
              children: [

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.deepOrange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "MyVorder",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          // Botón refrescar
                          GestureDetector(
                            onTap: _cargarTickets,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.deepOrange,
                                size: 20,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Botón cerrar sesión
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: Colors.deepOrange,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // TÍTULO SECCIÓN
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        "Tickets y Pedidos",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          shadows: [
                            Shadow(color: Colors.white54, blurRadius: 4)
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!_cargando)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_tickets.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // LISTA DE TICKETS
                Expanded(
                  child: _cargando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepOrange,
                          ),
                        )
                      : _tickets.isEmpty
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(20),
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_long,
                                        size: 60, color: Colors.black26),
                                    SizedBox(height: 16),
                                    Text(
                                      "No hay tickets aún",
                                      style: TextStyle(
                                          color: Colors.black45,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                              itemCount: _tickets.length,
                              itemBuilder: (context, index) {
                                final ticket = _tickets[index];
                                final int ticketID = ticket['TicketID'];
                                final String estado =
                                    ticket['Estado']?.toString() ?? 'pendiente';
                                final double total = double.tryParse(
                                        ticket['Total'].toString()) ??
                                    0.0;
                                final String mesa =
                                    ticket['NumeroMesa']?.toString() ?? '-';
                                final String fecha =
                                    ticket['FechaHora']?.toString() ?? '';
                                final List detalles = ticket['detalles'] ?? [];
                                final bool expandido =
                                    _expandidos.contains(ticketID);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.07),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [

                                      // CABECERA DEL TICKET
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        onTap: () {
                                          setState(() {
                                            if (expandido) {
                                              _expandidos.remove(ticketID);
                                            } else {
                                              _expandidos.add(ticketID);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [

                                              // ÍCONO ESTADO
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: _colorEstado(estado)
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  _iconoEstado(estado),
                                                  color: _colorEstado(estado),
                                                  size: 24,
                                                ),
                                              ),

                                              const SizedBox(width: 14),

                                              // INFO
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "Ticket #$ticketID",
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 8,
                                                              vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _colorEstado(
                                                                    estado)
                                                                .withOpacity(
                                                                    0.15),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(8),
                                                          ),
                                                          child: Text(
                                                            estado.toUpperCase(),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              color: _colorEstado(
                                                                  estado),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Mesa $mesa  •  ${fecha.substring(0, fecha.length > 16 ? 16 : fecha.length)}",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black45,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // TOTAL
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "\$${total.toStringAsFixed(2)}",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.deepOrange,
                                                    ),
                                                  ),
                                                  Icon(
                                                    expandido
                                                        ? Icons.keyboard_arrow_up
                                                        : Icons
                                                            .keyboard_arrow_down,
                                                    color: Colors.black38,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // DETALLE EXPANDIBLE
                                      if (expandido) ...[
                                        const Divider(height: 1),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 12, 16, 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Detalle del pedido",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if (detalles.isEmpty)
                                                const Text(
                                                  "Sin detalle disponible",
                                                  style: TextStyle(
                                                      color: Colors.black38,
                                                      fontSize: 13),
                                                )
                                              else
                                                ...detalles.map((d) {
                                                  final String platillo =
                                                      d['nombrePlatillo'] ??
                                                          'Sin nombre';
                                                  final int cantidad =
                                                      d['Cantidad'] ?? 0;
                                                  final double subtotal =
                                                      double.tryParse(d[
                                                                  'Subtotal']
                                                              .toString()) ??
                                                          0.0;

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 6),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.fastfood,
                                                            size: 14,
                                                            color: Colors
                                                                .deepOrange),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            "$cantidad× $platillo",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        13),
                                                          ),
                                                        ),
                                                        Text(
                                                          "\$${subtotal.toStringAsFixed(2)}",
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),

                                              // BOTÓN MARCAR COMO PAGADO
                                              if (estado.toLowerCase() !=
                                                  'pagado') ...[
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    icon: const Icon(
                                                        Icons.check_circle,
                                                        size: 18),
                                                    label: const Text(
                                                        "Marcar como Pagado"),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              vertical: 10),
                                                    ),
                                                    onPressed: () =>
                                                        _actualizarEstado(
                                                            ticketID, 'Pagado'),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}