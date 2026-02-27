import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'restaurantes_screen.dart';
import 'admin_screen.dart';

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
  String _rolSeleccionado = "cliente";

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
      print("DATA COMPLETA: ${result["data"]}");
    
      final usuario = result["data"]["usuario"];

      final rol = usuario["Rol"]
          .toString()
          .toLowerCase()
          .trim();

     print("ROL NORMALIZADO: $rol");

     if (rol == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else {
       Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RestaurantesScreen()),
        );
      }
    }

       else {
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
      if (_nombreController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor llena todos los campos')),
        );
        return;
      }

      setState(() => isLoading = true);

      final result = await authService.register(
        _nombreController.text,
        _emailController.text,
        _passwordController.text,
        _rolSeleccionado,
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      if (result["statusCode"] == 200 || result["statusCode"] == 201) {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Cuenta creada correctamente"),
      backgroundColor: Colors.green,
    ),
  );

  // 👇 LOGIN AUTOMÁTICO DESPUÉS DE REGISTRAR
  final loginResult = await authService.login(
    _emailController.text,
    _passwordController.text,
  );

  if (loginResult["statusCode"] == 200) {

    final usuario = loginResult["data"]["usuario"];

    final rol = usuario["Rol"]
        .toString()
        .toLowerCase()
        .trim();

    if (rol == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RestaurantesScreen()),
      );
    }

  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error al iniciar sesión automáticamente"),
        backgroundColor: Colors.red,
      ),
    );
  }

}
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
              // Selector de Rol (SOLO EN REGISTRO)
              if (!_esLogin) ...[
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona Rol',
                    prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.deepOrange),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "cliente",
                      child: Text("Cliente"),
                    ),
                    DropdownMenuItem(
                      value: "admin",
                      child: Text("Administrador"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _rolSeleccionado = value!;
                    });
                  },
                ),
              ],
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