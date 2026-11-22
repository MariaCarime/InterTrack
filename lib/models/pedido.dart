/// Estados tal como se guardan en la base, en orden del ciclo de vida
const List<String> kEstadosBd = [
  'Pendiente',
  'Esperando Aprobación de Planta',
  'En Pausa',
  'Aprobado/Listo para Cargar',
  'En Ruta/Trip Creado',
  'En Recepción/Conciliación',
  'Entregado',
];
const String kEstadoCanceladoBd = 'Cancelado';

class LineaPedido {
  final String codigoArticulo;
  final String descripcion;
  final int cantidad;
  final String? lote;

  const LineaPedido({
    required this.codigoArticulo,
    required this.descripcion,
    required this.cantidad,
    this.lote,
  });
}

class Pedido {
  final int idPedido;
  final String folio;
  final String? documentoErp;
  final String fecha;
  final String estado;
  final bool urgente;
  final String cliente;
  final String asesor;
  final String sucursal;
  final List<LineaPedido> lineas;

  const Pedido({
    required this.idPedido,
    required this.folio,
    required this.documentoErp,
    required this.fecha,
    required this.estado,
    required this.urgente,
    required this.cliente,
    required this.asesor,
    required this.sucursal,
    required this.lineas,
  });

  static String _nombre(dynamic v) =>
      (v is Map ? v['nombre'] as String? : null) ?? '—';

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
    idPedido: j['id_pedido'] as int,
    folio: j['folio'] as String,
    documentoErp: j['documento_erp'] as String?,
    fecha: j['fecha'] as String,
    estado: j['estado'] as String,
    urgente: j['urgente'] as bool,
    cliente: _nombre(j['cliente']),
    asesor: _nombre(j['asesor']),
    sucursal: _nombre(j['sucursal']),
    lineas: ((j['detalle_pedido'] as List?) ?? [])
        .map((d) => LineaPedido(
      codigoArticulo: d['codigo_articulo'] as String,
      descripcion:
      ((d['material'] as Map?)?['descripcion'] as String?) ?? '',
      cantidad: d['cantidad'] as int,
      lote: d['lote'] as String?,
    ))
        .toList(),
  );

  /// Posición en el ciclo de vida; -1 si está cancelado
  int get indiceEstado =>
      estado == kEstadoCanceladoBd ? -1 : kEstadosBd.indexOf(estado);
}

class CambioPedido {
  final String? descripcion;
  final String estadoNuevo;
  final DateTime fechaHora;
  final String usuario;

  const CambioPedido({
    required this.descripcion,
    required this.estadoNuevo,
    required this.fechaHora,
    required this.usuario,
  });

  factory CambioPedido.fromJson(Map<String, dynamic> j) => CambioPedido(
    descripcion: j['descripcion'] as String?,
    estadoNuevo: j['estado_nuevo'] as String,
    fechaHora: DateTime.parse(j['fecha_hora'] as String).toLocal(),
    usuario: Pedido._nombre(j['usuario']),
  );
}

class VerificacionLinea {
  final String codigo;
  final String descripcion;
  final int cantidad;
  final int asignado;
  final int disponible;
  final String estado; // 'ok' | 'en_pausa' | 'sin_asignar'

  const VerificacionLinea({
    required this.codigo,
    required this.descripcion,
    required this.cantidad,
    required this.asignado,
    required this.disponible,
    required this.estado,
  });

  factory VerificacionLinea.fromJson(Map<String, dynamic> j) =>
      VerificacionLinea(
        codigo: j['o_codigo'] as String,
        descripcion: j['o_descripcion'] as String,
        cantidad: j['o_cantidad'] as int,
        asignado: j['o_asignado'] as int,
        disponible: j['o_disponible'] as int,
        estado: j['o_estado'] as String,
      );
}