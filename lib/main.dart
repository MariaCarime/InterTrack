import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intertrack_app/theme.dart';
import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/secure_local_storage.dart';

import 'package:intertrack_app/screens/login_screen.dart';
import 'package:intertrack_app/screens/dashboard_screen.dart';
import 'package:intertrack_app/screens/registrar_pedido_screen.dart';
import 'package:intertrack_app/screens/seguimiento_pedido_screen.dart';
import 'package:intertrack_app/screens/aprobacion_planta_screen.dart';
import 'package:intertrack_app/screens/armado_camion_screen.dart';
import 'package:intertrack_app/screens/gestion_stock_screen.dart';
import 'package:intertrack_app/screens/fleteras_screen.dart';
import 'package:intertrack_app/screens/reportes_screen.dart';
import 'package:intertrack_app/screens/recuperar_contrasena_screen.dart';
import 'package:intertrack_app/screens/documento_trip_screen.dart';
import 'package:intertrack_app/screens/panel_general_screen.dart';
import 'package:intertrack_app/screens/vista_asesor_screen.dart';
import 'package:intertrack_app/screens/usuarios_roles_screen.dart';
import 'package:intertrack_app/screens/registrar_usuario_screen.dart';
import 'package:intertrack_app/screens/importar_catalogo_screen.dart';
import 'package:intertrack_app/screens/clientes_screen.dart';
import 'package:intertrack_app/screens/crear_contrasena_screen.dart';
import 'package:intertrack_app/screens/importar_vista_previa_screen.dart';
import 'package:intertrack_app/screens/confirmacion_pedido_screen.dart';
import 'package:intertrack_app/screens/sucursales_screen.dart';
import 'package:intertrack_app/screens/historial_screen.dart';

import 'package:intertrack_app/models/usuario_service.dart';
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qmrviohoksbknkaztsas.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtcnZpb2hva3Nia25rYXp0c2FzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzNTIyMTksImV4cCI6MjEwNzkyODIxOX0.FBSG1Fh-7DSqajU7ecAdydL3bZHp9ypjH5a1Qn_20wo',
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );

  // Enlaces del correo: invitación o recuperar contraseña
  supabase.auth.onAuthStateChange.listen((datos) async {
    if (datos.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/nueva-contrasena', (_) => false);
    } else if (datos.event == AuthChangeEvent.signedIn) {
      try {
        if (await UsuarioService().cuentaPendiente()) {
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/activar', (_) => false);
        }
      } catch (_) {}
    }
  });

  // Auto-login: si hay sesión guardada, entra directo a la pantalla de su rol
  String rutaInicial = '/login';
  try {
    final usuario = await AuthService().obtenerUsuarioActual();
    if (usuario != null) rutaInicial = usuario.rol.rutaInicial;
  } catch (_) {
    // Sin internet o error: pide iniciar sesión
  }

  runApp(InterTrackApp(rutaInicial: rutaInicial));
}

class InterTrackApp extends StatelessWidget {
  final String rutaInicial;
  const InterTrackApp({super.key, required this.rutaInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    navigatorKey: navigatorKey,
    title: 'InterTrack',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: rutaInicial,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/registrar': (_) => const RegistrarPedidoScreen(),
        '/seguimiento': (ctx) => SeguimientoPedidoScreen(
            idPedido: ModalRoute.of(ctx)?.settings.arguments as int?),
        '/confirmacion': (_) => const ConfirmacionPedidoScreen(),
        '/planta': (_) => const AprobacionPlantaScreen(),
        '/camiones': (_) => const ArmadoCamionScreen(),
        '/stock': (_) => const GestionStockScreen(),
        '/fleteras': (_) => const FleterasScreen(),
        '/reportes': (_) => const ReportesScreen(),
        '/recuperar': (_) => const RecuperarContrasenaScreen(),
        '/documento': (_) => const DocumentoTripScreen(),
        '/general': (_) => const PanelGeneralScreen(),
        '/asesor': (_) => const VistaAsesorScreen(),
        '/usuarios': (_) => const UsuariosRolesScreen(),
        '/usuario-nuevo': (_) => const RegistrarUsuarioScreen(),
        '/importar': (_) => const ImportarCatalogoScreen(),
        '/clientes': (_) => const ClientesScreen(),
        '/activar': (_) => const CrearContrasenaScreen(),
        '/sucursales': (_) => const SucursalesScreen(),
        '/historial': (_) => const HistorialScreen(),
        '/nueva-contrasena': (_) => const CrearContrasenaScreen(
          titulo: 'Crea una nueva contraseña',
          subtitulo:
          'Elige una contraseña segura. La usarás la próxima vez que inicies sesión.',
          textoBoton: 'Actualizar contraseña',
          mensajeExito: 'Contraseña actualizada. Inicia sesión.',
          conCancelar: true,
        ),
        '/importar-vista-previa': (_) => const ImportarVistaPreviaScreen(),
      },
    );
  }
}
