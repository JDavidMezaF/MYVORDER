import 'package:flutter/material.dart';

class RestaurantesScreen extends StatelessWidget {
  const RestaurantesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurantes"),
      ),
      body: const Center(
        child: Text(
          "Bienvenido a Restaurantes",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
