import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intertrack_app/models/articulo.dart';
import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/cliente.dart';
import 'package:intertrack_app/models/pedido.dart';

const _seleccion = 'id_pedido, folio, documento_erp, fecha, estado, urgente, '
    'id_cliente, id_asesor, '
    'cliente(nombre), asesor:usuario!id_asesor(nombre), sucursal(nombre), '
    'detalle_pedido(codigo_articulo, cantidad, lote, material(descripcion))';

/// Mensaje legible para mostrar al usuario
String mensajeDeError(Object e) {
  if (e is PostgrestException) return e.message;
  return 'Revisa tu conexión e intenta de nuevo.';
}

class PedidoService {
  Future<List<Pedido>> listar({int limite = 10}) async {
    final datos = await supabase
        .from('pedido')
        .select(_seleccion)
        .order('id_pedido', ascending: false)
        .limit(limite);
    return datos.map<Pedido>((j) => Pedido.fromJson(j)).toList();
  }

  Future<Map<String, int>> contarPorEstado() async {
    final datos = await supabase.from('pedido').select('estado');
    final conteo = <String, int>{};
    for (final d in datos) {
      final e = d['estado'] as String;
      conteo[e] = (conteo[e] ?? 0) + 1;
    }
    return conteo;
  }

  Future<Pedido> obtener(int idPedido) async {
    final dato = await supabase
        .from('pedido')
        .select(_seleccion)
        .eq('id_pedido', idPedido)
        .single();
    return Pedido.fromJson(dato);
  }

  Future<List<CambioPedido>> historial(int idPedido) async {
    final datos = await supabase
        .from('historial_pedido')
        .select('estado_anterior, estado_nuevo, descripcion, fecha_hora, usuario(nombre)')
        .eq('id_pedido', idPedido)
        .order('fecha_hora');
    return datos.map<CambioPedido>((j) => CambioPedido.fromJson(j)).toList();
  }

  Future<({int idPedido, String folio})> crear({
    required int idCliente,
    required int idAsesor,
    required String documentoErp,
    required bool urgente,
    required List<({String codigo, int cantidad})> lineas,
  }) async {
    final r = await supabase.rpc('crear_pedido', params: {
      'p_id_cliente': idCliente,
      'p_id_asesor': idAsesor,
      'p_documento_erp': documentoErp,
      'p_urgente': urgente,
      'p_lineas': lineas
          .map((l) => {'codigo_articulo': l.codigo, 'cantidad': l.cantidad})
          .toList(),
    });
    final fila = (r as List).first as Map<String, dynamic>;
    return (idPedido: fila['o_id_pedido'] as int, folio: fila['o_folio'] as String);
  }

  /// Cancela con motivo (queda en el historial). Solo si no hay material en un camión.
  Future<void> cancelar(int idPedido, String motivo) async {
    await supabase.rpc('cancelar_pedido',
        params: {'p_id_pedido': idPedido, 'p_motivo': motivo.trim()});
  }

  /// Edita datos y líneas. Solo en Pendiente o En Pausa y sin material en camión.
  Future<void> editar({
    required int idPedido,
    required int idCliente,
    required int idAsesor,
    required String documentoErp,
    required bool urgente,
    required List<({String codigo, int cantidad})> lineas,
  }) async {
    await supabase.rpc('editar_pedido', params: {
      'p_id_pedido': idPedido,
      'p_id_cliente': idCliente,
      'p_id_asesor': idAsesor,
      'p_documento_erp': documentoErp,
      'p_urgente': urgente,
      'p_lineas': lineas
          .map((l) => {'codigo_articulo': l.codigo, 'cantidad': l.cantidad})
          .toList(),
    });
  }

  /// true si alguna línea del pedido ya está asignada a un camión.
  Future<bool> tieneMaterialEnCamion(int idPedido) async {
    final r = await supabase
        .from('camion_detalle_pedido')
        .select('id_camion, detalle_pedido!inner(id_pedido)')
        .eq('detalle_pedido.id_pedido', idPedido)
        .limit(1);
    return r.isNotEmpty;
  }

  Future<List<VerificacionLinea>> verificarAsignacion(int idPedido) async {
    final r = await supabase
        .rpc('verificar_asignacion', params: {'p_id_pedido': idPedido});
    return (r as List)
        .map((j) => VerificacionLinea.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve 'aprobado', 'en_pausa' o 'solicitud'
  Future<String> aplicarVerificacion(int idPedido) async {
    final r = await supabase
        .rpc('aplicar_verificacion', params: {'p_id_pedido': idPedido});
    return r as String;
  }

  // Opciones para el formulario de registrar pedido
  Future<List<Cliente>> clientesActivos() async {
    final datos = await supabase
        .from('cliente')
        .select()
        .eq('activo', true)
        .order('nombre');
    return datos.map<Cliente>((j) => Cliente.fromJson(j)).toList();
  }

  Future<List<({int id, String nombre})>> asesoresActivos() async {
    final datos = await supabase
        .from('usuario')
        .select('id_usuario, nombre')
        .eq('rol', 'asesor')
        .eq('activo', true)
        .order('nombre');
    return datos
        .map((d) => (id: d['id_usuario'] as int, nombre: d['nombre'] as String))
        .toList();
  }

  Future<List<Articulo>> articulos() async {
    final datos = await supabase
        .from('material')
        .select('codigo_articulo, descripcion')
        .order('codigo_articulo');
    return datos.map<Articulo>((j) => Articulo.fromJson(j)).toList();
  }
}