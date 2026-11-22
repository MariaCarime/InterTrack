import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/models/pedido_service.dart';

String _dos(int n) => n.toString().padLeft(2, '0');

String formatoFecha(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

String formatoFechaHora(DateTime d) =>
    '${formatoFecha(d)} ${_dos(d.hour)}:${_dos(d.minute)}';

/// Un movimiento de la bitácora (historial_pedido). Solo lectura (RNF-009).
class Movimiento {
  final String folio;
  final String usuario;
  final String? estadoAnterior;
  final String estadoNuevo;
  final String descripcion;
  final DateTime fechaHora;

  const Movimiento({
    required this.folio,
    required this.usuario,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.descripcion,
    required this.fechaHora,
  });

  static String _nombre(dynamic v, String campo) =>
      (v is Map ? v[campo] as String? : null) ?? '—';

  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
    folio: _nombre(j['pedido'], 'folio'),
    usuario: _nombre(j['usuario'], 'nombre'),
    estadoAnterior: j['estado_anterior'] as String?,
    estadoNuevo: j['estado_nuevo'] as String,
    descripcion: (j['descripcion'] as String?) ?? '',
    fechaHora: DateTime.parse(j['fecha_hora'] as String).toLocal(),
  );
}

class MetricaSucursal {
  final String sucursal;
  final int pedidos;
  final int urgentes;
  const MetricaSucursal(this.sucursal, this.pedidos, this.urgentes);
}

class MetricasGenerales {
  final int pedidosMes;
  final int urgentes;
  final int rechazos;
  final List<MetricaSucursal> porSucursal;
  const MetricasGenerales({
    required this.pedidosMes,
    required this.urgentes,
    required this.rechazos,
    required this.porSucursal,
  });
}

class ConsultaService {
  /// Últimos movimientos de la bitácora, del más reciente al más antiguo.
  Future<List<Movimiento>> movimientos({int limite = 300}) async {
    final datos = await supabase
        .from('historial_pedido')
        .select('estado_anterior, estado_nuevo, descripcion, fecha_hora, '
        'pedido(folio), usuario(nombre)')
        .order('fecha_hora', ascending: false)
        .limit(limite);
    return datos.map<Movimiento>((j) => Movimiento.fromJson(j)).toList();
  }

  /// Pedidos para búsqueda y reportes (los filtros se aplican en pantalla).
  Future<List<Pedido>> pedidos({int limite = 500}) =>
      PedidoService().listar(limite: limite);

  Future<MetricasGenerales> metricas() async {
    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    final inicio =
        '${inicioMes.year}-${_dos(inicioMes.month)}-${_dos(inicioMes.day)}';

    final pedidos = await supabase
        .from('pedido')
        .select('urgente, estado, sucursal(nombre)')
        .gte('fecha', inicio);

    final rechazadas = await supabase
        .from('orden_compra')
        .select('id_orden')
        .eq('estado_aprobacion', 'rechazado');

    var urgentes = 0;
    final porSucursal = <String, List<int>>{}; // [pedidos, urgentes]
    for (final p in pedidos) {
      final cancelado = p['estado'] == kEstadoCanceladoBd;
      if (cancelado) continue;
      final esUrgente = p['urgente'] == true;
      if (esUrgente) urgentes++;
      final s = p['sucursal'];
      final nombre = (s is Map ? s['nombre'] as String? : null) ?? '—';
      final fila = porSucursal.putIfAbsent(nombre, () => [0, 0]);
      fila[0]++;
      if (esUrgente) fila[1]++;
    }

    final lista = porSucursal.entries
        .map((e) => MetricaSucursal(e.key, e.value[0], e.value[1]))
        .toList()
      ..sort((a, b) => b.pedidos.compareTo(a.pedidos));

    return MetricasGenerales(
      pedidosMes: lista.fold<int>(0, (s, m) => s + m.pedidos),
      urgentes: urgentes,
      rechazos: rechazadas.length,
      porSucursal: lista,
    );
  }
}