import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/usuario.dart';

/// Solo el Gerente General crea y edita en los catálogos
/// (clientes, fleteras, sucursales). Compras solo los consulta.
bool puedeEditarCatalogos() => AuthService.rolActual == RolUsuario.gerenteGeneral;