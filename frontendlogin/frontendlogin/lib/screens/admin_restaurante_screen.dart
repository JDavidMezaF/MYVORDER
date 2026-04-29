import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AdminRestauranteScreen extends StatefulWidget {
  final Map<String, dynamic> restaurante;

  const AdminRestauranteScreen({super.key, required this.restaurante});

  @override
  State<AdminRestauranteScreen> createState() => _AdminRestauranteScreenState();
}

class _AdminRestauranteScreenState extends State<AdminRestauranteScreen> {
  List<dynamic> _menu = [];
  bool _cargandoMenu = true;

  List<dynamic> _mesas = [];
  bool _cargandoMesas = true;

  // Controladores para editar restaurante
  late TextEditingController _nombreController;
  late TextEditingController _logoController;

  // Controladores para nuevo platillo
  final TextEditingController _platilloNombreController = TextEditingController();
  final TextEditingController _platilloDescController = TextEditingController();
  final TextEditingController _platilloPrecioController = TextEditingController();
  final TextEditingController _platilloCategoriaController = TextEditingController();

  // Controladores para nueva mesa
  final TextEditingController _mesaNumeroController = TextEditingController();
  final TextEditingController _mesaCapacidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.restaurante['nombre']);
    _logoController = TextEditingController(text: widget.restaurante['logo'] ?? '');
    _cargarMenu();
    _cargarMesas();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _logoController.dispose();
    _platilloNombreController.dispose();
    _platilloDescController.dispose();
    _platilloPrecioController.dispose();
    _platilloCategoriaController.dispose();
    _mesaNumeroController.dispose();
    _mesaCapacidadController.dispose();
    super.dispose();
  }

  // ── MENÚ ──

  Future<void> _cargarMenu() async {
    setState(() => _cargandoMenu = true);
    try {
      final id = widget.restaurante['id'];
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/menu/$id'),
      );
      if (response.statusCode == 200) {
        setState(() => _menu = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error al cargar menú: $e");
    } finally {
      setState(() => _cargandoMenu = false);
    }
  }

  Future<void> _editarRestaurante() async {
    final nombre = _nombreController.text.trim();
    final logo = _logoController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre no puede estar vacío")),
      );
      return;
    }

    try {
      final id = widget.restaurante['id'];
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/restaurantes/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre, 'logo': logo}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Restaurante actualizado correctamente"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar restaurante")),
        );
      }
    } catch (e) {
      print("Error al editar: $e");
    }
  }

  Future<void> _agregarPlatillo() async {
    final nombre = _platilloNombreController.text.trim();
    final descripcion = _platilloDescController.text.trim();
    final precioText = _platilloPrecioController.text.trim();
    final categoria = _platilloCategoriaController.text.trim();

    if (nombre.isEmpty || precioText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre y precio son obligatorios")),
      );
      return;
    }

    final precio = double.tryParse(precioText);
    if (precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El precio debe ser un número válido")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/menu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idRestaurante': widget.restaurante['id'],
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'categoria': categoria,
          'disponibilidad': 1,
        }),
      );

      if (response.statusCode == 201) {
        _platilloNombreController.clear();
        _platilloDescController.clear();
        _platilloPrecioController.clear();
        _platilloCategoriaController.clear();
        _cargarMenu();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Platillo agregado correctamente"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error al agregar platillo: $e");
    }
  }

  Future<void> _confirmarEliminarPlatillo(int idMenu, String nombre) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
            SizedBox(width: 10),
            Text("Confirmar eliminación"),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar "$nombre"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No",
                style: TextStyle(color: Colors.black54, fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Sí, eliminar", style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/menu/$idMenu'),
        );
        if (response.statusCode == 200) {
          _cargarMenu();
        }
      } catch (e) {
        print("Error al eliminar platillo: $e");
      }
    }
  }

  // ── MESAS ──

  Future<void> _cargarMesas() async {
    setState(() => _cargandoMesas = true);
    try {
      final id = widget.restaurante['id'];
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/mesas/$id'),
      );
      if (response.statusCode == 200) {
        setState(() => _mesas = jsonDecode(response.body));
      }
    } catch (e) {
      print("Error al cargar mesas: $e");
    } finally {
      setState(() => _cargandoMesas = false);
    }
  }

  Future<void> _agregarMesa() async {
    final numeroText = _mesaNumeroController.text.trim();
    final capacidadText = _mesaCapacidadController.text.trim();

    if (numeroText.isEmpty || capacidadText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Número de mesa y capacidad son obligatorios")),
      );
      return;
    }

    final numero = int.tryParse(numeroText);
    final capacidad = int.tryParse(capacidadText);

    if (numero == null || capacidad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa solo números enteros")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/mesas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'RestauranteID': widget.restaurante['id'],
          'NumeroMesa': numero,
          'Capacidad': capacidad,
          'Estado': 'disponible',
        }),
      );

      if (response.statusCode == 201) {
        _mesaNumeroController.clear();
        _mesaCapacidadController.clear();
        _cargarMesas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mesa agregada correctamente"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al agregar mesa")),
        );
      }
    } catch (e) {
      print("Error al agregar mesa: $e");
    }
  }

  Future<void> _confirmarEliminarMesa(int mesaID, int numeroMesa) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
            SizedBox(width: 10),
            Text("Confirmar eliminación"),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar la Mesa $numeroMesa?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No",
                style: TextStyle(color: Colors.black54, fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Sí, eliminar", style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/mesas/$mesaID'),
        );
        if (response.statusCode == 200) {
          _cargarMesas();
        }
      } catch (e) {
        print("Error al eliminar mesa: $e");
      }
    }
  }

  // ── COLOR POR ESTADO ──
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'ocupada':
        return Colors.redAccent;
      case 'reservada':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.restaurante['nombre'] ?? 'Restaurante'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SECCIÓN EDITAR RESTAURANTE ──
            _seccionTitulo(Icons.store, "Datos del restaurante"),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _campo(
                    controller: _nombreController,
                    label: "Nombre del restaurante",
                    icono: Icons.storefront,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _logoController,
                    label: "URL del logo (opcional)",
                    icono: Icons.image,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Guardar cambios",
                          style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _editarRestaurante,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── SECCIÓN AGREGAR MESA ──
            _seccionTitulo(Icons.table_restaurant, "Agregar mesa"),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _campo(
                    controller: _mesaNumeroController,
                    label: "Número de mesa",
                    icono: Icons.tag,
                    teclado: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _mesaCapacidadController,
                    label: "Capacidad (personas)",
                    icono: Icons.people,
                    teclado: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar mesa",
                          style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _agregarMesa,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── SECCIÓN LISTA DE MESAS ──
            _seccionTitulo(Icons.chair, "Mesas actuales"),
            const SizedBox(height: 12),

            _cargandoMesas
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  )
                : _mesas.isEmpty
                    ? _card(
                        child: const Center(
                          child: Text(
                            "No hay mesas aún.\n¡Agrega la primera!",
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.black45, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _mesas.length,
                        itemBuilder: (context, index) {
                          final mesa = _mesas[index];
                          final int mesaID = mesa['MesaID'];
                          final int numeroMesa = mesa['NumeroMesa'];
                          final int capacidad = mesa['Capacidad'];
                          final String estado = mesa['Estado'] ?? 'disponible';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.table_restaurant,
                                    color: Colors.deepOrange),
                              ),
                              title: Text(
                                "Mesa $numeroMesa",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.people,
                                      size: 14, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text("$capacidad personas  •  ",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _colorEstado(estado)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      estado,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _colorEstado(estado),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 24),
                                tooltip: "Eliminar mesa",
                                onPressed: () =>
                                    _confirmarEliminarMesa(mesaID, numeroMesa),
                              ),
                            ),
                          );
                        },
                      ),

            const SizedBox(height: 28),

            // ── SECCIÓN AGREGAR PLATILLO ──
            _seccionTitulo(Icons.restaurant_menu, "Agregar platillo"),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: [
                  _campo(
                    controller: _platilloNombreController,
                    label: "Nombre del platillo",
                    icono: Icons.fastfood,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _platilloDescController,
                    label: "Descripción (opcional)",
                    icono: Icons.notes,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _platilloPrecioController,
                    label: "Precio",
                    icono: Icons.attach_money,
                    teclado: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _campo(
                    controller: _platilloCategoriaController,
                    label: "Categoría (opcional)",
                    icono: Icons.category,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar al menú",
                          style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _agregarPlatillo,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── SECCIÓN MENÚ ──
            _seccionTitulo(Icons.menu_book, "Menú actual"),
            const SizedBox(height: 12),

            _cargandoMenu
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepOrange),
                  )
                : _menu.isEmpty
                    ? _card(
                        child: const Center(
                          child: Text(
                            "No hay platillos aún.\n¡Agrega el primero!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black45, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _menu.length,
                        itemBuilder: (context, index) {
                          final platillo = _menu[index];
                          final int idMenu = platillo['idMenu'];
                          final String nombre =
                              platillo['nombre'] ?? 'Sin nombre';
                          final String descripcion =
                              platillo['descripcion'] ?? '';
                          final double precio =
                              double.tryParse(platillo['precio'].toString()) ??
                                  0;
                          final String categoria =
                              platillo['categoria'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.fastfood,
                                    color: Colors.deepOrange),
                              ),
                              title: Text(
                                nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (descripcion.isNotEmpty)
                                    Text(descripcion,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        "\$${precio.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (categoria.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrange
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            categoria,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.deepOrange),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 24),
                                tooltip: "Eliminar platillo",
                                onPressed: () =>
                                    _confirmarEliminarPlatillo(idMenu, nombre),
                              ),
                            ),
                          );
                        },
                      ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS AUXILIARES ──

  Widget _seccionTitulo(IconData icono, String titulo) {
    return Row(
      children: [
        Icon(icono, color: Colors.deepOrange, size: 22),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, color: Colors.deepOrange),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.deepOrange, width: 1.5),
        ),
      ),
    );
  }
}