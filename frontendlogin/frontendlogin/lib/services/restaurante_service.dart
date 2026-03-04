import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RestauranteService {

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
}