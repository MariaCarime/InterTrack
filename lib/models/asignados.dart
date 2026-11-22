import 'dart:typed_data';
import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`
import 'package:intertrack_app/models/importacion.dart';

/// Columnas del archivo diario de Planta y los nombres con que pueden venir.
/// Los encabezados se comparan sin acentos, sin mayúsculas y con "_" por espacio.
const Map<String, List<String>> _alias = {
  'numero_orden': ['numero_orden', 'numero_de_orden', 'no_orden', 'n_orden', 'orden'],
  'orden_compra': ['orden_compra', 'orden_de_compra', 'oc'],
  'codigo_articulo': ['codigo_articulo', 'articulo', 'codigo', 'material', 'codigo_material'],
  'descripcion': ['descripcion', 'descripcion_articulo'],
  'tono': ['tono', 'lote', 'color'],
  'cantidad_asignada': ['cantidad_asignada', 'cant_asignada', 'cantidad', 'asignado'],
  'planta_origen': ['planta_origen', 'planta_de_origen', 'planta', 'origen'],
  'peso': ['peso', 'peso_total', 'peso_kg'],
};
const List<String> _obligatorias = ['codigo_articulo', 'cantidad_asignada'];

class ResultadoAsignados {
  final String archivo;
  final int filasLeidas;
  final List<Map<String, dynamic>> filasValidas;
  final List<ErrorFila> errores;
  final List<String> columnasSinUsar; // encabezados que no se reconocieron

  const ResultadoAsignados({
    required this.archivo,
    this.filasLeidas = 0,
    this.filasValidas = const [],
    this.errores = const [],
    this.columnasSinUsar = const [],
  });

  int get validas => filasValidas.length;
  double get totalCantidad => filasValidas.fold<double>(
      0, (s, f) => s + (f['cantidad_asignada'] as num).toDouble());
}

Map<String, int> _mapearColumnas(List<String> fila) {
  final mapa = <String, int>{};
  for (var j = 0; j < fila.length; j++) {
    final n = normalizarEncabezado(fila[j]);
    if (n.isEmpty) continue;
    for (final e in _alias.entries) {
      if (!mapa.containsKey(e.key) && e.value.contains(n)) mapa[e.key] = j;
    }
  }
  return mapa;
}

/// "1,200.50" -> 1200.5   "12,5" -> 12.5   "1200" -> 1200
double? _numero(String s) {
  var t = s.trim().replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return null;
  if (RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(t)) {
    t = t.replaceAll(',', '');
  } else {
    t = t.replaceAll(',', '.');
  }
  return double.tryParse(t);
}

ResultadoAsignados validarAsignados(String nombre, Uint8List bytes) {
  List<List<String>> tabla;
  try {
    tabla = leerTablaArchivo(nombre, bytes);
  } catch (_) {
    return ResultadoAsignados(archivo: nombre, errores: const [
      ErrorFila(1, 'No se pudo leer el archivo. Revisa que sea un .xlsx o .csv válido'),
    ]);
  }

  // Los archivos del ERP pueden traer títulos arriba: se busca la fila de encabezados.
  var filaEnc = -1;
  var col = <String, int>{};
  for (var i = 0; i < tabla.length && i < 15; i++) {
    final m = _mapearColumnas(tabla[i]);
    if (_obligatorias.every(m.containsKey)) {
      filaEnc = i;
      col = m;
      break;
    }
  }
  if (filaEnc < 0) {
    return ResultadoAsignados(archivo: nombre, errores: const [
      ErrorFila(1,
          'No encontré las columnas de artículo y de cantidad asignada en las primeras filas'),
    ]);
  }

  final usadas = col.values.toSet();
  final sinUsar = <String>[
    for (var j = 0; j < tabla[filaEnc].length; j++)
      if (!usadas.contains(j) && tabla[filaEnc][j].trim().isNotEmpty)
        tabla[filaEnc][j].trim()
  ];

  String celda(List<String> fila, String c) {
    final i = col[c];
    return (i == null || i >= fila.length) ? '' : fila[i].trim();
  }

  final validas = <Map<String, dynamic>>[];
  final errores = <ErrorFila>[];
  var leidas = 0;

  for (var i = filaEnc + 1; i < tabla.length; i++) {
    final fila = tabla[i];
    if (!fila.any((c) => c.trim().isNotEmpty)) continue;
    leidas++;

    final errs = <String>[];
    final codigo = celda(fila, 'codigo_articulo');
    final cantidad = _numero(celda(fila, 'cantidad_asignada'));
    final pesoTxt = celda(fila, 'peso');
    final peso = _numero(pesoTxt);

    if (codigo.isEmpty) errs.add('Falta el artículo');
    if (cantidad == null || cantidad < 0) {
      errs.add('La cantidad asignada debe ser un número mayor o igual a 0');
    }
    if (pesoTxt.isNotEmpty && (peso == null || peso < 0)) {
      errs.add('El peso debe ser un número mayor o igual a 0');
    }

    if (errs.isNotEmpty) {
      errores.add(ErrorFila(i + 1, errs.join('; ')));
      continue;
    }

    String? opc(String c) {
      final v = celda(fila, c);
      return v.isEmpty ? null : v;
    }

    validas.add({
      'numero_orden': opc('numero_orden'),
      'orden_compra': opc('orden_compra'),
      'codigo_articulo': codigo,
      'descripcion': opc('descripcion'),
      'tono': opc('tono'),
      'cantidad_asignada': cantidad,
      'planta_origen': opc('planta_origen'),
      'peso': peso,
    });
  }

  return ResultadoAsignados(
    archivo: nombre,
    filasLeidas: leidas,
    filasValidas: validas,
    errores: errores,
    columnasSinUsar: sinUsar,
  );
}

class CargaAsignados {
  final int idCarga;
  final String? archivo;
  final int filas;
  final DateTime importadoEn;

  const CargaAsignados({
    required this.idCarga,
    required this.archivo,
    required this.filas,
    required this.importadoEn,
  });

  factory CargaAsignados.fromJson(Map<String, dynamic> j) => CargaAsignados(
    idCarga: j['id_carga'] as int,
    archivo: j['archivo'] as String?,
    filas: j['filas'] as int,
    importadoEn: DateTime.parse(j['importado_en'] as String).toLocal(),
  );
}

class AsignadoPlanta {
  final String? numeroOrden;
  final String? ordenCompra;
  final String codigoArticulo;
  final String? descripcion;
  final String? tono;
  final double cantidad;
  final String? plantaOrigen;
  final double? peso;

  const AsignadoPlanta({
    required this.numeroOrden,
    required this.ordenCompra,
    required this.codigoArticulo,
    required this.descripcion,
    required this.tono,
    required this.cantidad,
    required this.plantaOrigen,
    required this.peso,
  });

  factory AsignadoPlanta.fromJson(Map<String, dynamic> j) => AsignadoPlanta(
    numeroOrden: j['numero_orden'] as String?,
    ordenCompra: j['orden_compra'] as String?,
    codigoArticulo: j['codigo_articulo'] as String,
    descripcion: j['descripcion'] as String?,
    tono: j['tono'] as String?,
    cantidad: (j['cantidad_asignada'] as num).toDouble(),
    plantaOrigen: j['planta_origen'] as String?,
    peso: (j['peso'] as num?)?.toDouble(),
  );
}

class AsignadosService {
  Future<int> importar(String archivo, List<Map<String, dynamic>> filas) async {
    final r = await supabase.rpc('importar_asignados',
        params: {'p_archivo': archivo, 'p_filas': filas});
    return (r as Map)['filas'] as int;
  }

  /// La carga más reciente de la sucursal es la vigente.
  Future<CargaAsignados?> ultimaCarga(int idSucursal) async {
    final datos = await supabase
        .from('carga_asignados')
        .select('id_carga, archivo, filas, importado_en')
        .eq('id_sucursal', idSucursal)
        .order('id_carga', ascending: false)
        .limit(1);
    return datos.isEmpty ? null : CargaAsignados.fromJson(datos.first);
  }

  /// Trae todas las filas de la carga (el servidor entrega 1,000 por consulta).
  Future<List<AsignadoPlanta>> lineas(int idCarga) async {
    final todas = <AsignadoPlanta>[];
    var desde = 0;
    while (true) {
      final datos = await supabase
          .from('asignado_planta')
          .select()
          .eq('id_carga', idCarga)
          .order('codigo_articulo')
          .order('id_asignado')
          .range(desde, desde + 999);
      todas.addAll(datos.map<AsignadoPlanta>((j) => AsignadoPlanta.fromJson(j)));
      if (datos.length < 1000) break;
      desde += 1000;
    }
    return todas;
  }
}