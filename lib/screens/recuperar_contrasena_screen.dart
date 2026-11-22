import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`
import 'package:intertrack_app/widgets.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _correo = TextEditingController();
  bool _enviado = false;
  bool _enviando = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final correo = _correo.text.trim();
    if (!correo.contains('@') || !correo.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe un correo válido')));
      return;
    }
    setState(() => _enviando = true);
    try {
      // El enlace es de un solo uso y con vigencia limitada (RNF-012).
      // Mismo esquema y host que el intent-filter del AndroidManifest.
      await supabase.auth
          .resetPasswordForEmail(correo, redirectTo: 'intertrack://acceso');
    } catch (_) {
      // Se muestra el mismo mensaje exista o no el correo, para no revelar
      // qué cuentas están registradas.
    }
    if (mounted) {
      setState(() {
        _enviando = false;
        _enviado = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: AppColors.azul, size: 16),
                  SizedBox(width: 6),
                  Text('Volver a iniciar sesión',
                      style: TextStyle(
                          color: AppColors.azul,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: AppColors.azul, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(height: 24),
            const Text('¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const Text(
                'Ingresa el correo electrónico con el que te registraste y te enviaremos un enlace para restablecerla.',
                style: TextStyle(
                    color: AppColors.gris, fontSize: 15, height: 1.35)),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Correo electrónico',
              hint: 'correo@ejemplo.com',
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            PrimaryButton(
                text: 'Enviar instrucciones',
                onPressed: _enviando ? null : _enviar),
            const SizedBox(height: 18),
            Text(
              _enviado
                  ? 'Si el correo está registrado, recibirás un enlace en unos minutos. Es temporal; si no lo ves, revisa la carpeta de spam.'
                  : 'El enlace es temporal. Si no lo ves en tu bandeja, revisa la carpeta de spam.',
              style: TextStyle(
                  color: _enviado ? AppColors.verde : AppColors.gris,
                  fontSize: 12,
                  height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}