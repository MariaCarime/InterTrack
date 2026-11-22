import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/consulta_service.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/solicitud_service.dart';

/// Comentarios de una solicitud a Planta (reemplazan al chat).
/// Los usan Compras, el General y Planta.
class ComentariosSolicitud extends StatefulWidget {
  final int idOrden;
  const ComentariosSolicitud({super.key, required this.idOrden});

  @override
  State<ComentariosSolicitud> createState() => _ComentariosSolicitudState();
}

class _ComentariosSolicitudState extends State<ComentariosSolicitud> {
  final _servicio = SolicitudService();
  final _texto = TextEditingController();
  List<ComentarioSolicitud> _comentarios = [];
  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final datos = await _servicio.comentarios(widget.idOrden);
      if (mounted) setState(() => _comentarios = datos);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _enviar() async {
    final t = _texto.text.trim();
    if (t.isEmpty) return;
    setState(() => _enviando = true);
    try {
      await _servicio.comentar(widget.idOrden, t);
      _texto.clear();
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comentarios',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
                height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.rojo, fontSize: 12))
        else if (_comentarios.isEmpty)
            const Text('Sin comentarios todavía.',
                style: TextStyle(color: AppColors.gris, fontSize: 12))
          else
            for (final c in _comentarios)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.fondo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c.autor} · ${c.etiquetaRol} · ${formatoFechaHora(c.creadoEn)}',
                        style: const TextStyle(color: AppColors.gris, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(c.texto, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _texto,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              onPressed: (_enviando || _texto.text.trim().isEmpty) ? null : _enviar,
              icon: const Icon(Icons.send, color: AppColors.azul),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sección "Solicitud a Planta" de un pedido: qué material se pidió, en qué
/// estado está y los comentarios. No muestra nada si el pedido no tiene solicitud.
class SolicitudesPedido extends StatefulWidget {
  final int idPedido;
  const SolicitudesPedido({super.key, required this.idPedido});

  @override
  State<SolicitudesPedido> createState() => _SolicitudesPedidoState();
}

class _SolicitudesPedidoState extends State<SolicitudesPedido> {
  final _servicio = SolicitudService();
  List<SolicitudDePedido> _solicitudes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await _servicio.delPedido(widget.idPedido);
      if (mounted) setState(() => _solicitudes = datos);
    } catch (_) {
      // Sin permiso o sin conexión: la sección simplemente no aparece.
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Color _color(String estado) => switch (estado) {
    'aprobado' => AppColors.verde,
    'rechazado' => AppColors.rojo,
    _ => AppColors.naranja,
  };

  @override
  Widget build(BuildContext context) {
    if (_cargando || _solicitudes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Solicitud a Planta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (final s in _solicitudes)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    s.fecha == null
                        ? s.etiquetaEstado
                        : '${s.etiquetaEstado} · ${formatoFecha(s.fecha!)}',
                    style: TextStyle(
                        color: _color(s.estado),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (final l in s.lineas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                        '${l.codigo}${(l.descripcion ?? '').isEmpty ? '' : ' · ${l.descripcion}'}  —  ${l.cantidad} cajas',
                        style: const TextStyle(fontSize: 13)),
                  ),
                if ((s.motivoRechazo ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Motivo del rechazo: ${s.motivoRechazo}',
                      style: const TextStyle(color: AppColors.rojo, fontSize: 12)),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.borde),
                ),
                ComentariosSolicitud(idOrden: s.idOrden),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}