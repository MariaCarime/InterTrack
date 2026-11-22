import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/sucursal.dart';
import 'package:intertrack_app/screens/usuarios_roles_screen.dart';
import 'package:intertrack_app/models/usuario_service.dart';

class RegistrarUsuarioScreen extends StatefulWidget {
  const RegistrarUsuarioScreen({super.key});

  @override
  State<RegistrarUsuarioScreen> createState() => _RegistrarUsuarioScreenState();
}

class _RegistrarUsuarioScreenState extends State<RegistrarUsuarioScreen> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _servicio = UsuarioService();

  List<Sucursal> _sucursales = [];
  String? _sucursal;
  String? _rol;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    super.dispose();
  }

  void _mensaje(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _cargarSucursales() async {
    try {
      final datos = await _servicio.sucursales();
      if (!mounted) return;
      setState(() => _sucursales = datos);
    } catch (_) {
      _mensaje('No se pudieron cargar las sucursales');
    }
  }

  Future<void> _registrar() async {
    final nombre = _nombre.text.trim();
    final correo = _correo.text.trim();
    if (nombre.isEmpty) {
      _mensaje('Escribe el nombre completo');
      return;
    }
    if (!correo.contains('@') || !correo.contains('.')) {
      _mensaje('Escribe un correo válido');
      return;
    }
    if (_rol == null) {
      _mensaje('Selecciona un rol');
      return;
    }
    if (_sucursal == null) {
      _mensaje('Selecciona una sucursal');
      return;
    }

    final idSucursal =
        _sucursales.firstWhere((s) => s.nombre == _sucursal).idSucursal;

    setState(() => _guardando = true);
    try {
      await _servicio.invitar(
        nombre: nombre,
        correo: correo,
        rolBd: kRolesBd[_rol!]!,
        idSucursal: idSucursal,
      );
      _mensaje('Invitación enviada a $correo');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Rol: Gerente General',
            title: 'Registrar nuevo usuario',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                    label: 'Nombre completo',
                    hint: 'Nombre y apellidos',
                    controller: _nombre),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Correo electrónico',
                  hint: 'correo@ejemplo.com',
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppSelectField(
                  label: 'Sucursal',
                  hint: 'Seleccionar sucursal',
                  options: _sucursales.map((s) => s.nombre).toList(),
                  value: _sucursal,
                  onSelected: (v) => setState(() => _sucursal = v),
                  emptyMessage: 'Aún no hay sucursales registradas.',
                ),
                const SizedBox(height: 16),
                AppSelectField(
                  label: 'Rol asignado',
                  hint: 'Seleccionar rol',
                  options: kRoles,
                  value: _rol,
                  onSelected: (v) => setState(() => _rol = v),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Se enviará un correo de invitación para que el usuario cree su propia contraseña.',
                    style: TextStyle(color: AppColors.gris, fontSize: 12)),
                const SizedBox(height: 14),
                PrimaryButton(
                    text: _guardando
                        ? 'Enviando...'
                        : 'Registrar y enviar invitación',
                    onPressed: _guardando ? null : _registrar),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(
                          color: AppColors.azul,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}