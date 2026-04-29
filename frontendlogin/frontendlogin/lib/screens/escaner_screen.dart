import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/api_config.dart';
import 'menu_screen.dart';

class EscanerScreen extends StatefulWidget {
  final String nombreUsuario;
  final String nombreRestaurante;
  final int idRestaurante;

  const EscanerScreen({
    super.key,
    required this.nombreUsuario,
    required this.nombreRestaurante,
    required this.idRestaurante,
  });

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _codigoDetectado = false;
  bool _buscandoMesa = false;

  // Recibe el código escaneado o escrito (ej. "MESA-01" o "1")
  // y busca el MesaID real en la BD antes de navegar
  Future<void> _irAlMenu(String codigoMesa) async {
    if (_codigoDetectado) return;
    if (codigoMesa.trim().isEmpty) return;

    setState(() {
      _codigoDetectado = true;
      _buscandoMesa = true;
    });

    try {
      // Obtener todas las mesas del restaurante y buscar por NumeroMesa o código
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/mesas/${widget.idRestaurante}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> mesas = jsonDecode(response.body);

        // Intentar hacer match por número (ej. "MESA-01" → busca "1", "01", etc.)
        // o directamente si el QR contiene el número entero
        final String codigoLimpio = codigoMesa
            .replaceAll(RegExp(r'[^0-9]'), ''); // extrae solo los dígitos

        Map<String, dynamic>? mesaEncontrada;

        // Primero intenta match exacto por número
        for (final mesa in mesas) {
          final String numeroMesa = mesa['NumeroMesa'].toString();
          if (numeroMesa == codigoLimpio ||
              numeroMesa == codigoMesa.trim()) {
            mesaEncontrada = Map<String, dynamic>.from(mesa);
            break;
          }
        }

        // Si no encontró, intenta match ignorando ceros iniciales
        if (mesaEncontrada == null && codigoLimpio.isNotEmpty) {
          final int? numeroBuscado = int.tryParse(codigoLimpio);
          for (final mesa in mesas) {
            final int? numeroMesa =
                int.tryParse(mesa['NumeroMesa'].toString());
            if (numeroBuscado != null && numeroMesa == numeroBuscado) {
              mesaEncontrada = Map<String, dynamic>.from(mesa);
              break;
            }
          }
        }

        if (mesaEncontrada != null) {
          final int mesaID = mesaEncontrada['MesaID'];
          final String nombreMesa =
              'Mesa ${mesaEncontrada['NumeroMesa']}';

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MenuScreen(
                  restaurante: widget.nombreRestaurante,
                  mesa: nombreMesa,
                  idRestaurante: widget.idRestaurante,
                  mesaID: mesaID,
                ),
              ),
            );
          }
        } else {
          // Mesa no encontrada — reiniciar para que pueda escanear de nuevo
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Mesa "$codigoMesa" no encontrada en este restaurante'),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() {
              _codigoDetectado = false;
              _buscandoMesa = false;
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al consultar mesas. Intenta de nuevo.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _codigoDetectado = false;
            _buscandoMesa = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _codigoDetectado = false;
          _buscandoMesa = false;
        });
      }
    }
  }

  void _mostrarIngresoManual() {
    final TextEditingController manualController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mesa en ${widget.nombreRestaurante}'),
        content: TextField(
          controller: manualController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Ej. 5',
            labelText: 'Número de mesa',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _irAlMenu(manualController.text);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child:
                const Text('Entrar', style: TextStyle(color: Colors.white)),
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
                final String codigo =
                    barcodes.first.rawValue ?? "Desconocido";
                _irAlMenu(codigo);
              }
            },
          ),

          // Marco de escaneo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepOrange, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Overlay de carga mientras busca la mesa
          if (_buscandoMesa)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.deepOrange),
                    SizedBox(height: 16),
                    Text(
                      'Buscando mesa...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Botón ingreso manual
          if (!_buscandoMesa)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  const Text(
                    "¿Problemas con el código?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _mostrarIngresoManual,
                    icon: const Icon(Icons.keyboard, color: Colors.black),
                    label: const Text(
                      "Ingresar número de mesa",
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}