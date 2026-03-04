import 'package:flutter/material.dart';
import 'crear_restaurante_screen.dart'; // 👈 asegúrate de tener este import

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Administrador"),
      ),
      body: const Center(
        child: Text("Bienvenido Admin"),
      ),

      // 👇 BOTÓN FLOTANTE
      floatingActionButton: FloatingActionButton(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CrearRestauranteScreen(),
      ),
    );

    if (result == true) {
      print("Se creó restaurante, refrescar lista");
      // Aquí luego recargaremos la lista si quieres mostrarla
    }
  },
  child: const Icon(Icons.add),
),
    );
  }
}