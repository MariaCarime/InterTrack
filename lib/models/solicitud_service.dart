import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`

class LineaSolicitud {
  final String codigo;
  final int cantidad;
  final String? descripcion;
  const LineaSolicitud(this.codigo, this.cantidad, [this.descripcion]);
}

List<LineaSolicitud> _lineas(dynamic detalle) => ((detalle as List?) ?? [])
    .map((d) => LineaSolicitud(
  d['codigo_articulo'] as String,
  (d['cantidad_minima'] ?? d['cantidad']) as int,
  (d['material'] as Map?)?['descripcion'] as String?,
))
    .toList();

/// Solicitud pendiente que ve Planta.
class SolicitudPlanta {
  final int idOrden;
  final DateTime fecha;
  final List<LineaSolicitud> lineas;

  const SolicitudPlanta(
      {required this.idOrden, required this.fecha, required this.lineas});

  factory SolicitudPlanta.fromJson(Map<String, dynamic> j) => SolicitudPlanta(
    idOrden: j['id_orden'] as int,
    fecha: DateTime.parse(j['fecha_solicitud'] as String).toLocal(),
    lineas: _lineas(j['detalle_orden_compra']),
  );
}

/// Solicitud de un pedido, en cualquier estado (la ven Compras y el General).
class SolicitudDePedido {
  final int idOrden;
  final String estado; // pendiente | aprobado | rechazado
  final DateTime? fecha;
  final String? motivoRechazo;
  final List<LineaSolicitud> lineas;

  const SolicitudDePedido({
    required this.idOrden,
    required this.estado,
    required this.fecha,
    required this.motivoRechazo,
    required this.lineas,
  });

  factory SolicitudDePedido.fromJson(Map<String, dynamic> j) => SolicitudDePedido(
    idOrden: j['id_orden'] as int,
    estado: j['estado_aprobacion'] as String,
    fecha: j['fecha_solicitud'] == null
        ? null
        : DateTime.parse(j['fecha_solicitud'] as String).toLocal(),
    motivoRechazo: j['motivo_rechazo'] as String?,
    lineas: _lineas(j['detalle_orden_compra']),
  );

  String get etiquetaEstado => switch (estado) {
    'pendiente' => 'Pendiente de Planta',
    'aprobado' => 'Aprobada por Planta',
    'rechazado' => 'Rechazada por Planta',
    _ => estado,
  };
}

class ComentarioSolicitud {
  final String autor;
  final String rol;
  final String texto;
  final DateTime creadoEn;

  const ComentarioSolicitud({
    required this.autor,
    required this.rol,
    required this.texto,
    required this.creadoEn,
  });

  factory ComentarioSolicitud.fromJson(Map<String, dynamic> j) =>
      ComentarioSolicitud(
        autor: (j['autor'] as String?) ?? '—',
        rol: (j['rol'] as String?) ?? '',
        texto: j['texto'] as String,
        creadoEn: DateTime.parse(j['creado_en'] as String).toLocal(),
      );

  String get etiquetaRol => switch (rol) {
    'planta' => 'Planta',
    'gerente_compras' => 'Compras',
    'gerente_general' => 'Gerente General',
    _ => rol,
  };
}

const _seleccionDetalle =
    'detalle_orden_compra(codigo_articulo, cantidad, cantidad_minima, material(descripcion))';

class SolicitudService {
  Future<List<SolicitudPlanta>> pendientes() async {
    final datos = await supabase
        .from('orden_compra')
        .select('id_orden, fecha_solicitud, $_seleccionDetalle')
        .eq('estado_aprobacion', 'pendiente')
        .order('fecha_solicitud');
    return datos
        .map<SolicitudPlanta>((j) => SolicitudPlanta.fromJson(j))
        .toList();
  }

  /// Todas las solicitudes de un pedido (la más reciente primero).
  Future<List<SolicitudDePedido>> delPedido(int idPedido) async {
    final datos = await supabase
        .from('orden_compra')
        .select(
        'id_orden, estado_aprobacion, fecha_solicitud, motivo_rechazo, $_seleccionDetalle')
        .eq('id_pedido', idPedido)
        .order('id_orden', ascending: false);
    return datos
        .map<SolicitudDePedido>((j) => SolicitudDePedido.fromJson(j))
        .toList();
  }

  /// Solicitudes de reposición de stock (no ligadas a un pedido).
  Future<List<SolicitudDePedido>> deStock({int limite = 15}) async {
    final datos = await supabase
        .from('orden_compra')
        .select(
        'id_orden, estado_aprobacion, fecha_solicitud, motivo_rechazo, $_seleccionDetalle')
        .eq('tipo', 'stock')
        .order('id_orden', ascending: false)
        .limit(limite);
    return datos
        .map<SolicitudDePedido>((j) => SolicitudDePedido.fromJson(j))
        .toList();
  }

  Future<List<ComentarioSolicitud>> comentarios(int idOrden) async {
    final r = await supabase
        .rpc('comentarios_solicitud', params: {'p_id_orden': idOrden});
    return (r as List)
        .map((j) => ComentarioSolicitud.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> comentar(int idOrden, String texto) async {
    await supabase.rpc('comentar_solicitud',
        params: {'p_id_orden': idOrden, 'p_texto': texto.trim()});
  }

  Future<void> aprobar(int idOrden) async {
    await supabase
        .from('orden_compra')
        .update({'estado_aprobacion': 'aprobado'}).eq('id_orden', idOrden);
  }

  Future<void> rechazar(int idOrden, String motivo) async {
    await supabase.from('orden_compra').update({
      'estado_aprobacion': 'rechazado',
      'motivo_rechazo': motivo,
    }).eq('id_orden', idOrden);
  }
}