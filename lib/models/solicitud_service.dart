import 'package:intertrack_app/models/auth_service.dart';

class LineaSolicitud {
  final String codigo;
  final int cantidad;
  const LineaSolicitud(this.codigo, this.cantidad);
}

class SolicitudPlanta {
  final int idOrden;
  final DateTime fecha;
  final List<LineaSolicitud> lineas;

  const SolicitudPlanta(
      {required this.idOrden, required this.fecha, required this.lineas});

  factory SolicitudPlanta.fromJson(Map<String, dynamic> j) => SolicitudPlanta(
    idOrden: j['id_orden'] as int,
    fecha: DateTime.parse(j['fecha_solicitud'] as String).toLocal(),
    lineas: ((j['detalle_orden_compra'] as List?) ?? [])
        .map((d) => LineaSolicitud(
      d['codigo_articulo'] as String,
      (d['cantidad_minima'] ?? d['cantidad']) as int,
    ))
        .toList(),
  );
}

class SolicitudService {
  Future<List<SolicitudPlanta>> pendientes() async {
    final datos = await supabase
        .from('orden_compra')
        .select(
        'id_orden, fecha_solicitud, detalle_orden_compra(codigo_articulo, cantidad, cantidad_minima)')
        .eq('estado_aprobacion', 'pendiente')
        .order('fecha_solicitud');
    return datos
        .map<SolicitudPlanta>((j) => SolicitudPlanta.fromJson(j))
        .toList();
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