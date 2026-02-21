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
}
