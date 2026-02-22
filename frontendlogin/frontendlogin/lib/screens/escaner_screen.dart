import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'menu_screen.dart';

class EscanerScreen extends StatefulWidget {
  final String nombreUsuario;
  final String nombreRestaurante;

  const EscanerScreen({
    super.key,
    required this.nombreUsuario,
    required this.nombreRestaurante
  });

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _codigoDetectado = false;

  void _irAlMenu(String codigoMesa) {
    if (_codigoDetectado) return;
    if (codigoMesa.trim().isEmpty) return;

    setState(() {
      _codigoDetectado = true;
    });

    // Navegación real al Menú
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          restaurante: widget.nombreRestaurante,
          mesa: codigoMesa,
        ),
      ),
    );
  }

  void _mostrarIngresoManual() {
    final TextEditingController manualController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mesa en ${widget.nombreRestaurante}'),
        content: TextField(
          controller: manualController,
          decoration: const InputDecoration(
            hintText: 'Ej. MESA-05',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _irAlMenu(manualController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Entrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escáner - ${widget.nombreRestaurante}'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String codigo = barcodes.first.rawValue ?? "Desconocido";
                _irAlMenu(codigo);
              }
            },
          ),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepOrange, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 50, left: 20, right: 20,
            child: Column(
              children: [
                const Text(
                  "¿Problemas con el código?",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)]
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _mostrarIngresoManual,
                  icon: const Icon(Icons.keyboard, color: Colors.black),
                  label: const Text("Ingresar código manualmente", style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      // Botón flotante para simular que escaneaste algo en el emulador
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irAlMenu("MESA-01"),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }
}