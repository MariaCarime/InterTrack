class Sucursal {
  final int idSucursal;
  final String nombre;
  final String zona;
  final String sigla; // vacía mientras no se capture; la factura es SIGLA-NÚMERO

  const Sucursal({
    required this.idSucursal,
    required this.nombre,
    required this.zona,
    this.sigla = '',
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
    idSucursal: json['id_sucursal'] as int,
    nombre: json['nombre'] as String,
    zona: json['zona'] as String,
    sigla: (json['sigla'] as String?) ?? '',
  );
}