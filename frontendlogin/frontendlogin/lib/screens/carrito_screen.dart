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

  // Función para agregar +1 desde el carrito
  void _sumarItem(int index) {
    setState(() {
      widget.platillosCarrito[index]['cantidad']++;
    });
  }

  // Función para restar -1 desde el carrito
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
      appBar: AppBar(
        title: const Text('Tu Pedido'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: widget.platillosCarrito.isEmpty
          ? const Center(
        child: Text('Tu carrito está vacío 🛒', style: TextStyle(fontSize: 20, color: Colors.grey)),
      )
          : Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.restaurante, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Mesa: ${widget.mesa}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const Divider(height: 30, thickness: 2),

            Expanded(
              child: ListView.builder(
                itemCount: widget.platillosCarrito.length,
                itemBuilder: (context, index) {
                  final item = widget.platillosCarrito[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('\$${item['precio'].toStringAsFixed(2)} c/u'),

                    // ✨ MAGIA VISUAL: Controles de + y - en el carrito
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.deepOrange),
                          onPressed: () => _restarItem(index),
                        ),
                        Text(
                            '${item['cantidad']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                          onPressed: () => _sumarItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 30, thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, color: Colors.deepOrange, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('¡Pedido enviado a la cocina! 👨‍🍳'),
                        backgroundColor: Colors.green
                    ),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Confirmar Pedido', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}