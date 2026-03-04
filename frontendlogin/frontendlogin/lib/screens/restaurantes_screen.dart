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
      body: Stack(
        children: [

          // 🔹 FONDO
          SizedBox.expand(
            child: Image.asset(
              'assets/images/fondorest.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 240),

                  // 🔥 TÍTULO ELEGANTE
                  const Text(
                    '¿Dónde comerás hoy?',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Elige entre las siguientes opciones',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // 🔹 LISTA
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: restaurantes,
                      builder: (context, snapshot) {

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepOrange,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error al cargar restaurantes"),
                          );
                        }

                        final data = snapshot.data ?? [];

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 30),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final rest = data[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 22),
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.97),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // 🔹 NOMBRE
                                    Text(
                                      rest['nombre'],
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // 🔹 FILA ESTRELLAS Y PRECIO
                                    Row(
                                      children: const [

                                        Icon(Icons.star, size: 16, color: Colors.amber),
                                        Icon(Icons.star, size: 16, color: Colors.amber),
                                        Icon(Icons.star, size: 16, color: Colors.amber),
                                        Icon(Icons.star_half, size: 16, color: Colors.amber),
                                        Icon(Icons.star_border, size: 16, color: Colors.amber),

                                        SizedBox(width: 10),

                                        Text(
                                          "4.3",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),

                                        Spacer(),

                                        Text(
                                          "\$\$",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    const Text(
                                      "Restaurante",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black54,
                                      ),
                                    ),
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
          ),
        ],
      ),
    );
  }
}