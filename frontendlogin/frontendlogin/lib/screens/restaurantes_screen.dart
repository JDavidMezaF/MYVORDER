import 'package:flutter/material.dart';
import 'escaner_screen.dart';
import '../services/restaurante_service.dart';

Map<String, String> imagenesRestaurantes = {
  "EL PEQUEÑO CESAR": "assets/images/cesars.png",
  "TACOS PEPE": "assets/images/pepe.png",
  "BURGER HOUSE": "assets/images/burger.png",
};


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

          // FONDO
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

                  // TÍTULO
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

                  // LISTA
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

                        if (data.isEmpty) {
                          return const Center(
                            child: Text(
                              "No hay restaurantes disponibles aún.",
                              style: TextStyle(color: Colors.black54),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 30),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final rest = data[index];
                            final String? logoUrl = rest['logo'];
                            final bool tieneLogo =
                                logoUrl != null && logoUrl.isNotEmpty;

                            return InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EscanerScreen(
                                      nombreUsuario: "Invitado",
                                      nombreRestaurante: rest['nombre'],
                                      idRestaurante: rest['id'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 22),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // IMAGEN / LOGO
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(25),
                                      ),
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            imagenesRestaurantes[rest['nombre']] ??
                                                'assets/images/default.png',
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                          Container(
                                            height: 180,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.4),
                                                  Colors.transparent
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // NOMBRE
                                          Text(
                                            rest['nombre'] ?? 'Sin nombre',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // TIPO
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.restaurant,
                                                size: 14,
                                                color: Colors.deepOrange,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                "Restaurante",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

  Widget _imagenPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.deepOrange.withOpacity(0.08),
      child: const Icon(
        Icons.restaurant,
        size: 60,
        color: Colors.deepOrange,
      ),
    );
  }
}