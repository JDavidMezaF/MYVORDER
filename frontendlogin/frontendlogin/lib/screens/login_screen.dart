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
  bool _esLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();

  final AuthService authService = AuthService();
  bool isLoading = false;
  String _rolSeleccionado = "cliente";

  bool _hoveringButton = false;

  void _toggleForm() {
    setState(() {
      _esLogin = !_esLogin;
    });
  }

  Future<void> _procesarFormulario() async {
    if (_esLogin) {
      setState(() => isLoading = true);

      final result = await authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      if (result["statusCode"] == 200) {
        final usuario = result["data"]["usuario"];
        final rol = usuario["rol"].toString().toLowerCase().trim();

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
          SnackBar(
            content: Text(
              result["data"]?["message"] ?? "Error al iniciar sesión",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
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

        final loginResult = await authService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (loginResult["statusCode"] == 200) {
          final usuario = loginResult["data"]["usuario"];
          final rol =
              usuario["Rol"].toString().toLowerCase().trim();

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
      }
    }
  }

  InputDecoration _inputDecoration(String textoLabel, IconData icon) {
    return InputDecoration(
      // ✨ EL TRUCO: Contenedor camuflado
      label: Container(
        // Un poco de relleno para que proteja las letras cuando esté sobre la comida
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white, // Se camufla adentro, protege afuera
          borderRadius: BorderRadius.circular(8),
          // 🚨 ¡Eliminamos el border: Border.all()! Así ya no parece botón adentro
        ),
        child: Text(
          textoLabel,
          style: const TextStyle(
            color: Colors.deepOrange, // Lo dejamos naranja como sugeriste
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),

      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Icon(icon, color: Colors.deepOrange, size: 28),
      ),

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 15),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 2.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/fondologin.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.25),
          ),
          SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 220),

                  const Text(
                    "Bienvenido",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          blurRadius: 15,
                          color: Colors.black54,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "My Virtual Order",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [

                        if (!_esLogin)
                          TextField(
                            controller: _nombreController,
                            decoration: _inputDecoration(
                                'Nombre Completo', Icons.person),
                          ),

                        if (!_esLogin)
                          const SizedBox(height: 15),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                              'Correo Electrónico', Icons.email),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration(
                              'Contraseña', Icons.lock),
                        ),

                        if (!_esLogin) ...[
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            value: _rolSeleccionado,
                            decoration: _inputDecoration(
                                'Selecciona Rol',
                                Icons.admin_panel_settings),
                            items: const [
                              DropdownMenuItem(
                                value: "cliente",
                                child: Text("Cliente"),
                              ),
                              DropdownMenuItem(
                                value: "restaurante",
                                child: Text("Restaurante"),
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

                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveringButton = true),
                          onExit: (_) =>
                              setState(() => _hoveringButton = false),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : _procesarFormulario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hoveringButton
                                    ? Colors.orangeAccent
                                    : Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      _esLogin
                                          ? 'Iniciar Sesión'
                                          : 'Registrarse',
                                      style: const TextStyle(
                                          fontSize: 18),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        GestureDetector(
                          onTap: _toggleForm,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                              children: [
                                // ✨ Quitamos el 'const' y ponemos la condición
                                TextSpan(
                                  text: _esLogin ? "¿No tienes cuenta? " : "¿Ya tienes una cuenta? ",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                // ✨ Aquí también cambia el texto según la pantalla
                                TextSpan(
                                  text: _esLogin ? "Regístrate" : "Iniciar Sesión",
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}