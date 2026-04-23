import 'package:flutter/material.dart';
import 'login_screen.dart';

class RestauranteHomeScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const RestauranteHomeScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final nombre = usuario["Nombre"] ?? "Restaurante";

    return Scaffold(
      body: Stack(
        children: [

          // FONDO
          SizedBox.expand(
            child: Image.asset(
              'assets/images/fondoadmin.png',
              fit: BoxFit.cover,
            ),
          ),

          // Overlay suave
          Container(color: Colors.white.withOpacity(0.18)),

          // CONTENIDO
          SafeArea(
            child: Column(
              children: [

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      // Logo / título
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.deepOrange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "MyVorder",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // Botón cerrar sesión
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.deepOrange,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENIDO CENTRAL
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Container(
                        padding: const EdgeInsets.all(35),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // Ícono
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront,
                                size: 60,
                                color: Colors.deepOrange,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Bienvenida
                            const Text(
                              "¡Bienvenido!",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Nombre del restaurante
                            Text(
                              nombre,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Línea divisora
                            Container(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),

                            const SizedBox(height: 16),

                            // Mensaje
                            const Text(
                              "Tu panel de pedidos estará disponible pronto. Por ahora todo está listo para comenzar.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Badge de estado
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      size: 10,
                                      color: Colors.green.shade400),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Cuenta activa",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}