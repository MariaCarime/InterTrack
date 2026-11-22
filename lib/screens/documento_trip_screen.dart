import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intertrack_app/models/archivos.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/camion.dart';
import 'package:intertrack_app/models/camion_service.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/trip_pdf.dart';

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
                      const SizedBox(height: 8),
                      Text(
                          'Peso total: ${(d?.toneladas ?? 0).toStringAsFixed(1)} / 35 ton',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}