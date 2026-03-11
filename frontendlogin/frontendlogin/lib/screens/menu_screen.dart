import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'carrito_screen.dart';

class MenuScreen extends StatefulWidget {
  final String restaurante;
  final String mesa;
  final int idRestaurante;

  const MenuScreen({
    super.key,
    required this.restaurante,
    required this.mesa,
    required this.idRestaurante,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> _platillos = [];
  bool _cargando = true;
  final List<Map<String, dynamic>> _miCarrito = [];

  @override
  void initState() {
    super.initState();
    _cargarMenu();
  }

  Future<void> _cargarMenu() async {
    setState(() => _cargando = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/menu/${widget.idRestaurante}'),
      );
      if (response.statusCode == 200) {
        setState(() => _platillos = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error al cargar menú: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _agregarAlCarrito(Map<String, dynamic> platillo) {
  setState(() {
    int index = _miCarrito.indexWhere((item) => item['nombre'] == platillo['nombre']);

    if (index != -1) {
      _miCarrito[index]['cantidad']++;
    } else {
      _miCarrito.add({
        'nombre': platillo['nombre'],
        'precio': double.tryParse(platillo['precio'].toString()) ?? 0.0,
        'cantidad': 1,
        'imagen': platillo['imagen'] ?? 'assets/images/taco.png',
      });
    }
  });
}

  void _removerDelCarrito(Map<String, dynamic> platillo) {
    setState(() {
      int index = _miCarrito.indexWhere((item) => item['nombre'] == platillo['nombre']);
      if (index != -1) {
        if (_miCarrito[index]['cantidad'] > 1) {
          _miCarrito[index]['cantidad']--;
        } else {
          _miCarrito.removeAt(index);
        }
      }
    });
  }

  int _obtenerCantidad(String nombre) {
    int index = _miCarrito.indexWhere((item) => item['nombre'] == nombre);
    return index != -1 ? _miCarrito[index]['cantidad'] : 0;
  }

  @override
  Widget build(BuildContext context) {
    int totalArticulos = 0;
    for (var item in _miCarrito) {
      totalArticulos += item['cantidad'] as int;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.restaurante),
            Text(
              'Mesa: ${widget.mesa}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            )
          : _platillos.isEmpty
              ? const Center(
                  child: Text(
                    "Este restaurante aún no tiene platillos.",
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _platillos.length,
                  itemBuilder: (context, index) {
                    final platillo = _platillos[index];
                    final double precio =
                        double.tryParse(platillo['precio'].toString()) ?? 0.0;
                    final int cantidadActual =
                        _obtenerCantidad(platillo['nombre']);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // IMAGEN O PLACEHOLDER
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.deepOrange.withOpacity(0.08),
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.deepOrange,
                                size: 40,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // NOMBRE, DESCRIPCIÓN Y PRECIO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  platillo['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (platillo['descripcion'] != null &&
                                    platillo['descripcion'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      platillo['descripcion'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 5),
                                Text(
                                  '\$${precio.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // CONTROLES CARRITO
                          cantidadActual == 0
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.deepOrange,
                                    size: 35,
                                  ),
                                  onPressed: () => _agregarAlCarrito(platillo),
                                )
                              : Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.deepOrange,
                                      ),
                                      onPressed: () =>
                                          _removerDelCarrito(platillo),
                                    ),
                                    Text(
                                      '$cantidadActual',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.deepOrange,
                                      ),
                                      onPressed: () =>
                                          _agregarAlCarrito(platillo),
                                    ),
                                  ],
                                ),

                          const SizedBox(width: 5),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarritoScreen(
                restaurante: widget.restaurante,
                mesa: widget.mesa,
                platillosCarrito: _miCarrito,
              ),
            ),
          );
          setState(() {});
        },
        backgroundColor: Colors.deepOrange,
        icon: Badge(
          label: Text('$totalArticulos'),
          isLabelVisible: totalArticulos > 0,
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
        label: const Text('Ver Pedido', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}