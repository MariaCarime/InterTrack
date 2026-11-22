/// Límite por camión: 35 t menos el margen obligatorio. Nunca llega a este valor.
const double kLimiteToneladas = 34.5;

/// Una línea de un pedido aprobado que todavía tiene cajas por cargar.
class LineaPorCargar {
  final int idDetalle;
  final int idPedido;
  final String folio;
  final String cliente;
  final bool urgente;
  final String codigo;
  final String descripcion;
  final double pesoCaja; // kg
  final int? cajasPorParrilla;
  final int total; // cajas del renglón, redondeadas a parrillas completas
  final int cargado;
  final int restante;

  const LineaPorCargar({
    required this.idDetalle,
    required this.idPedido,
    required this.folio,
    required this.cliente,
    required this.urgente,
    required this.codigo,
    required this.descripcion,
    required this.pesoCaja,
    required this.cajasPorParrilla,
    required this.total,
    required this.cargado,
    required this.restante,
  });

  factory LineaPorCargar.fromJson(Map<String, dynamic> j) => LineaPorCargar(
    idDetalle: j['o_id_detalle'] as int,
    idPedido: j['o_id_pedido'] as int,
    folio: j['o_folio'] as String,
    cliente: j['o_cliente'] as String,
    urgente: j['o_urgente'] as bool,
    codigo: j['o_codigo'] as String,
    descripcion: j['o_descripcion'] as String,
    pesoCaja: (j['o_peso_caja'] as num).toDouble(),
    cajasPorParrilla: j['o_cajas_por_parrilla'] as int?,
    total: j['o_total'] as int,
    cargado: j['o_cargado'] as int,
    restante: j['o_restante'] as int,
  );

  /// toneladas = cajas × peso_caja ÷ 1000
  double toneladas(int cajas) => cajas * pesoCaja / 1000;

  /// Cuántas cajas (en parrillas completas) caben sin llegar al límite (34.5 ton).
  int cajasQueCaben(double toneladasLibres) {
    final unidad = cajasPorParrilla ?? 1;
    final kgPorBloque = unidad * pesoCaja;
    // Se resta un margen mínimo para que el total quede por debajo, no igual.
    final bloquesMax = (((toneladasLibres * 1000) - 0.001) / kgPorBloque).floor();
    final bloquesRestantes = restante ~/ unidad;
    final bloques = bloquesMax < bloquesRestantes ? bloquesMax : bloquesRestantes;
    return bloques <= 0 ? 0 : bloques * unidad;
  }
}

class LineaTripDatos {
  final String folio;
  final String codigo;
  final String descripcion;
  final int cajas;
  final int? parrillas;
  final String? lote;
  final double toneladas;
  final String? facturaPo; // factura del pedido (P.O.)

  const LineaTripDatos({
    required this.folio,
    required this.codigo,
    required this.descripcion,
    required this.cajas,
    required this.parrillas,
    required this.lote,
    required this.toneladas,
    this.facturaPo,
  });
}

/// Todo lo que lleva el documento Trip de un camión.
class DatosTrip {
  final int idCamion;
  final String? origen;
  final String destino;
  final String fletera;
  final double toneladas;
  final String? rutaPdf;
  final double? tarifaTonelada;
  final double? costoFlete;
  final String? numeroTrip;
  final String? placas;
  final String? chofer;
  final String? economico;
  final String? sello;
  final DateTime? fechaRecepcion;
  final List<LineaTripDatos> lineas;

  const DatosTrip({
    required this.idCamion,
    required this.origen,
    required this.destino,
    required this.fletera,
    required this.toneladas,
    required this.rutaPdf,
    this.tarifaTonelada,
    this.costoFlete,
    this.numeroTrip,
    this.placas,
    this.chofer,
    this.economico,
    this.sello,
    this.fechaRecepcion,
    required this.lineas,
  });

  String get nombreArchivo => 'Trip_$idCamion.pdf';

  factory DatosTrip.fromJson(Map<String, dynamic> j) => DatosTrip(
    idCamion: j['id_camion'] as int,
    origen: j['planta_origen'] as String?,
    destino: j['ship_to'] as String,
    fletera: ((j['fletera'] as Map?)?['nombre'] as String?) ?? '-',
    toneladas: (j['toneladas_totales'] as num).toDouble(),
    rutaPdf: j['ruta_pdf'] as String?,
    tarifaTonelada: (j['tarifa_tonelada'] as num?)?.toDouble(),
    costoFlete: (j['costo_flete'] as num?)?.toDouble(),
    numeroTrip: j['numero_trip'] as String?,
    placas: j['placas'] as String?,
    chofer: j['chofer'] as String?,
    economico: j['economico'] as String?,
    sello: j['sello'] as String?,
    fechaRecepcion: j['fecha_recepcion'] == null
        ? null
        : DateTime.parse(j['fecha_recepcion'] as String).toLocal(),
    lineas: ((j['camion_detalle_pedido'] as List?) ?? []).map((c) {
      final dp = c['detalle_pedido'] as Map<String, dynamic>;
      final mat = dp['material'] as Map<String, dynamic>;
      final cajas = c['cantidad_asignada'] as int;
      final cpp = mat['cajas_por_parrilla'] as int?;
      final peso = (mat['peso_caja'] as num).toDouble();
      return LineaTripDatos(
        folio: ((dp['pedido'] as Map?)?['folio'] as String?) ?? '-',
        codigo: dp['codigo_articulo'] as String,
        descripcion: mat['descripcion'] as String,
        cajas: cajas,
        parrillas: cpp == null ? null : cajas ~/ cpp,
        lote: dp['lote'] as String?,
        toneladas: cajas * peso / 1000,
        facturaPo: (dp['pedido'] as Map?)?['documento_erp'] as String?,
      );
    }).toList(),
  );
}

/// Datos mínimos de un camión para listarlo.
class CamionResumen {
  final int idCamion;
  final String fletera;
  final String destino;
  final double toneladas;
  final DateTime? fechaRecepcion;

  const CamionResumen({
    required this.idCamion,
    required this.fletera,
    required this.destino,
    required this.toneladas,
    required this.fechaRecepcion,
  });

  bool get recibido => fechaRecepcion != null;

  factory CamionResumen.fromJson(Map<String, dynamic> j) => CamionResumen(
    idCamion: j['id_camion'] as int,
    fletera: ((j['fletera'] as Map?)?['nombre'] as String?) ?? '—',
    destino: (j['ship_to'] as String?) ?? '',
    toneladas: (j['toneladas_totales'] as num).toDouble(),
    fechaRecepcion: j['fecha_recepcion'] == null
        ? null
        : DateTime.parse(j['fecha_recepcion'] as String).toLocal(),
  );
}