import 'package:intertrack_app/models/cliente.dart';
import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`

class ClienteService {
  /// activo: true = solo activos, false = solo inactivos, null = todos
  Future<List<Cliente>> listar({bool? activo}) async {
    var consulta = supabase.from('cliente').select();
    if (activo != null) consulta = consulta.eq('activo', activo);
    final datos = await consulta.order('nombre');
    return datos.map<Cliente>((j) => Cliente.fromJson(j)).toList();
  }

  Future<void> crear(String nombre, {String? contacto}) async {
    await supabase.from('cliente').insert({
      'nombre': nombre.trim(),
      'contacto': _limpiar(contacto),
    });
  }

  Future<void> actualizar(int idCliente,
      {String? nombre, String? contacto, bool? activo}) async {
    final cambios = <String, dynamic>{
      if (nombre != null) 'nombre': nombre.trim(),
      if (contacto != null) 'contacto': _limpiar(contacto),
      if (activo != null) 'activo': activo,
    };
    if (cambios.isEmpty) return;
    await supabase.from('cliente').update(cambios).eq('id_cliente', idCliente);
  }

  /// Texto vacío = sin contacto (se guarda como nulo)
  String? _limpiar(String? texto) {
    final t = texto?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}