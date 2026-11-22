import 'dart:typed_data';
import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`
import 'package:intertrack_app/models/importacion.dart';

/// Excel del stock físico del CEDIS. Columnas:
///   codigo_articulo (obligatoria) · cantidad (obligatoria, en cajas)
/// Se acepta "disponible" como nombre de la cantidad. Las demás columnas se ignoran.
const Map<String, List<String>> _alias = {
  'codigo_articulo': ['codigo_articulo', 'codigo', 'articulo'],
  'cantidad': ['cantidad', 'disponible'],
};

class ResultadoStock {
  final String archivo;
  final int filasLeidas;
  final List<Map<String, dynamic>> filasValidas;
  final List<ErrorFila> errores;
  final List<String> columnasIgnoradas;
  final List<String> advertencias;
  final List<String> faltantes; // artículos del catálogo que no vienen: quedarán en 0

  const ResultadoStock({
    required this.archivo,
    this.filasLeidas = 0,
    this.filasValidas = const [],
    this.errores = const [],
    this.columnasIgnoradas = const [],
    this.advertencias = const [],
    this.faltantes = const [],
  });

  int get validas => filasValidas.length;
  int get totalCajas =>
      filasValidas.fold<int>(0, (s, f) => s + (f['cantidad'] as int));

  /// Una carga es una foto completa: con errores no se importa, porque un
  /// artículo omitido pasaría a contarse como sin stock.
  bool get sePuedeImportar => errores.isEmpty && filasValidas.isNotEmpty;
}

Map<String, int> _mapear(List<String> fila) {
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

/// Máximo de un integer de PostgreSQL; el servidor acepta exactamente el mismo rango.
const int _maxCajas = 2147483647;

/// Entero en cajas entre 0 y 2147483647. "30" y "30.0" valen; "12.5", "" y "-3" no.
int? _cajas(String s) {
  final t = s.trim().replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return null;
  final d = double.tryParse(t.replaceAll(',', '.'));
  if (d == null || d < 0 || d != d.roundToDouble() || d > _maxCajas) return null;
  return d.toInt();
}

ResultadoStock validarStockCedis(
    String nombre,
    Uint8List bytes,
    Set<String> codigosCatalogo, {
      int? filasCargaAnterior,
    }) {
  List<List<String>> tabla;
  try {
    tabla = leerTablaArchivo(nombre, bytes);
  } catch (_) {
    return ResultadoStock(archivo: nombre, errores: const [
      ErrorFila(1, 'No se pudo leer el archivo. Revisa que sea un .xlsx o .csv válido'),
    ]);
  }

  var filaEnc = -1;
  var col = <String, int>{};
  for (var i = 0; i < tabla.length && i < 15; i++) {
    final m = _mapear(tabla[i]);
    if (m.containsKey('codigo_articulo') && m.containsKey('cantidad')) {
      filaEnc = i;
      col = m;
      break;
    }
  }
  if (filaEnc < 0) {
    return ResultadoStock(archivo: nombre, errores: const [
      ErrorFila(1,
          'No encontré las columnas codigo_articulo y cantidad en las primeras filas'),
    ]);
  }

  final usadas = col.values.toSet();
  final ignoradas = <String>[
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
  final vistos = <String>{};
  var leidas = 0;

  for (var i = filaEnc + 1; i < tabla.length; i++) {
    final fila = tabla[i];
    if (!fila.any((c) => c.trim().isNotEmpty)) continue;
    leidas++;

    final codigo = celda(fila, 'codigo_articulo');
    final cantidad = _cajas(celda(fila, 'cantidad'));
    final errs = <String>[];

    if (codigo.isEmpty) {
      errs.add('Falta el artículo');
    } else if (!codigosCatalogo.contains(codigo)) {
      errs.add('El artículo $codigo no está en el catálogo');
    } else if (!vistos.add(codigo)) {
      errs.add('El artículo $codigo está repetido en el archivo');
    }
    if (cantidad == null) {
      errs.add('La cantidad debe ser un número entero de cajas entre 0 y 2147483647; no puede ir vacía');
    }

    if (errs.isNotEmpty) {
      errores.add(ErrorFila(i + 1, errs.join('; ')));
      continue;
    }
    validas.add({'codigo_articulo': codigo, 'cantidad': cantidad});
  }

  final avisos = <String>[];
  if (filasCargaAnterior != null &&
      filasCargaAnterior > 0 &&
      validas.length < filasCargaAnterior * 0.5) {
    avisos.add(
        'Esta carga trae ${validas.length} artículos y la anterior traía $filasCargaAnterior. '
            'Los artículos que no vengan se considerarán sin stock. Revisa que el archivo esté completo.');
  }

  // Es una foto completa: lo que no venga en el archivo queda con 0 cajas.
  final enArchivo = validas.map((f) => f['codigo_articulo'] as String).toSet();
  final faltantes = (codigosCatalogo.difference(enArchivo)).toList()..sort();

  return ResultadoStock(
    archivo: nombre,
    filasLeidas: leidas,
    filasValidas: validas,
    errores: errores,
    columnasIgnoradas: ignoradas,
    advertencias: avisos,
    faltantes: errores.isEmpty ? faltantes : const [],
  );
}

class ItemStockCedis {
  final String codigo;
  final String descripcion;
  final int cantidad;
  final int puntoReorden;
  final int stockIdeal;
  final bool bajoReorden;
  final bool enCarga; // false = no venía en el archivo (cuenta como 0)

  const ItemStockCedis({
    required this.codigo,
    required this.descripcion,
    required this.cantidad,
    required this.puntoReorden,
    required this.stockIdeal,
    required this.bajoReorden,
    required this.enCarga,
  });

  factory ItemStockCedis.fromJson(Map<String, dynamic> j) => ItemStockCedis(
    codigo: j['o_codigo'] as String,
    descripcion: j['o_descripcion'] as String,
    cantidad: j['o_cantidad'] as int,
    puntoReorden: j['o_punto_reorden'] as int,
    stockIdeal: j['o_stock_ideal'] as int,
    bajoReorden: j['o_bajo_reorden'] as bool,
    enCarga: j['o_en_carga'] as bool,
  );
}

class CargaStock {
  final int idCarga;
  final String? archivo;
  final int filas;
  final int faltantes; // artículos que quedaron en 0 por no venir en el archivo
  final DateTime importadoEn;

  const CargaStock({
    required this.idCarga,
    required this.archivo,
    required this.filas,
    required this.faltantes,
    required this.importadoEn,
  });

  factory CargaStock.fromJson(Map<String, dynamic> j) => CargaStock(
    idCarga: j['id_carga'] as int,
    archivo: j['archivo'] as String?,
    filas: j['filas'] as int,
    faltantes: (j['faltantes'] as int?) ?? 0,
    importadoEn: DateTime.parse(j['importado_en'] as String).toLocal(),
  );
}

class StockCedisService {
  /// Códigos del catálogo, para rechazar artículos que no existen antes de importar.
  Future<Set<String>> codigosCatalogo() async {
    final codigos = <String>{};
    var desde = 0;
    while (true) {
      final datos = await supabase
          .from('material')
          .select('codigo_articulo')
          .order('codigo_articulo')
          .range(desde, desde + 999);
      for (final j in datos) {
        codigos.add(j['codigo_articulo'] as String);
      }
      if (datos.length < 1000) break;
      desde += 1000;
    }
    return codigos;
  }

  /// [confirmaFaltantes] solo debe ser true si el usuario confirmó que el archivo está completo.
  Future<int> importar(String archivo, List<Map<String, dynamic>> filas,
      {bool confirmaFaltantes = false}) async {
    final r = await supabase.rpc('importar_stock', params: {
      'p_archivo': archivo,
      'p_filas': filas,
      'p_confirma_faltantes': confirmaFaltantes,
    });
    return (r as Map)['filas'] as int;
  }

  /// Cargas de la sucursal, la más reciente primero (la primera es la vigente).
  Future<List<CargaStock>> cargas(int idSucursal, {int limite = 10}) async {
    final datos = await supabase
        .from('carga_stock')
        .select('id_carga, archivo, filas, faltantes, importado_en')
        .eq('id_sucursal', idSucursal)
        .order('id_carga', ascending: false)
        .limit(limite);
    return datos.map<CargaStock>((j) => CargaStock.fromJson(j)).toList();
  }

  Future<List<ItemStockCedis>> vigente() async {
    final todos = <ItemStockCedis>[];
    var desde = 0;
    while (true) {
      final datos = await supabase.rpc('stock_cedis_vigente').range(desde, desde + 999);
      final lista = (datos as List).cast<Map<String, dynamic>>();
      todos.addAll(lista.map(ItemStockCedis.fromJson));
      if (lista.length < 1000) break;
      desde += 1000;
    }
    return todos;
  }
}