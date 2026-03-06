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

  // RESTAURANTES
  final List<Map<String, dynamic>> restaurantesLocales = [
    {
      "nombre": "EL PEQUEÑO CESAR",
      "rating": 4.3,
      "precio": "\$\$",
      "imagen": "assets/images/cesars.png"
    },
    {
      "nombre": "TACOS PEPE",
      "rating": 4.6,
      "precio": "\$",
      "imagen": "assets/images/pepe.png"
    },
    {
      "nombre": "BURGER HOUSE",
      "rating": 4.5,
      "precio": "\$\$",
      "imagen": "assets/images/burger.png"
    }
  ];

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

          //  FONDO
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

                  const Text(
                    '¿Dónde comerás hoy?',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Elige entre las siguientes opciones',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 30),
                      itemCount: restaurantesLocales.length,
                      itemBuilder: (context, index) {

                        final rest = restaurantesLocales[index];

                        return InkWell(
                          borderRadius: BorderRadius.circular(25),
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

                                // IMAGEN RESTAURANTE
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(25)),
                                  child: Image.asset(
                                    rest['imagen'],
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      //  NOMBRE
                                      Text(
                                        rest['nombre'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Row(
                                        children: [

                                          const Icon(
                                            Icons.star,
                                            size: 18,
                                            color: Colors.amber,
                                          ),

                                          const SizedBox(width: 5),

                                          Text(
                                            rest['rating'].toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),

                                          const SizedBox(width: 12),

                                          const Text(
                                            "Restaurante",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),

                                          const Spacer(),

                                          //  PRECIO
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.deepOrange
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              rest['precio'],
                                              style: const TextStyle(
                                                color: Colors.deepOrange,
                                                fontWeight: FontWeight.bold,
                                              ),
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
