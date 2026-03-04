import 'package:flutter/material.dart';
import 'crear_restaurante_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          //FONDO
          SizedBox.expand(
            child: Image.asset(
              'assets/images/fondoadmin.png',
              fit: BoxFit.cover,
            ),
          ),

          //Overlay ligero blanco para elegancia
          Container(
            color: Colors.white.withOpacity(0.15),
          ),

          //CONTENIDO PRINCIPAL
          Center(
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

                    const Icon(
                      Icons.admin_panel_settings,
                      size: 70,
                      color: Colors.deepOrange,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Bienvenido Administrador",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Desde aquí puedes gestionar los restaurantes de la plataforma.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 35),

                    //BOTÓN PRINCIPAL CENTRADO
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_business),
                        label: const Text(
                          "Crear Nuevo Restaurante",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CrearRestauranteScreen(),
                            ),
                          );

                          if (result == true) {
                            print(
                                "Se creó restaurante, refrescar lista");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}