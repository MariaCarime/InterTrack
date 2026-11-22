import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/usuario_service.dart';

const List<String> kRoles = [
  'Gerente General',
  'Gerente de Compras',
  'Asesor',
  'Planta',
];

class UsuarioApp {
  final int idUsuario;
  String nombre;
  String correo;
  String rol;
  bool activo;
  bool pendiente; // invitado que aún no activa su cuenta
  final bool esYo;

  UsuarioApp({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.activo = true,
    this.pendiente = false,
    this.esYo = false,
  });
}

class UsuariosRolesScreen extends StatefulWidget {
  const UsuariosRolesScreen({super.key});

  @override
  State<UsuariosRolesScreen> createState() => _UsuariosRolesScreenState();
}

class _UsuariosRolesScreenState extends State<UsuariosRolesScreen> {
  final _busqueda = TextEditingController();
  final _servicio = UsuarioService();

  List<UsuarioApp> _usuarios = [];
  bool _cargando = true;
  String? _error;

  static const _filtrosRol = ['Todos', 'General', 'Compras', 'Asesor', 'Planta'];
  static const _filtrosEstado = ['Todos', 'Activos', 'Inactivos', 'Pendientes'];
  int _rol = 0;
  int _estado = 0;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _mensaje(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _servicio.listar();
      final miId = supabase.auth.currentUser?.id;
      if (!mounted) return;
      setState(() {
        _usuarios = datos
            .map((d) => UsuarioApp(
          idUsuario: d['id_usuario'] as int,
          nombre: d['nombre'] as String,
          correo: d['correo'] as String,
          rol: rolEtiqueta(d['rol'] as String),
          activo: d['activo'] as bool,
          pendiente: d['pendiente'] as bool,
          esYo: d['id_auth'] == miId,
        ))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<UsuarioApp> get _visibles {
    final q = _busqueda.text.trim().toLowerCase();
    return _usuarios.where((u) {
      if (_rol > 0 && u.rol != kRoles[_rol - 1]) return false;
      if (_estado == 1 && !(u.activo && !u.pendiente)) return false;
      if (_estado == 2 && u.activo) return false;
      if (_estado == 3 && !u.pendiente) return false;
      if (q.isNotEmpty &&
          !u.nombre.toLowerCase().contains(q) &&
          !u.correo.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _nuevo() async {
    final creado = await Navigator.pushNamed(context, '/usuario-nuevo');
    if (creado == true) _cargar();
  }

  Future<void> _editar(UsuarioApp u) async {
    if (u.esYo) {
      _mensaje('No puedes cambiar tu propio rol');
      return;
    }
    final r = await showDialog<(String, bool)>(
      context: context,
      builder: (_) => _CambiarRolDialog(u),
    );
    if (r == null) return;
    try {
      await _servicio.actualizar(u.idUsuario,
          rolBd: kRolesBd[r.$1], activo: r.$2);
      await _cargar();
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _visibles;
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Rol: Gerente General',
            title: 'Usuarios y Roles',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                    hint: 'Buscar por nombre o correo', controller: _busqueda),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < _filtrosRol.length; i++)
                    PillChip(
                        label: _filtrosRol[i],
                        selected: _rol == i,
                        onTap: () => setState(() => _rol = i)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < _filtrosEstado.length; i++)
                    PillChip(
                        label: _filtrosEstado[i],
                        selected: _estado == i,
                        onTap: () => setState(() => _estado = i)),
                ]),
                const SizedBox(height: 12),
                const Text('Toca un usuario para cambiar su rol.',
                    style: TextStyle(color: AppColors.gris, fontSize: 12)),
                const SizedBox(height: 10),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null) ...[
                  EmptyStateCard(
                      title: 'No se pudieron cargar los usuarios',
                      message: _error!),
                  TextButton(
                      onPressed: _cargar, child: const Text('Reintentar')),
                ] else if (lista.isEmpty)
                  const EmptyStateCard(
                      title: 'Sin resultados',
                      message: 'No hay usuarios con esos filtros.')
                else
                  for (final u in lista)
                    _UsuarioTile(u, onTap: () => _editar(u)),
                const SizedBox(height: 12),
                const Text(
                    'No puedes cambiar tu propio rol. Los demás usuarios aparecerán aquí cuando los registres.',
                    style: TextStyle(color: AppColors.gris, fontSize: 12)),
                const SizedBox(height: 14),
                PrimaryButton(
                    text: '+ Registrar nuevo usuario', onPressed: _nuevo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  final UsuarioApp u;
  final VoidCallback onTap;
  const _UsuarioTile(this.u, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                      color: AppColors.azulClaro, shape: BoxShape.circle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.nombre,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('${u.correo}${u.esYo ? ' · Tú' : ''}',
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _Etiqueta(u.rol, AppColors.azul, AppColors.azulClaro),
                        if (u.pendiente)
                          const _Etiqueta('Pendiente', AppColors.naranja,
                              AppColors.naranjaClaro),
                        if (!u.activo)
                          const _Etiqueta(
                              'Inactivo', AppColors.rojo, AppColors.rojoClaro),
                      ]),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gris),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;
  const _Etiqueta(this.texto, this.color, this.fondo);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
        color: fondo, borderRadius: BorderRadius.circular(20)),
    child: Text(texto,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

/// Pantalla 18b: modal "Cambiar rol".
class _CambiarRolDialog extends StatefulWidget {
  final UsuarioApp u;
  const _CambiarRolDialog(this.u);

  @override
  State<_CambiarRolDialog> createState() => _CambiarRolDialogState();
}

class _CambiarRolDialogState extends State<_CambiarRolDialog> {
  late String _rol = widget.u.rol;
  late bool _activo = widget.u.activo;

  Future<void> _reenviar() async {
    try {
      await UsuarioService().reenviarInvitacion(widget.u.idUsuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitación reenviada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Widget _opcion(String r) {
    final sel = _rol == r;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _rol = r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: sel ? AppColors.azulPalido : AppColors.blanco,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.azul : AppColors.borde),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: sel ? AppColors.azul : AppColors.borde, width: 2),
                ),
                child: sel
                    ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.azul, shape: BoxShape.circle),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(r,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const nota = TextStyle(color: AppColors.gris, fontSize: 12, height: 1.4);

    return Dialog(
      backgroundColor: AppColors.blanco,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cambiar rol',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Text(widget.u.nombre,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(widget.u.correo,
                style: const TextStyle(color: AppColors.gris, fontSize: 12)),
            const SizedBox(height: 12),
            for (final r in kRoles) _opcion(r),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borde),
              ),
              child: Row(
                children: [
                  const Expanded(
                      child: Text('Usuario activo',
                          style: TextStyle(fontSize: 15))),
                  Switch(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    thumbColor: const WidgetStatePropertyAll(AppColors.blanco),
                    trackColor: WidgetStateProperty.resolveWith((s) =>
                    s.contains(WidgetState.selected)
                        ? AppColors.azul
                        : AppColors.borde),
                    trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                // Solo mientras el usuario no haya activado su cuenta.
                onPressed: widget.u.pendiente ? _reenviar : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.azul,
                  disabledForegroundColor: AppColors.deshabilitado,
                  side: BorderSide(
                      color: widget.u.pendiente
                          ? AppColors.azul
                          : AppColors.borde),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('Reenviar invitación'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
                'Solo disponible mientras el usuario no haya activado su cuenta.',
                style: nota),
            const SizedBox(height: 8),
            const Text(
                'El nuevo rol se aplica la próxima vez que el usuario abra la app.',
                style: nota),
            const SizedBox(height: 8),
            const Text('No puedes cambiar tu propio rol.', style: nota),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grisClaro,
                        foregroundColor: AppColors.texto,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, (_rol, _activo)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azul,
                        foregroundColor: AppColors.blanco,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}