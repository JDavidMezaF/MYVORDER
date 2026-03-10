import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'crear_restaurante_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _restaurantes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRestaurantes();
  }

  Future<void> _cargarRestaurantes() async {
    setState(() => _cargando = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/restaurantes'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _restaurantes = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Error al cargar restaurantes: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

          // Overlay ligero blanco
          Container(
            color: Colors.white.withOpacity(0.15),
          ),

          // CONTENIDO PRINCIPAL
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [

                  // ENCABEZADO
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Bienvenido Administrador",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Desde aquí puedes gestionar los restaurantes de la plataforma.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),

                        // BOTÓN CREAR
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CrearRestauranteScreen(),
                                ),
                              );
                              if (result == true) {
                                _cargarRestaurantes(); // Refresca la lista
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TÍTULO LISTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Restaurantes registrados",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                        ),
                      ),
                      IconButton(
                        onPressed: _cargarRestaurantes,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: "Refrescar",
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // LISTA DE RESTAURANTES
                  Expanded(
                    child: _cargando
                        ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                        : _restaurantes.isEmpty
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(25),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Text(
                                    "No hay restaurantes aún.\n¡Crea el primero!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54, fontSize: 15),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _restaurantes.length,
                                itemBuilder: (context, index) {
                                  final rest = _restaurantes[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 4,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: rest['logo'] != null && rest['logo'].toString().isNotEmpty
                                            ? Image.network(
                                                rest['logo'],
                                                width: 55,
                                                height: 55,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => _iconoRestaurante(),
                                              )
                                            : _iconoRestaurante(),
                                      ),
                                      title: Text(
                                        rest['nombre'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'ID: ${rest['id']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      trailing: const Icon(
                                        Icons.restaurant,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconoRestaurante() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 30),
    );
  }
}