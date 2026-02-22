import 'package:flutter/material.dart';

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

  // 🪄 Aquí está la magia: Dependiendo del restaurante, devolvemos un menú diferente
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

    // Por si agregas otro restaurante y olvidas ponerle menú
    return [
      {'nombre': 'Platillo Genérico', 'descripcion': 'Descripción pendiente.', 'precio': 100.0, 'imagen': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=300'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Mandamos a llamar los platillos correctos justo antes de dibujar la pantalla
    final platillos = _obtenerPlatillos();

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
                        platillo['descripcion'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '\$${platillo['precio'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepOrange, size: 30),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${platillo['nombre']} agregado al carrito'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 5),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Aquí conectaremos el Carrito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ir al carrito (Pendiente)')),
          );
        },
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: const Text('Ver Pedido', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}