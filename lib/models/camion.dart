import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intertrack_app/models/archivos.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/camion.dart';
import 'package:intertrack_app/models/camion_service.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/trip_pdf.dart';
import 'package:intertrack_app/models/consulta_service.dart';

class DocumentoTripScreen extends StatefulWidget {
  final int? idCamion;
  const DocumentoTripScreen({super.key, this.idCamion});

  @override
  State<DocumentoTripScreen> createState() => _DocumentoTripScreenState();
}

class _DocumentoTripScreenState extends State<DocumentoTripScreen> {
  final _servicio = CamionService();
  DatosTrip? _datos;
  bool _cargando = true;
  bool _descargando = false;
  bool _recibiendo = false;
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
    final id = widget.idCamion;
    if (id == null) {
      setState(() => _cargando = false);
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _servicio.datosTrip(id);
      if (!mounted) return;
      setState(() => _datos = datos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _editarEmbarque() async {
    final d = _datos;
    if (d == null) return;
    final trip = TextEditingController(text: d.numeroTrip);
    final placas = TextEditingController(text: d.placas);
    final chofer = TextEditingController(text: d.chofer);
    final economico = TextEditingController(text: d.economico);
    final sello = TextEditingController(text: d.sello);

    InputDecoration campo(String etiqueta) =>
        InputDecoration(labelText: etiqueta, isDense: true);

    final guardar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Datos del embarque'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: trip, decoration: campo('Número de Trip')),
              const SizedBox(height: 10),
              TextField(controller: placas, decoration: campo('Placas')),
              const SizedBox(height: 10),
              TextField(controller: chofer, decoration: campo('Chofer')),
              const SizedBox(height: 10),
              TextField(controller: economico, decoration: campo('Número económico')),
              const SizedBox(height: 10),
              TextField(controller: sello, decoration: campo('Número de sello')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar')),
        ],
      ),
    );

    final valores = (trip.text, placas.text, chofer.text, economico.text, sello.text);
    for (final c in [trip, placas, chofer, economico, sello]) {
      c.dispose();
    }
    if (guardar != true) return;

    try {
      await _servicio.guardarEmbarque(
        d.idCamion,
        numeroTrip: valores.$1,
        placas: valores.$2,
        chofer: valores.$3,
        economico: valores.$4,
        sello: valores.$5,
      );
      // El PDF guardado quedó con los datos anteriores: se vuelve a generar.
      final nuevos = await _servicio.datosTrip(d.idCamion);
      final bytes = await construirTripPdf(nuevos);
      await _servicio.subirPdf(d.idCamion, bytes);
      if (mounted) setState(() => _datos = nuevos);
      _mensaje('Datos del embarque guardados');
    } catch (e) {
      _mensaje(mensajeDeError(e));
    }
  }

  Future<void> _recibir() async {
    final d = _datos;
    if (d == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar recepción'),
        content: Text(
            '¿El camión ${d.idCamion} ya llegó y se recibió? Los pedidos que viajaban completos en él pasarán a Entregado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, recibido')),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() => _recibiendo = true);
    try {
      final n = await _servicio.recibir(d.idCamion);
      await _cargar();
      _mensaje(n == 0
          ? 'Recepción registrada'
          : 'Recepción registrada. $n ${n == 1 ? 'pedido pasó' : 'pedidos pasaron'} a Entregado');
    } catch (e) {
      _mensaje(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _recibiendo = false);
    }
  }

  Future<void> _descargar() async {
    final d = _datos;
    if (d == null) return;
    setState(() => _descargando = true);
    try {
      Uint8List bytes;
      try {
        // Si el PDF ya está guardado en Supabase se usa ese; si no, se genera.
        bytes = d.rutaPdf != null
            ? await _servicio.descargarPdf(d.rutaPdf!)
            : await construirTripPdf(d);
      } catch (_) {
        bytes = await construirTripPdf(d);
      }
      final ruta = await guardarArchivo(d.nombreArchivo, bytes);
      if (ruta != null) _mensaje('PDF guardado');
    } catch (e) {
      _mensaje('No se pudo abrir el PDF: ${mensajeDeError(e)}');
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gris = TextStyle(color: AppColors.gris, fontSize: 13);
    final d = _datos;

    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Vista previa del documento',
            title: d?.nombreArchivo ?? 'Trip_XXXX.pdf',
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EmptyStateCard(
                    title: 'No se pudo cargar el documento',
                    message: _error!),
                TextButton(
                    onPressed: _cargar,
                    child: const Text('Reintentar')),
              ],
            )
                : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TRIP / PREVIO',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text(
                          'Origen: ${d?.origen ?? (d == null ? 'Planta de origen' : 'No indicado')}  →  Destino: ${d?.destino ?? 'CEDIS destino'}',
                          style: gris),
                      const SizedBox(height: 8),
                      Text('Fletera: ${d?.fletera ?? 'Nombre de la fletera'}',
                          style: gris),
                      if (d != null) ...[
                        const SizedBox(height: 8),
                        Text(
                            'Trip: ${d.numeroTrip ?? '-'} · Placas: ${d.placas ?? '-'} · Económico: ${d.economico ?? '-'}\nChofer: ${d.chofer ?? '-'} · Sello: ${d.sello ?? '-'}',
                            style: gris),
                      ],
                      const SizedBox(height: 8),
                      Text(
                          'Peso total: ${(d?.toneladas ?? 0).toStringAsFixed(1)} / 34.5 ton',
                          style: gris),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                            height: 1, color: AppColors.borde),
                      ),
                      const Text('Materiales incluidos:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (d == null || d.lineas.isEmpty)
                        const Text(
                            '• F-AAAA-XXXX · Código · Cajas · Parrillas · Lote · Ton',
                            style: TextStyle(
                                color: AppColors.gris, fontSize: 12))
                      else
                        for (final l in d.lineas)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                                '• ${l.folio} · ${l.codigo} · ${l.cajas} cajas · ${l.parrillas ?? '-'} parrillas · ${l.lote ?? '-'} · ${l.toneladas.toStringAsFixed(1)} ton',
                                style: const TextStyle(
                                    color: AppColors.gris,
                                    fontSize: 12)),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  text: _descargando ? 'Abriendo...' : 'Descargar PDF',
                  onPressed:
                  (d == null || _descargando) ? null : _descargar,
                ),
                if (d != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _editarEmbarque,
                      child: const Text('Datos del embarque (placas, chofer, sello…)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (d.fechaRecepcion != null)
                    Text('Recibido el ${formatoFechaHora(d.fechaRecepcion!)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.verde,
                            fontSize: 13,
                            fontWeight: FontWeight.w600))
                  else
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _recibiendo ? null : _recibir,
                        child: Text(_recibiendo
                            ? 'Registrando...'
                            : 'Marcar camión como recibido'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}