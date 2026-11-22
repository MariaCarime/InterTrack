class MaterialStock {
  final String codigo;
  final String descripcion;
  final int disponible; // existencia en Planta, en cajas
  final int asignado; // lo que Planta ya asignó
  final int puntoReorden;
  final int stockIdeal;
  final int? _cajasPorParrilla;
  final double pesoCaja; // kg
  final bool pendiente; // ya hay una solicitud de reposición esperando a Planta

  const MaterialStock({
    required this.codigo,
    required this.descripcion,
    required this.disponible,
    required this.asignado,
    required this.puntoReorden,
    required this.stockIdeal,
    required int? cajasPorParrilla,
    required this.pesoCaja,
    required this.pendiente,
  }) : _cajasPorParrilla = cajasPorParrilla;

  factory MaterialStock.fromJson(Map<String, dynamic> j) => MaterialStock(
    codigo: j['o_codigo'] as String,
    descripcion: j['o_descripcion'] as String,
    disponible: j['o_disponible'] as int,
    asignado: j['o_asignado'] as int,
    puntoReorden: j['o_punto_reorden'] as int,
    stockIdeal: j['o_stock_ideal'] as int,
    cajasPorParrilla: j['o_cajas_por_parrilla'] as int?,
    pesoCaja: (j['o_peso_caja'] as num).toDouble(),
    pendiente: j['o_pendiente'] as bool,
  );

  bool get tieneParrilla => _cajasPorParrilla != null;
  int get cajasPorParrilla => _cajasPorParrilla ?? 1;

  int get faltante => stockIdeal > disponible ? stockIdeal - disponible : 0;

  /// El faltante se redondea hacia arriba a parrillas completas.
  int get parrillasAReponer => (faltante / cajasPorParrilla).ceil();
  int get cajasAReponer => parrillasAReponer * cajasPorParrilla;
  double get toneladasAReponer => cajasAReponer * pesoCaja / 1000;

  /// Si Planta ya asignó material suficiente, la orden se genera directo.
  bool get asignadoCubre => asignado >= cajasAReponer;
}