import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'restaurantes_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. VARIABLES DE TU DISEÑO ORIGINAL
  bool _esLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();

  // 2. VARIABLES DEL BACKEND DE TU COMPAÑERO
  final AuthService authService = AuthService();
  bool isLoading = false;

  // Función para cambiar entre Login y Registro
  void _toggleForm() {
    setState(() {
      _esLogin = !_esLogin;
    });
  }

  // Lógica fusionada (Diseño + Backend)
  Future<void> _procesarFormulario() async {
    if (_esLogin) {
      // --- LÓGICA DEL COMPAÑERO (LOGIN REAL) ---
      setState(() => isLoading = true);

      final result = await authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      if (result["statusCode"] == 200) {
        // Navegamos a Restaurantes (usando la ruta de tu compañero)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RestaurantesScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result["data"]?["message"] ?? "Error al iniciar sesión",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // --- LÓGICA DE REGISTRO (Pendiente de Backend) ---
      String nombre = _nombreController.text;
      if (nombre.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor llena todos los campos')),
        );
        return;
      }

      // Aviso temporal para tu compañero
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falta conectar el Registro a la Base de Datos (Avisa a tu equipo)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tu diseño de ícono (Mantenemos tu estilo)
              const Icon(Icons.restaurant, size: 80, color: Colors.deepOrange),
              const SizedBox(height: 20),

              Text(
                _esLogin ? 'Bienvenido de nuevo' : 'Crear Cuenta',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 30),

              // Campo Nombre (Solo para Registro)
              if (!_esLogin)
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person, color: Colors.deepOrange),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
                  ),
                ),
              if (!_esLogin) const SizedBox(height: 15),

              // Campo Correo
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: Icon(Icons.email, color: Colors.deepOrange),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
                ),
              ),
              const SizedBox(height: 15),

              // Campo Contraseña
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock, color: Colors.deepOrange),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
                ),
              ),
              const SizedBox(height: 30),

              // Botón Principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Deshabilitamos el botón si la app está pensando (cargando)
                  onPressed: isLoading ? null : _procesarFormulario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white) // Animación del compañero
                      : Text(_esLogin ? 'Iniciar Sesión' : 'Registrarse', style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 15),

              // Cambiar entre Login y Registro
              TextButton(
                onPressed: _toggleForm,
                child: Text(
                  _esLogin
                      ? '¿No tienes cuenta? Regístrate aquí'
                      : '¿Ya tienes cuenta? Inicia sesión',
                  style: TextStyle(color: Colors.deepOrange.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}