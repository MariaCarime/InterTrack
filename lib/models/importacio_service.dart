import 'package:intertrack_app/models/auth_service.dart';

class ImportacionService {
  /// Devuelve {nuevos, actualizados, existencias}
  Future<Map<String, dynamic>> importar(List<Map<String, dynamic>> filas) async {
    final r = await supabase.rpc('importar_catalogo', params: {'p_filas': filas});
    return Map<String, dynamic>.from(r as Map);
  }
}