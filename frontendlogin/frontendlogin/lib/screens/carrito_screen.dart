import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CarritoScreen extends StatefulWidget {
  final String restaurante;
  final String mesa;        // nombre visible ej. "MESA-01" o "1"
  final int mesaID;         // ID real de la BD (MesaID)
  final List<Map<String, dynamic>> platillosCarrito;
  // Cada platillo debe tener: { 'idMenu', 'nombre', 'precio', 'cantidad' }

  const CarritoScreen({
    super.key,
    required this.restaurante,
    required this.mesa,
    required this.mesaID,
    required this.platillosCarrito,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  bool _enviando = false;

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

  Future<void> _confirmarPedido() async {
    if (widget.platillosCarrito.isEmpty) return;
    setState(() => _enviando = true);

    try {
      // Armar lista de platillos con MenuID
      final List<Map<String, dynamic>> platillos = widget.platillosCarrito
          .map((item) => {
                'MenuID': item['idMenu'],
                'Nombre': item['nombre'],
                'Cantidad': item['cantidad'],
                'PrecioUnitario': item['precio'],
              })
          .toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/pedidos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'MesaID': widget.mesaID,
          'platillos': platillos,
        }),
      );

      if (response.statusCode == 201) {
        widget.platillosCarrito.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Pedido enviado a la cocina! 👨‍🍳'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        final error = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error['message'] ?? 'No se pudo enviar el pedido'}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (var item in widget.platillosCarrito) {
      total += (item['precio'] * item['cantidad']);
    }

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
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

                const SizedBox(height: 16),

                // LISTA DE PLATILLOS
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.platillosCarrito.length,
                    itemBuilder: (context, index) {
                      final item = widget.platillosCarrito[index];
                      final double subtotal =
                          item['precio'] * item['cantidad'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // ÍCONO
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withOpacity(0.1),
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
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black45),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
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
                      );
                    },
                  ),
                ),

                // RESUMEN Y BOTÓN CONFIRMAR
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
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
                            'Total a pagar:',
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

  Widget _botonControl(
      {required IconData icono, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.deepOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, size: 16, color: Colors.deepOrange),
      ),
    );
  }
}