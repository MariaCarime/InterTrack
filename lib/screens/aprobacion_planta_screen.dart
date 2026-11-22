import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/solicitud_service.dart';

class AprobacionPlantaScreen extends StatefulWidget {
  const AprobacionPlantaScreen({super.key});

  @override
  State<AprobacionPlantaScreen> createState() => _AprobacionPlantaScreenState();
}

class _AprobacionPlantaScreenState extends State<AprobacionPlantaScreen> {
  final _servicio = SolicitudService();
  List<SolicitudPlanta> _solicitudes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _servicio.pendientes();
      if (!mounted) return;
      setState(() => _solicitudes = datos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _aprobar(SolicitudPlanta s) async {
    try {
      await _servicio.aprobar(s.idOrden);
      await _cargar();
      _aviso('Solicitud aprobada');
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  Future<void> _rechazar(SolicitudPlanta s) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _RechazoDialog(),
    );
    if (motivo == null) return;
    try {
      await _servicio.rechazar(s.idOrden, motivo);
      await _cargar();
      _aviso('Solicitud rechazada');
    } catch (e) {
      _aviso(mensajeDeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BlueHeader(
            subtitle: 'Rol: Planta',
            title: 'Solicitudes Pendientes',
            trailing: CerrarSesionLink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Código, cantidad y fecha únicamente',
                      style: TextStyle(color: AppColors.gris, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null) ...[
                    EmptyStateCard(
                        title: 'No se pudieron cargar las solicitudes',
                        message: _error!),
                    TextButton(
                        onPressed: _cargar, child: const Text('Reintentar')),
                  ] else if (_solicitudes.isEmpty)
                    const EmptyStateCard(
                      title: 'No hay solicitudes pendientes',
                      message:
                      'Las solicitudes de asignación aparecerán aquí para que las apruebes o rechaces.',
                    )
                  else
                    for (final s in _solicitudes)
                      _SolicitudCard(
                        solicitud: s,
                        onAprobar: () => _aprobar(s),
                        onRechazar: () => _rechazar(s),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final SolicitudPlanta solicitud;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _SolicitudCard({
    required this.solicitud,
    required this.onAprobar,
    required this.onRechazar,
  });

  String _fecha(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in solicitud.lineas)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${l.codigo}  ·  ${l.cantidad} cajas',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 2),
          Text('Fecha: ${_fecha(solicitud.fecha)}',
              style: const TextStyle(color: AppColors.gris, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              _Accion(
                  texto: 'Aprobar',
                  fondo: AppColors.verde,
                  color: AppColors.blanco,
                  onTap: onAprobar),
              const SizedBox(width: 10),
              _Accion(
                  texto: 'Rechazar',
                  fondo: AppColors.rojoClaro,
                  color: AppColors.rojo,
                  onTap: onRechazar),
            ],
          ),
        ],
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color color;
  final VoidCallback onTap;

  const _Accion({
    required this.texto,
    required this.fondo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: Text(texto),
      ),
    );
  }
}

/// Pantalla 05c: modal "Rechazar solicitud" (el motivo es obligatorio).
class _RechazoDialog extends StatefulWidget {
  const _RechazoDialog();

  @override
  State<_RechazoDialog> createState() => _RechazoDialogState();
}

class _RechazoDialogState extends State<_RechazoDialog> {
  final _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _rechazar() {
    final m = _motivo.text.trim();
    if (m.isEmpty) {
      setState(() => _error = 'Escribe el motivo del rechazo');
      return;
    }
    Navigator.pop(context, m);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.blanco,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rechazar solicitud',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Motivo del rechazo',
                hint: 'Escribe el motivo del rechazo',
                controller: _motivo),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!,
                  style: const TextStyle(color: AppColors.rojo, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            const Text(
                'El pedido pasará a En Pausa y el Gerente de Compras verá el motivo.',
                style: TextStyle(
                    color: AppColors.gris, fontSize: 12, height: 1.4)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grisClaro,
                        foregroundColor: AppColors.texto,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _rechazar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rojoClaro,
                        foregroundColor: AppColors.rojo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}