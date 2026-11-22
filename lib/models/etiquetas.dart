/// Convierte una lista en un mapa etiqueta -> elemento, con etiquetas únicas.
/// Si dos elementos tienen el mismo nombre se distinguen con [detalle] (por
/// ejemplo el contacto del cliente) y, si aún chocan, con un número.
/// Así el selector devuelve siempre el elemento exacto y no el primero que
/// coincide por nombre (I-01).
Map<String, T> etiquetasUnicas<T>(
    List<T> items,
    String Function(T) nombre, [
      String Function(T)? detalle,
    ]) {
  final repetidos = <String, int>{};
  for (final i in items) {
    repetidos.update(nombre(i), (n) => n + 1, ifAbsent: () => 1);
  }

  final resultado = <String, T>{};
  for (final i in items) {
    var etiqueta = nombre(i);
    if (repetidos[etiqueta]! > 1) {
      final extra = detalle?.call(i).trim() ?? '';
      if (extra.isNotEmpty) etiqueta = '$etiqueta · $extra';
    }
    final base = etiqueta;
    var n = 2;
    while (resultado.containsKey(etiqueta)) {
      etiqueta = '$base ($n)';
      n++;
    }
    resultado[etiqueta] = i;
  }
  return resultado;
}