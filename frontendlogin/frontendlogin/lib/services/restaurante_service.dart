import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RestauranteService {

  // Obtener todos los restaurantes
  Future<List<dynamic>> obtenerRestaurantes() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/restaurantes"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener restaurantes");
    }
  }

  // Crear restaurante y recibir credenciales generadas
  Future<Map<String, dynamic>> crearRestaurante(String nombre, {String? logo}) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/restaurantes"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        if (logo != null) "logo": logo,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al crear restaurante");
    }
  }
}