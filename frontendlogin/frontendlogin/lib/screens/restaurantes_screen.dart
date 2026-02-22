import 'package:flutter/material.dart';
import 'escaner_screen.dart'; // Conectamos con el escáner

class RestaurantesScreen extends StatelessWidget {
  const RestaurantesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para los 3 restaurantes
    final List<Map<String, String>> restaurantes = [
      {
        'nombre': 'La Casa del Taco',
        'tipo': 'Comida Mexicana',
        'imagen': 'https://images.unsplash.com/photo-1551504734-5ee904db610c?q=80&w=200',
      },
      {
        'nombre': 'Luigi\'s Pizza',
        'tipo': 'Comida Italiana',
        'imagen': 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=200',
      },
      {
        'nombre': 'Sushi Master',
        'tipo': 'Comida Japonesa',
        'imagen': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=200',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige un Restaurante'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Quita la flecha de regresar al login
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              '¿Dónde comerás hoy?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: restaurantes.length,
                itemBuilder: (context, index) {
                  final rest = restaurantes[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: InkWell(
                      onTap: () {
                        // ¡Aquí ocurre la magia de la navegación al escáner!
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EscanerScreen(
                              nombreUsuario: "Invitado",
                              nombreRestaurante: rest['nombre']!,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                            child: Image.network(
                              rest['imagen']!,
                              width: 120,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(
                                  width: 120, height: 100, child: Icon(Icons.restaurant, size: 50, color: Colors.grey)
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rest['nombre']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(rest['tipo']!, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios, color: Colors.deepOrange),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}