class Articulo {
  final String codigoArticulo;
  final String descripcion;

  const Articulo({required this.codigoArticulo, required this.descripcion});

  factory Articulo.fromJson(Map<String, dynamic> json) => Articulo(
    codigoArticulo: json['codigo_articulo'] as String,
    descripcion: json['descripcion'] as String,
  );

  String get etiqueta => '$codigoArticulo — $descripcion';
}