import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SoporteBoton extends StatelessWidget {
  const SoporteBoton({super.key});

  static const String _telefono = '528119875815';
  static const String _mensaje = 'Hola, necesito soporte técnico con MyVorder.';

  Future<void> _abrirWhatsApp(BuildContext context) async {
    final Uri url = Uri.parse(
      'https://wa.me/$_telefono?text=${Uri.encodeComponent(_mensaje)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _abrirWhatsApp(context),
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: const Text(
          'Soporte Técnico',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
