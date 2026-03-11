```dart
import 'package:flutter/material.dart';

class CarritoScreen extends StatefulWidget {
  final String restaurante;
  final String mesa;
  final List<Map<String, dynamic>> platillosCarrito;

  const CarritoScreen({
    super.key,
    required this.restaurante,
    required this.mesa,
    required this.platillosCarrito,
  });

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {

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

                /// ENCABEZADO RESTAURANTE
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

                /// LISTA DE PLATILLOS
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.platillosCarrito.length,
                    itemBuilder: (context, index) {

                      final item = widget.platillosCarrito[index];
                      final double subtotal =
                          item['precio'] * item['cantidad'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [

                            /// IMAGEN DEL PLATILLO
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                item['imagen'] ??
                                    'assets/images/comida_default.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// NOMBRE Y PRECIO
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                        fontSize: 12,
                                        color: Colors.black45),
                                  ),
                                ],
                              ),
                            ),

                            /// CONTROLES
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
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
                                      padding:
                                          const EdgeInsets.symmetric(
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

                /// RESUMEN
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
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [

                          const Text(
                            'Total a pagar:',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
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
                          icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white),

                          label: const Text(
                            'Confirmar Pedido',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),

                          onPressed: () {

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '¡Pedido enviado a la cocina! 👨‍🍳'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            Navigator.popUntil(
                                context, (route) => route.isFirst);
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

  /// BOTÓN + -
  Widget _botonControl({
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,

        decoration: BoxDecoration(
          color: Colors.deepOrange,
          borderRadius: BorderRadius.circular(10),
        ),

        child: Icon(
          icono,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

