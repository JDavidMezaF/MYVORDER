import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
   Future<Map<String, dynamic>> login(
      String email, String password) async {

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/usuarios/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "EMail": email,
        "Password": password,
      }),
    );

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

Future<Map<String, dynamic>> register(
  String nombre,
  String email,
  String password,
) async {

  final response = await http.post(
    Uri.parse("${ApiConfig.baseUrl}/api/usuarios"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "Nombre": nombre,
      "EMail": email,
      "Password": password,
    }),
  );

  // 👇 ESTO ES LO NUEVO (para ver el error real)
  print("STATUS CODE: ${response.statusCode}");
  print("RESPONSE BODY: ${response.body}");

  return {
    "statusCode": response.statusCode,
    "data": response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {},
  };
}
}
