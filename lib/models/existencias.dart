import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`

class ExistenciaMaterial {
  final String codigo;
  final String descripcion;
  final String bodega;
  final int disponible; // existencia en Planta, en cajas
  final int asignado; // lo que Planta ya asignó a la sucursal
  final int remesa;
  final int enProduccion;
  final int puntoReorden;
  final int stockIdeal;

  const ExistenciaMaterial({
    required this.codigo,
    required this.descripcion,
    required this.bodega,
    required this.disponible,
    required this.asignado,
    required this.remesa,
    required this.enProduccion,
    required this.puntoReorden,
    required this.stockIdeal,
  });

  factory ExistenciaMaterial.fromJson(Map<String, dynamic> j) => ExistenciaMaterial(
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    bodega: j['bodega'] as String,
    disponible: j['disponible'] as int,
    asignado: j['asignado'] as int,
    remesa: j['remesa'] as int,
    enProduccion: j['en_produccion'] as int,
    puntoReorden: j['punto_reorden'] as int,
    stockIdeal: j['stock_ideal'] as int,
  );

  bool get bajoReorden => puntoReorden > 0 && disponible < puntoReorden;
}

class ExistenciasService {
  Future<List<ExistenciaMaterial>> todas() async {
    final todas = <ExistenciaMaterial>[];
    var desde = 0;
    while (true) {
      final datos = await supabase.rpc('existencias_todas').range(desde, desde + 999);
      final lista = (datos as List).cast<Map<String, dynamic>>();
      todas.addAll(lista.map(ExistenciaMaterial.fromJson));
      if (lista.length < 1000) break;
      desde += 1000;
    }
    return todas;
  }
}