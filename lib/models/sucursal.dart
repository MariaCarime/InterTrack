class Sucursal {
  final int idSucursal;
  final String nombre;
  final String zona;

  const Sucursal({
    required this.idSucursal,
    required this.nombre,
    required this.zona,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
    idSucursal: json['id_sucursal'] as int,
    nombre: json['nombre'] as String,
    zona: json['zona'] as String,
  );

  // Sin id: lo genera la base
  Map<String, dynamic> toJson() => {'nombre': nombre, 'zona': zona};
}