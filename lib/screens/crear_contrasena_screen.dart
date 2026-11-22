import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/usuario_service.dart';

/// Pantalla 16b (activar cuenta por invitación). Los textos son parámetros
/// para reutilizarla en la pantalla 16 (nueva contraseña tras recuperarla).
class CrearContrasenaScreen extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final String textoBoton;
  final String mensajeExito;
  final bool conCancelar; // muestra el enlace "Cancelar" (pantalla 16)

  const CrearContrasenaScreen({
    super.key,
    this.titulo = 'Bienvenido a InterTrack',
    this.subtitulo = 'Crea tu contraseña para activar tu cuenta.',
    this.textoBoton = 'Activar cuenta',
    this.mensajeExito = 'Cuenta activada. Inicia sesión.',
    this.conCancelar = false,
  });

  @override
  State<CrearContrasenaScreen> createState() => _CrearContrasenaScreenState();
}

class _CrearContrasenaScreenState extends State<CrearContrasenaScreen> {
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _ocultar = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nueva.addListener(() => setState(() {}));
    _confirmar.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  bool get _longitudOk => _nueva.text.length >= 8;
  bool get _letraOk => RegExp(r'[A-Za-z]').hasMatch(_nueva.text);
  bool get _numeroOk => RegExp(r'[0-9]').hasMatch(_nueva.text);
  bool get _coincideOk =>
      _confirmar.text.isNotEmpty && _nueva.text == _confirmar.text;
  bool get _valida => _longitudOk && _letraOk && _numeroOk && _coincideOk;

  Future<void> _activar() async {
    setState(() => _guardando = true);
    try {
      await UsuarioService().crearContrasena(_nueva.text);
      await AuthService().cerrarSesion(); // luego inicia sesión con su contraseña nueva
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.mensajeExito)));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'No se pudo guardar la contraseña. Pide un nuevo enlace e intenta de nuevo.')));
      setState(() => _guardando = false);
    }
  }

  Widget _requisito(String texto, bool cumplido) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text('• $texto',
        style: TextStyle(
            fontSize: 12,
            color: cumplido ? AppColors.verde : AppColors.gris)),
  );

  @override
  Widget build(BuildContext context) {
    final ojo = IconButton(
      icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility,
          color: AppColors.gris, size: 20),
      onPressed: () => setState(() => _ocultar = !_ocultar),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
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
            Text(widget.titulo,
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(widget.subtitulo,
                style: const TextStyle(color: AppColors.gris, fontSize: 14)),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Nueva contraseña',
              hint: 'Mínimo 8 caracteres, letras y números',
              controller: _nueva,
              obscure: _ocultar,
              suffix: ojo,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirmar contraseña',
              hint: 'Repite la contraseña',
              controller: _confirmar,
              obscure: _ocultar,
            ),
            const SizedBox(height: 14),
            _requisito('Mínimo 8 caracteres', _longitudOk),
            _requisito('Al menos una letra', _letraOk),
            _requisito('Al menos un número', _numeroOk),
            _requisito('Ambas contraseñas deben coincidir', _coincideOk),
            const SizedBox(height: 14),
            PrimaryButton(
              text: widget.textoBoton,
              onPressed: _valida && !_guardando ? _activar : null,
            ),
            if (widget.conCancelar) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false),
                  child: const Text('Cancelar',
                      style: TextStyle(
                          color: AppColors.azul,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}