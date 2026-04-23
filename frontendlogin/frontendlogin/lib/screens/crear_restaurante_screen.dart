import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/restaurante_service.dart';

class CrearRestauranteScreen extends StatefulWidget {
  const CrearRestauranteScreen({super.key});

  @override
  State<CrearRestauranteScreen> createState() =>
      _CrearRestauranteScreenState();
}

class _CrearRestauranteScreenState
    extends State<CrearRestauranteScreen> {

  final TextEditingController nombreController = TextEditingController();
  final RestauranteService _service = RestauranteService();

  bool isLoading = false;
  bool hoveringButton = false;

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(
        color: Colors.deepOrange,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: const Icon(Icons.restaurant, color: Colors.deepOrange),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
      ),
    );
  }

  // ─── Modal de credenciales (se ve UNA SOLA VEZ) ───────────────
  void _mostrarCredenciales(String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false, // obliga a presionar el botón
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: const [
            Icon(Icons.lock_outline, color: Colors.deepOrange, size: 48),
            SizedBox(height: 10),
            Text(
              "Credenciales generadas",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Advertencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Guarda esta información. No podrás verla de nuevo.",
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Email
            _credencialTile(
              label: "Correo",
              value: email,
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 12),

            // Contraseña
            _credencialTile(
              label: "Contraseña",
              value: password,
              icon: Icons.key_outlined,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);  // cierra modal
                Navigator.pop(context, true);  // regresa al admin
              },
              child: const Text(
                "Entendido, ya lo guardé",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tile de cada credencial con botón de copiar
  Widget _credencialTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black54)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Botón copiar
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.deepOrange),
            tooltip: "Copiar",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$label copiado")),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Acción de guardar ─────────────────────────────────────────
  Future<void> _guardarRestaurante() async {
    final nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un nombre")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await _service.crearRestaurante(nombre);

      setState(() => isLoading = false);

      final email = data['credenciales']['email'];
      final password = data['credenciales']['password'];

      _mostrarCredenciales(email, password);

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ─── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // FONDO ADMIN
          SizedBox.expand(
            child: Image.asset(
              'assets/images/fondoadmin.png',
              fit: BoxFit.cover,
            ),
          ),

          // Overlay blanco suave
          Container(color: Colors.white.withOpacity(0.18)),

          // BOTÓN ATRÁS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // CONTENIDO PRINCIPAL
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(Icons.add_business,
                        size: 70, color: Colors.deepOrange),

                    const SizedBox(height: 20),

                    const Text(
                      "Nuevo Restaurante",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Registra un nuevo restaurante en la plataforma.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),

                    const SizedBox(height: 30),

                    TextField(
                      controller: nombreController,
                      decoration: _inputDecoration("Nombre del restaurante"),
                    ),

                    const SizedBox(height: 30),

                    MouseRegion(
                      onEnter: (_) => setState(() => hoveringButton = true),
                      onExit: (_) => setState(() => hoveringButton = false),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _guardarRestaurante,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hoveringButton
                                ? Colors.orangeAccent
                                : Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Guardar Restaurante",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}