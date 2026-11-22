import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/models/pedido_service.dart';

/// Etiquetas que se ven en pantalla (mismo orden que kEstadosBd)
const List<String> kEstadosPedido = [
  'Pendiente',
  'Esperando Aprobación de Planta',
  'En Pausa',
  'Aprobado / Listo para Cargar',
  'En Ruta / Trip Creado',
  'En Recepción / Conciliación',
  'Entregado',
];
const String kEstadoCancelado = 'Cancelado (estado alternativo)';

/// Colores de la etiqueta de estado (también los usa el dashboard)
({Color texto, Color fondo}) colorEstadoPedido(String estadoBd) {
  if (estadoBd == kEstadoCanceladoBd) {
    return (texto: AppColors.rojo, fondo: AppColors.rojoClaro);
  }
  switch (kEstadosBd.indexOf(estadoBd)) {
    case 0:
    case 1:
    case 2:
      return (texto: AppColors.naranja, fondo: AppColors.naranjaClaro);
    case 6:
      return (texto: AppColors.verde, fondo: AppColors.azulPalido);
    default:
      return (texto: AppColors.azul, fondo: AppColors.azulClaro);
  }
}

class SeguimientoPedidoScreen extends StatefulWidget {
  final int? idPedido;
  final bool soloLectura; // el Asesor no ve botones de acción

  const SeguimientoPedidoScreen(
      {super.key, this.idPedido, this.soloLectura = false});

  @override
  State<SeguimientoPedidoScreen> createState() =>
      _SeguimientoPedidoScreenState();
}

class _SeguimientoPedidoScreenState extends State<SeguimientoPedidoScreen> {
  final _servicio = PedidoService();
  Pedido? _pedido;
  List<CambioPedido> _historial = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _mensaje(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _cargar() async {
    final id = widget.idPedido;
    if (id == null) {
      setState(() {
        _cargando = false;
        _error = 'No se indicó qué pedido mostrar.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pedido = await _servicio.obtener(id);
      final historial = await _servicio.historial(id);
      if (!mounted) return;
      setState(() {
        _pedido = pedido;
        _historial = historial;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _verificar() async {
    final p = _pedido!;
    try {
      final lineas = await _servicio.verificarAsignacion(p.idPedido);
      if (!mounted) return;
      final continuar = await showDialog<bool>(
        context: context,
        builder: (_) => _VerificacionDialog(lineas: lineas),
      );
      if (continuar != true) return;
      final resultado = await _servicio.aplicarVerificacion(p.idPedido);
      await _cargar();
      _mensaje(switch (resultado) {
        'solicitud' => 'Solicitud enviada a Planta',
        'en_pausa' => 'El pedido quedó En Pausa',
        _ => 'Pedido aprobado y listo para cargar',
      });
    } catch (e) {
      _mensaje(mensajeDeError(e));
    }
  }

  Future<void> _cancelar() async {
    final p = _pedido!;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text(
            '¿Seguro que quieres cancelar el pedido ${p.folio}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cancelar',
                  style: TextStyle(color: AppColors.rojo))),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _servicio.cancelar(p.idPedido);
      await _cargar();
      _mensaje('Pedido cancelado');
    } catch (e) {
      _mensaje(mensajeDeError(e));
    }
  }

  String _fecha(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = _pedido;
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Seguimiento',
            title: p == null ? 'Pedido' : 'Pedido ${p.folio}',
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null || p == null
                ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EmptyStateCard(
                    title: 'No se pudo cargar el pedido',
                    message: _error ?? 'Intenta de nuevo.'),
                TextButton(
                    onPressed: _cargar,
                    child: const Text('Reintentar')),
              ],
            )
                : _contenido(p),
          ),
        ],
      ),
    );
  }

  Widget _contenido(Pedido p) {
    final estadoActual = p.indiceEstado;
    final cancelado = p.estado == kEstadoCanceladoBd;
    final badge = colorEstadoPedido(p.estado);
    final etiqueta = cancelado
        ? 'Cancelado'
        : (estadoActual >= 0 ? kEstadosPedido[estadoActual] : p.estado);

    // Qué acciones tienen sentido según el estado
    final puedeVerificar = estadoActual == 0 || estadoActual == 2;
    final puedeCancelar = estadoActual >= 0 && estadoActual <= 3;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Ficha del pedido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente: ${p.cliente}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('Asesor: ${p.asesor}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                _dato('Documento ERP: ${p.documentoErp ?? '—'}'),
                _dato('Sucursal: ${p.sucursal}'),
                _dato('Productos:'),
                for (final l in p.lineas)
                  _dato(
                      '• ${l.codigoArticulo} — ${l.cantidad} cajas${l.lote != null ? ' (lote ${l.lote})' : ''}'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: badge.fondo,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(etiqueta,
                          style: TextStyle(
                              color: badge.texto,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (p.urgente)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.naranjaClaro,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Urgente',
                            style: TextStyle(
                                color: AppColors.naranja,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ciclo de vida
          const Text('Ciclo de vida del pedido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (var i = 0; i < kEstadosPedido.length; i++)
            _PasoEstado(
              texto: kEstadosPedido[i],
              color: (!cancelado && i <= estadoActual)
                  ? AppColors.azul
                  : AppColors.borde,
              activo: !cancelado && i == estadoActual,
              alcanzado: !cancelado && i <= estadoActual,
            ),
          _PasoEstado(
            texto: kEstadoCancelado,
            color: AppColors.rojo,
            activo: cancelado,
            alcanzado: cancelado,
          ),
          const SizedBox(height: 24),

          // Historial
          const Text('Historial de cambios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _historial.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Text(
                      '${_historial[i].descripcion ?? 'Cambio de estado'} → ${_historial[i].estadoNuevo}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                      '${_fecha(_historial[i].fechaHora)} · ${_historial[i].usuario}',
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 12)),
                ],
              ],
            ),
          ),

          // Acciones
          if (!widget.soloLectura) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PrimaryButton(
                    text: 'Verificar asignación',
                    onPressed: puedeVerificar ? _verificar : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: puedeCancelar ? _cancelar : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rojoClaro,
                        foregroundColor: AppColors.rojo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancelar pedido'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dato(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(texto,
        style: const TextStyle(color: AppColors.gris, fontSize: 13)),
  );
}

class _PasoEstado extends StatelessWidget {
  final String texto;
  final Color color;
  final bool activo;
  final bool alcanzado;

  const _PasoEstado({
    required this.texto,
    required this.color,
    required this.activo,
    required this.alcanzado,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                    color: alcanzado ? AppColors.texto : AppColors.gris)),
          ),
        ],
      ),
    );
  }
}

/// Resultado de revisar cada material del pedido contra lo que tiene Planta.
class _VerificacionDialog extends StatelessWidget {
  final List<VerificacionLinea> lineas;
  const _VerificacionDialog({required this.lineas});

  ({String texto, Color color}) _etiqueta(String estado) {
    switch (estado) {
      case 'ok':
        return (texto: 'Asignado y disponible', color: AppColors.verde);
      case 'en_pausa':
        return (texto: 'Asignado, falta material en Planta', color: AppColors.naranja);
      default:
        return (texto: 'Sin asignar', color: AppColors.rojo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sinAsignar = lineas.any((l) => l.estado == 'sin_asignar');
    final enPausa = lineas.any((l) => l.estado == 'en_pausa');
    final consecuencia = lineas.isEmpty
        ? 'Este pedido no tiene productos.'
        : sinAsignar
        ? 'Se enviará una solicitud a Planta por lo que falta asignar y el pedido pasará a Esperando Aprobación de Planta.'
        : enPausa
        ? 'El material está asignado, pero aún no está en Planta. El pedido pasará a En Pausa.'
        : 'Todo está asignado y disponible. El pedido pasará a Aprobado / Listo para Cargar.';

    return AlertDialog(
      title: const Text('Verificación de asignación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lineas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.codigo,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                        'Pedido: ${l.cantidad} · Asignado: ${l.asignado} · En Planta: ${l.disponible}',
                        style: const TextStyle(
                            color: AppColors.gris, fontSize: 12)),
                    Text(_etiqueta(l.estado).texto,
                        style: TextStyle(
                            color: _etiqueta(l.estado).color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(consecuencia,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cerrar')),
        TextButton(
            onPressed:
            lineas.isEmpty ? null : () => Navigator.pop(context, true),
            child: const Text('Continuar')),
      ],
    );
  }
}