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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Restaurante"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre del restaurante",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
  onPressed: () async {
    final nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un nombre")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/restaurantes"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombre,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restaurante creado")),
        );

        Navigator.pop(context, true); // 👈 regresamos y avisamos que se creó
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error conexión: $e")),
      );
    }
  },
  child: const Text("Guardar"),
)
          ],
        ),
      ),
    );
  }
}