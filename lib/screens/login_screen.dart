import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intertrack_app/models/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    try {
      final usuario = await AuthService()
          .iniciarSesion(_correo.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(usuario.rol.rutaInicial);
    } on AuthException {
      _mostrarError('Correo o contraseña incorrectos');
    } catch (e) {
      _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: AppColors.azul, shape: BoxShape.circle),
                ),
                const SizedBox(height: 12),
                const Text('InterTrack',
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Gestión de pedidos y logística',
                    style: TextStyle(color: AppColors.gris, fontSize: 14)),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Correo electrónico',
                  hint: 'correo@ejemplo.com',
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Contraseña',
                  hint: '••••••••',
                  controller: _password,
                  obscure: _ocultar,
                  suffix: IconButton(
                    icon: Icon(
                        _ocultar ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.gris,
                        size: 20),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(text: 'Iniciar sesión', onPressed: _iniciarSesion),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // TODO: pantalla 15 (solicitar enlace de recuperación)
                  },
                  child: const Text('¿Olvidaste tu contraseña?',
                      style: TextStyle(
                          color: AppColors.azul,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                const SizedBox(height: 8),
                const Text('Tu rol se asigna automáticamente según tu usuario.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gris, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}