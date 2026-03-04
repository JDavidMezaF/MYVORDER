import 'package:flutter/material.dart';
import 'escaner_screen.dart';
import '../services/restaurante_service.dart';

class RestaurantesScreen extends StatefulWidget {
  const RestaurantesScreen({super.key});

  @override
  State<RestaurantesScreen> createState() => _RestaurantesScreenState();
}

class _RestaurantesScreenState extends State<RestaurantesScreen> {

  final RestauranteService service = RestauranteService();
  late Future<List<dynamic>> restaurantes;

  @override
  void initState() {
    super.initState();
    restaurantes = service.obtenerRestaurantes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige un Restaurante'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              '¿Dónde comerás hoy?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: restaurantes,
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Error al cargar restaurantes"));
                  }

                  final data = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final rest = data[index];

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EscanerScreen(
                                  nombreUsuario: "Invitado",
                                  nombreRestaurante: rest['nombre'],
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 120,
                                height: 100,
                                child: Icon(Icons.restaurant, size: 50, color: Colors.grey),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rest['nombre'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text("Restaurante registrado"),
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