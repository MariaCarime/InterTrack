class Fletera {
  final int idFletera;
  final String nombre;
  final String? contacto;
  final String tipo; // 'propia' | 'externa' (como se guarda en la base)
  final bool activo;
  final double? tarifaTonelada; // MXN por tonelada; null = sin capturar

  const Fletera({
    required this.idFletera,
    required this.nombre,
    this.contacto,
    required this.tipo,
    required this.activo,
    this.tarifaTonelada,
  });

  factory Fletera.fromJson(Map<String, dynamic> json) => Fletera(
    idFletera: json['id_fletera'] as int,
    nombre: json['nombre'] as String,
    contacto: json['contacto'] as String?,
    tipo: json['tipo'] as String,
    activo: json['activo'] as bool,
    tarifaTonelada: (json['tarifa_tonelada'] as num?)?.toDouble(),
  );

  String get tipoEtiqueta => tipo == 'propia' ? 'Propia' : 'Externa';
}