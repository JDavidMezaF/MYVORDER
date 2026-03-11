import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CrearRestauranteScreen extends StatefulWidget {
  const CrearRestauranteScreen({super.key});

  @override
  State<CrearRestauranteScreen> createState() =>
      _CrearRestauranteScreenState();
}

class _CrearRestauranteScreenState
    extends State<CrearRestauranteScreen> {

  final TextEditingController nombreController =
      TextEditingController();

  bool isLoading = false;
  bool hoveringButton = false;

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(
        color: Colors.deepOrange,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon:
          const Icon(Icons.restaurant, color: Colors.deepOrange),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
            color: Colors.deepOrange, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          //FONDO ADMIN
          SizedBox.expand(
            child: Image.asset(
              'assets/images/fondoadmin.png',
              fit: BoxFit.cover,
            ),
          ),

          //Overlay blanco suave
          Container(
            color: Colors.white.withOpacity(0.18),
          ),

          // BOTÓN ATRÁS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
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
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ),
            ),
          ),

          //CONTENIDO PRINCIPAL
          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30),
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
                      Icons.add_business,
                      size: 70,
                      color: Colors.deepOrange,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Nuevo Restaurante",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Registra un nuevo restaurante en la plataforma.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      controller: nombreController,
                      decoration: _inputDecoration(
                          "Nombre del restaurante"),
                    ),

                    const SizedBox(height: 30),

                    MouseRegion(
                      onEnter: (_) =>
                          setState(() => hoveringButton = true),
                      onExit: (_) =>
                          setState(() => hoveringButton = false),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final nombre =
                                      nombreController.text.trim();

                                  if (nombre.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Ingresa un nombre")),
                                    );
                                    return;
                                  }

                                  setState(
                                      () => isLoading = true);

                                  try {
                                    final response =
                                        await http.post(
                                      Uri.parse(
                                          "${ApiConfig.baseUrl}/api/restaurantes"),
                                      headers: {
                                        "Content-Type":
                                            "application/json"
                                      },
                                      body: jsonEncode({
                                        "nombre": nombre,
                                      }),
                                    );

                                    setState(() =>
                                        isLoading = false);

                                    if (response.statusCode ==
                                            200 ||
                                        response.statusCode ==
                                            201) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Restaurante creado")),
                                      );

                                      Navigator.pop(
                                          context, true);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Error: ${response.body}")),
                                      );
                                    }
                                  } catch (e) {
                                    setState(() =>
                                        isLoading = false);

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Error conexión: $e")),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hoveringButton
                                ? Colors.orangeAccent
                                : Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 18),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      15),
                            ),
                            elevation: 5,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Guardar Restaurante",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                        ),
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