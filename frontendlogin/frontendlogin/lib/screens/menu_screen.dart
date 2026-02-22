import 'package:flutter/material.dart';
import 'carrito_screen.dart';

class MenuScreen extends StatefulWidget {
  final String restaurante;
  final String mesa;

  const MenuScreen({
    super.key,
    required this.restaurante,
    required this.mesa,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<Map<String, dynamic>> _miCarrito = [];

  List<Map<String, dynamic>> _obtenerPlatillos() {
    if (widget.restaurante == 'La Casa del Taco') {
      return [
        {'nombre': 'Tacos al Pastor', 'descripcion': 'Orden de 5 tacos con piña, cilantro y cebolla.', 'precio': 85.0, 'imagen': 'https://images.unsplash.com/photo-1551504734-5ee904db610c?q=80&w=300'},
        {'nombre': 'Gringa de Asada', 'descripcion': 'Tortilla de harina de 30cm con queso y carne.', 'precio': 95.0, 'imagen': 'https://images.unsplash.com/photo-1615870216519-2f9fa575fa5c?q=80&w=300'},
        {'nombre': 'Agua de Horchata', 'descripcion': 'Agua fresca tradicional de 1 litro.', 'precio': 35.0, 'imagen': 'https://images.unsplash.com/photo-1543253687-c92848b4e9fb?q=80&w=300'},
      ];
    } else if (widget.restaurante == 'Luigi\'s Pizza') {
      return [
        {'nombre': 'Pizza Pepperoni', 'descripcion': 'Pizza grande con extra queso y peperroni crujiente.', 'precio': 180.0, 'imagen': 'https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=300'},
        {'nombre': 'Spaghetti Boloñesa', 'descripcion': 'Pasta tradicional con carne y salsa de tomate.', 'precio': 130.0, 'imagen': 'https://images.unsplash.com/photo-1621996316565-e3dbc646d9a9?q=80&w=300'},
      ];
    } else if (widget.restaurante == 'Sushi Master') {
      return [
        {'nombre': 'California Roll', 'descripcion': 'Cangrejo, aguacate, pepino y queso crema.', 'precio': 110.0, 'imagen': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=300'},
        {'nombre': 'Ramen de Cerdo', 'descripcion': 'Fideos con caldo tradicional japonés y huevo.', 'precio': 160.0, 'imagen': 'https://images.unsplash.com/photo-1552611052-33e04de081de?q=80&w=300'},
        {'nombre': 'Teriyaki de Pollo', 'descripcion': 'Pollo glaseado servido con arroz al vapor.', 'precio': 135.0, 'imagen': 'https://images.unsplash.com/photo-1598514982205-f36b96d1e8d4?q=80&w=300'},
      ];
    }
    return [
      {'nombre': 'Platillo Genérico', 'descripcion': 'Descripción pendiente.', 'precio': 100.0, 'imagen': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=300'},
    ];
  }

  void _agregarAlCarrito(Map<String, dynamic> platillo) {
    setState(() {
      int index = _miCarrito.indexWhere((item) => item['nombre'] == platillo['nombre']);
      if (index != -1) {
        _miCarrito[index]['cantidad']++;
      } else {
        _miCarrito.add({
          'nombre': platillo['nombre'],
          'precio': platillo['precio'],
          'cantidad': 1,
        });
      }
    });
  }

  // ➖ NUEVA FUNCIÓN: Remover del carrito
  void _removerDelCarrito(Map<String, dynamic> platillo) {
    setState(() {
      int index = _miCarrito.indexWhere((item) => item['nombre'] == platillo['nombre']);
      if (index != -1) {
        if (_miCarrito[index]['cantidad'] > 1) {
          _miCarrito[index]['cantidad']--;
        } else {
          _miCarrito.removeAt(index); // Si llega a 0, lo borra de la lista
        }
      }
    });
  }

  // Ayudante para saber cuántos hay de un platillo específico
  int _obtenerCantidad(String nombre) {
    int index = _miCarrito.indexWhere((item) => item['nombre'] == nombre);
    return index != -1 ? _miCarrito[index]['cantidad'] : 0;
  }

  @override
  Widget build(BuildContext context) {
    final platillos = _obtenerPlatillos();

    int totalArticulos = 0;
    for (var item in _miCarrito) {
      totalArticulos += item['cantidad'] as int;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.restaurante),
            Text('Mesa: ${widget.mesa}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: platillos.length,
        itemBuilder: (context, index) {
          final platillo = platillos[index];
          final int cantidadActual = _obtenerCantidad(platillo['nombre']);

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  child: Image.network(
                    platillo['imagen'],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(width: 100, height: 100, child: Icon(Icons.fastfood, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platillo['nombre'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '\$${platillo['precio'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // ✨ MAGIA VISUAL: Si es 0 muestra "+", si es > 0 muestra "- [1] +"
                cantidadActual == 0
                    ? IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepOrange, size: 35),
                  onPressed: () => _agregarAlCarrito(platillo),
                )
                    : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.deepOrange),
                      onPressed: () => _removerDelCarrito(platillo),
                    ),
                    Text(
                      '$cantidadActual',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                      onPressed: () => _agregarAlCarrito(platillo),
                    ),
                  ],
                ),
                const SizedBox(width: 5),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // El 'await' hace que el menú se pause hasta que cierres el carrito
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarritoScreen(
                restaurante: widget.restaurante,
                mesa: widget.mesa,
                platillosCarrito: _miCarrito,
              ),
            ),
          );
          // Cuando regresas del carrito, actualizamos el menú para reflejar los cambios
          setState(() {});
        },
        backgroundColor: Colors.deepOrange,
        icon: Badge(
          label: Text('$totalArticulos'),
          isLabelVisible: totalArticulos > 0,
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
        label: const Text('Ver Pedido', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}