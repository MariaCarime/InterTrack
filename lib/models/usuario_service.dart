import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intertrack_app/models/sucursal.dart';
import 'package:intertrack_app/models/auth_service.dart';

/// Nombre que se ve en pantalla -> valor guardado en la base
const Map<String, String> kRolesBd = {
  'Gerente General': 'gerente_general',
  'Gerente de Compras': 'gerente_compras',
  'Asesor': 'asesor',
  'Planta': 'planta',
};

String rolEtiqueta(String valorBd) =>
    kRolesBd.entries.firstWhere((e) => e.value == valorBd).key;

class UsuarioService {
  Future<List<Map<String, dynamic>>> listar() async {
    final datos = await supabase.rpc('listar_usuarios');
    return List<Map<String, dynamic>>.from(datos as List);
  }

  Future<List<Sucursal>> sucursales() async {
    final datos = await supabase.from('sucursal').select().order('nombre');
    return datos.map<Sucursal>((j) => Sucursal.fromJson(j)).toList();
  }

  Future<void> invitar({
    required String nombre,
    required String correo,
    required String rolBd,
    required int idSucursal,
  }) =>
      _llamar({
        'accion': 'invitar',
        'nombre': nombre,
        'correo': correo,
        'rol': rolBd,
        'id_sucursal': idSucursal,
      });

  Future<void> reenviarInvitacion(int idUsuario) =>
      _llamar({'accion': 'reenviar', 'id_usuario': idUsuario});

  Future<void> actualizar(int idUsuario, {String? rolBd, bool? activo}) =>
      _llamar({
        'accion': 'actualizar',
        'id_usuario': idUsuario,
        if (rolBd != null) 'rol': rolBd,
        if (activo != null) 'activo': activo,
      });

  /// ¿La persona conectada aún no ha creado su contraseña?
  Future<bool> cuentaPendiente() async {
    final r = await supabase.rpc('cuenta_pendiente');
    return r == true;
  }

  Future<void> crearContrasena(String contrasena) async {
    await supabase.auth.updateUser(UserAttributes(password: contrasena));
  }

  Future<void> _llamar(Map<String, dynamic> cuerpo) async {
    try {
      await supabase.functions.invoke('dynamic-task', body: cuerpo);
    } on FunctionException catch (e) {
      final d = e.details;
      final texto = d is Map ? (d['error'] ?? d['message'])?.toString() : null;
      throw Exception(_traducir(
          texto ?? 'No se pudo completar la acción (código ${e.status})'));
    }
  }

  String _traducir(String m) {
    final t = m.toLowerCase();
    if (t.contains('already') && t.contains('registered')) {
      return 'Ese correo ya está registrado.';
    }
    if (t.contains('rate limit')) {
      return 'Se alcanzó el límite de correos por hora. Intenta más tarde.';
    }
    if (t.contains('not authorized')) {
      return 'Ese correo aún no puede recibir invitaciones: agrégalo al equipo de Supabase o configura el correo propio.';
    }
    return m;
  }
}