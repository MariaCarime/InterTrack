class Cliente {
  final int idCliente;
  final String nombre;
  final String? contacto;
  final bool activo;

  const Cliente({
    required this.idCliente,
    required this.nombre,
    this.contacto,
    required this.activo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    idCliente: json['id_cliente'] as int,
    nombre: json['nombre'] as String,
    contacto: json['contacto'] as String?,
    activo: json['activo'] as bool,
  );
}