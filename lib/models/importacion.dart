import 'dart:convert';
import 'dart:typed_data';
import 'package:excel_community/excel_community.dart';

const List<String> kColumnasCatalogo = [
  'codigo_articulo',
  'descripcion',
  'peso_caja',
  'cajas_por_parrilla',
  'unidad_medida',
  'punto_reorden',
  'stock_ideal',
  'bodega',
  'disponible',
  'asignado',
  'remesa',
  'en_produccion',
];
const List<String> _obligatorias = ['codigo_articulo', 'descripcion', 'peso_caja'];

class ErrorFila {
  final int fila;
  final String mensaje;
  const ErrorFila(this.fila, this.mensaje);
}

/// Resultado de leer y validar el archivo (aún no se guarda nada en la base).
class ResultadoValidacion {
  final String archivo;
  final int filasLeidas;
  final List<Map<String, dynamic>> filasValidas;
  final List<ErrorFila> errores;

  const ResultadoValidacion({
    this.archivo = 'Nombre del archivo.xlsx',
    this.filasLeidas = 0,
    this.filasValidas = const [],
    this.errores = const [],
  });

  int get validas => filasValidas.length;
  int get conError => errores.length;
}

ResultadoValidacion validarArchivo(String nombre, Uint8List bytes) {
  List<List<String>> tabla;
  try {
    tabla = _leerTabla(nombre, bytes);
  } catch (_) {
    return ResultadoValidacion(archivo: nombre, errores: const [
      ErrorFila(1, 'No se pudo leer el archivo. Revisa que sea un .xlsx o .csv válido'),
    ]);
  }
  if (tabla.isEmpty) {
    return ResultadoValidacion(
        archivo: nombre, errores: const [ErrorFila(1, 'El archivo está vacío')]);
  }

  final encabezados = tabla.first.map(_normalizar).toList();
  final datos = <int>[];
  for (var i = 1; i < tabla.length; i++) {
    if (tabla[i].any((c) => c.trim().isNotEmpty)) datos.add(i);
  }

  final faltan = _obligatorias.where((c) => !encabezados.contains(c)).toList();
  if (faltan.isNotEmpty) {
    return ResultadoValidacion(
      archivo: nombre,
      filasLeidas: datos.length,
      errores: [for (final c in faltan) ErrorFila(1, 'Falta la columna obligatoria "$c"')],
    );
  }

  String celda(List<String> fila, String col) {
    final i = encabezados.indexOf(col);
    return (i < 0 || i >= fila.length) ? '' : fila[i].trim();
  }

  num? numero(String s) => s.isEmpty ? null : num.tryParse(s.replaceAll(',', '.'));
  int? entero(String s) {
    final n = numero(s);
    if (n == null || n != n.roundToDouble()) return null;
    return n.toInt();
  }

  final validas = <Map<String, dynamic>>[];
  final errores = <ErrorFila>[];

  for (final i in datos) {
    final fila = tabla[i];
    final errs = <String>[];

    final codigo = celda(fila, 'codigo_articulo');
    final desc = celda(fila, 'descripcion');
    final peso = numero(celda(fila, 'peso_caja'));
    if (codigo.isEmpty) errs.add('Falta codigo_articulo');
    if (desc.isEmpty) errs.add('Falta descripcion');
    if (peso == null || peso <= 0) errs.add('peso_caja debe ser un número mayor que 0');

    int? opcionalEntero(String col, {required int minimo}) {
      final s = celda(fila, col);
      if (s.isEmpty) return null;
      final n = entero(s);
      if (n == null || n < minimo) {
        errs.add('$col debe ser un entero ${minimo == 0 ? 'mayor o igual a 0' : 'mayor que 0'}');
        return null;
      }
      return n;
    }

    final cpp = opcionalEntero('cajas_por_parrilla', minimo: 1);
    final reorden = opcionalEntero('punto_reorden', minimo: 0);
    final ideal = opcionalEntero('stock_ideal', minimo: 0);
    final unidad = celda(fila, 'unidad_medida');
    final bodega = celda(fila, 'bodega');
    final disp = opcionalEntero('disponible', minimo: 0);
    final asig = opcionalEntero('asignado', minimo: 0);
    final remesa = opcionalEntero('remesa', minimo: 0);
    final prod = opcionalEntero('en_produccion', minimo: 0);

    final traeNumeros = ['disponible', 'asignado', 'remesa', 'en_produccion']
        .any((c) => celda(fila, c).isNotEmpty);
    if (bodega.isEmpty && traeNumeros) errs.add('Hay existencias pero falta la bodega');

    if (errs.isEmpty) {
      validas.add({
        'codigo_articulo': codigo,
        'descripcion': desc,
        'peso_caja': peso!,
        if (cpp != null) 'cajas_por_parrilla': cpp,
        if (unidad.isNotEmpty) 'unidad_medida': unidad,
        if (reorden != null) 'punto_reorden': reorden,
        if (ideal != null) 'stock_ideal': ideal,
        if (bodega.isNotEmpty) 'bodega': bodega,
        if (disp != null) 'disponible': disp,
        if (asig != null) 'asignado': asig,
        if (remesa != null) 'remesa': remesa,
        if (prod != null) 'en_produccion': prod,
      });
    } else {
      errores.add(ErrorFila(i + 1, errs.join('; ')));
    }
  }

  return ResultadoValidacion(
    archivo: nombre,
    filasLeidas: datos.length,
    filasValidas: validas,
    errores: errores,
  );
}

/// Plantilla .xlsx con solo los encabezados.
Uint8List construirPlantillaCatalogo() {
  final libro = Excel.createExcel();
  final hoja = libro['Catalogo'];
  hoja.appendRow(kColumnasCatalogo.map<CellValue?>((c) => TextCellValue(c)).toList());
  libro.delete('Sheet1');
  libro.setDefaultSheet('Catalogo');
  return Uint8List.fromList(libro.encode()!);
}

/// Reporte de filas con error, en CSV (se abre en Excel con acentos).
Uint8List reporteErroresCsv(ResultadoValidacion r) {
  final sb = StringBuffer('fila,motivo\n');
  for (final e in r.errores) {
    sb.writeln('${e.fila},"${e.mensaje.replaceAll('"', '""')}"');
  }
  return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(sb.toString())]);
}

// ---------------------------------------------------------------------------

String _normalizar(String s) {
  var t = s.trim().toLowerCase();
  const de = 'áéíóúüñ';
  const a = 'aeiouun';
  for (var i = 0; i < de.length; i++) {
    t = t.replaceAll(de[i], a[i]);
  }
  return t.replaceAll(RegExp(r'[\s\-]+'), '_');
}

List<List<String>> _leerTabla(String nombre, Uint8List bytes) {
  final ext = nombre.toLowerCase().split('.').last;
  if (ext == 'xlsx') {
    final libro = Excel.decodeBytes(bytes);
    if (libro.tables.isEmpty) return [];
    final hoja = libro.tables[libro.tables.keys.first]!;
    return hoja.rows.map((fila) => fila.map((c) => _texto(c?.value)).toList()).toList();
  }
  String texto;
  try {
    texto = utf8.decode(bytes);
  } on FormatException {
    texto = latin1.decode(bytes); // CSV guardado desde Excel en español
  }
  return _leerCsv(texto);
}

String _texto(CellValue? v) {
  if (v == null) return '';
  if (v is IntCellValue) return v.value.toString();
  if (v is DoubleCellValue) {
    final d = v.value;
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }
  if (v is BoolCellValue) return v.value ? 'true' : 'false';
  if (v is TextCellValue) {
    final dynamic interno = v.value;
    if (interno is String) return interno;
    try {
      final t = interno.text;
      if (t is String) return t;
    } catch (_) {}
    return interno.toString();
  }
  return v.toString();
}

List<List<String>> _leerCsv(String texto) {
  if (texto.startsWith('\uFEFF')) texto = texto.substring(1);
  final primera = texto.split('\n').first;
  final sep = ';'.allMatches(primera).length > ','.allMatches(primera).length ? ';' : ',';

  final filas = <List<String>>[];
  var fila = <String>[];
  var campo = StringBuffer();
  var entreComillas = false;

  for (var i = 0; i < texto.length; i++) {
    final c = texto[i];
    if (entreComillas) {
      if (c == '"') {
        if (i + 1 < texto.length && texto[i + 1] == '"') {
          campo.write('"');
          i++;
        } else {
          entreComillas = false;
        }
      } else {
        campo.write(c);
      }
    } else if (c == '"') {
      entreComillas = true;
    } else if (c == sep) {
      fila.add(campo.toString());
      campo = StringBuffer();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < texto.length && texto[i + 1] == '\n') i++;
      fila.add(campo.toString());
      campo = StringBuffer();
      filas.add(fila);
      fila = <String>[];
    } else {
      campo.write(c);
    }
  }
  if (campo.isNotEmpty || fila.isNotEmpty) {
    fila.add(campo.toString());
    filas.add(fila);
  }
  return filas;
}


// Funciones públicas para otros importadores (asignados de Planta).
List<List<String>> leerTablaArchivo(String nombre, Uint8List bytes) =>
    _leerTabla(nombre, bytes);
String normalizarEncabezado(String s) => _normalizar(s);