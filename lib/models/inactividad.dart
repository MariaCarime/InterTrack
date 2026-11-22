import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intertrack_app/models/auth_service.dart';

/// Cierra la sesión si no hay actividad durante [limite].
/// Se reinicia con cada toque, clic o desplazamiento.
class InactividadGuard extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final Duration limite;

  const InactividadGuard({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.limite = const Duration(minutes: 15),
  });

  @override
  State<InactividadGuard> createState() => _InactividadGuardState();
}

class _InactividadGuardState extends State<InactividadGuard> {
  Timer? _timer;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = supabase.auth.onAuthStateChange.listen((datos) {
      if (datos.session == null) {
        _timer?.cancel();
      } else {
        _reiniciar();
      }
    });
    _reiniciar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  void _reiniciar([PointerEvent? _]) {
    _timer?.cancel();
    if (supabase.auth.currentSession == null) return;
    _timer = Timer(widget.limite, _cerrar);
  }

  Future<void> _cerrar() async {
    if (supabase.auth.currentSession == null) return;
    await AuthService().cerrarSesion();
    final nav = widget.navigatorKey.currentState;
    nav?.pushNamedAndRemoveUntil('/login', (_) => false);
    final ctx = widget.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Tu sesión se cerró por inactividad. Inicia sesión de nuevo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _reiniciar,
      onPointerMove: _reiniciar,
      onPointerSignal: _reiniciar,
      child: widget.child,
    );
  }
}