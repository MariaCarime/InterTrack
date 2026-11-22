enum RolUsuario {
  gerenteGeneral('gerente_general'),
  gerenteCompras('gerente_compras'),
  asesor('asesor'),
  planta('planta');

  final String valorBd;
  const RolUsuario(this.valorBd);

  static RolUsuario desdeBd(String valor) =>
      RolUsuario.values.firstWhere((r) => r.valorBd == valor);

  String get rutaInicial {
    switch (this) {
      case RolUsuario.gerenteCompras:
        return '/dashboard';
      case RolUsuario.asesor:
        return '/asesor';
      case RolUsuario.gerenteGeneral:
        return '/general';
      case RolUsuario.planta:
        return '/planta';
    }
  }
}

class Usuario {
  final int idUsuario;
  final String idAuth;
  final String nombre;
  final String correo;
  final RolUsuario rol;
  final bool activo;
  final int idSucursal;

  const Usuario({
    required this.idUsuario,
    required this.idAuth,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activo,
    required this.idSucursal,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    idUsuario: json['id_usuario'] as int,
    idAuth: json['id_auth'] as String,
    nombre: json['nombre'] as String,
    correo: json['correo'] as String,
    rol: RolUsuario.desdeBd(json['rol'] as String),
    activo: json['activo'] as bool,
    idSucursal: json['id_sucursal'] as int,
  );
}