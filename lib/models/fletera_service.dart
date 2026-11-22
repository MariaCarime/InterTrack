import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/fletera.dart';

class FleteraService {
  /// activo: true = solo activas, false = solo inactivas, null = todas
  Future<List<Fletera>> listar({bool? activo}) async {
    var consulta = supabase.from('fletera').select();
    if (activo != null) consulta = consulta.eq('activo', activo);
    final datos = await consulta.order('nombre');
    return datos.map<Fletera>((j) => Fletera.fromJson(j)).toList();
  }

  Future<void> crear(String nombre, String contacto, String tipoEtiqueta) async {
    await supabase.from('fletera').insert({
      'nombre': nombre.trim(),
      'contacto': _limpiar(contacto),
      'tipo': tipoEtiqueta.toLowerCase(),
    });
  }

  Future<void> actualizar(
      int idFletera, {
        required String nombre,
        required String contacto,
        required String tipoEtiqueta,
        required bool activo,
      }) async {
    await supabase.from('fletera').update({
      'nombre': nombre.trim(),
      'contacto': _limpiar(contacto),
      'tipo': tipoEtiqueta.toLowerCase(),
      'activo': activo,
    }).eq('id_fletera', idFletera);
  }

  String? _limpiar(String texto) {
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }
}