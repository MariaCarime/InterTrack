class Fletera {
  final int idFletera;
  final String nombre;
  final String? contacto;
  final String tipo; // 'propia' | 'externa' (como se guarda en la base)
  final bool activo;

  const Fletera({
    required this.idFletera,
    required this.nombre,
    this.contacto,
    required this.tipo,
    required this.activo,
  });

  factory Fletera.fromJson(Map<String, dynamic> json) => Fletera(
    idFletera: json['id_fletera'] as int,
    nombre: json['nombre'] as String,
    contacto: json['contacto'] as String?,
    tipo: json['tipo'] as String,
    activo: json['activo'] as bool,
  );

  String get tipoEtiqueta => tipo == 'propia' ? 'Propia' : 'Externa';
}