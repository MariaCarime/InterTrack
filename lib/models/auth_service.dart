import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intertrack_app/models/usuario.dart';
import 'package:flutter/material.dart';

final supabase = Supabase.instance.client;

class AuthService {
  // 1. Agrega esta variable estática al principio de la clase
  static RolUsuario? rolActual;

  Future<Usuario> iniciarSesion(String correo, String contrasena) async {
    await supabase.auth.signInWithPassword(email: correo, password: contrasena);
    final usuario = await obtenerUsuarioActual();
    if (usuario == null) {
      await supabase.auth.signOut();
      throw Exception('Tu cuenta está desactivada o no tiene acceso a la app.');
    }
    return usuario;
  }

  Future<Usuario?> obtenerUsuarioActual() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;
    final data = await supabase
        .from('usuario')
        .select()
        .eq('id_auth', authUser.id)
        .maybeSingle();
    if (data == null) return null;
    final usuario = Usuario.fromJson(data);

    // 2. Guarda el rol justo antes de regresar el usuario
    rolActual = usuario.activo ? usuario.rol : null;

    return usuario.activo ? usuario : null;
  }

  Future<void> cerrarSesion() => supabase.auth.signOut();
}

Future<void> cerrarSesionYSalir(BuildContext context) async {
  AuthService.rolActual = null; // Limpia el rol al salir
  await AuthService().cerrarSesion();
  if (!context.mounted) return;
  Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
}