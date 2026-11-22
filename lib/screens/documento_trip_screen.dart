import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

class LineaTrip {
  final String folio;
  final String codigo;
  final int cajas;
  final int parrillas;
  final String lote;
  final double toneladas;
  const LineaTrip({
    required this.folio,
    required this.codigo,
    required this.cajas,
    required this.parrillas,
    required this.lote,
    required this.toneladas,
  });
}

class DocumentoTripScreen extends StatelessWidget {
  final String nombreArchivo;
  final String origen;
  final String destino;
  final String fletera;
  final double pesoTotal;
  final List<LineaTrip> lineas;

  const DocumentoTripScreen({
    super.key,
    this.nombreArchivo = 'Trip_XXXX.pdf',
    this.origen = 'Planta de origen',
    this.destino = 'CEDIS destino',
    this.fletera = 'Nombre de la fletera',
    this.pesoTotal = 0,
    this.lineas = const [],
  });

  void _descargar(BuildContext context) {
    // TODO: obtener la ruta de camion.ruta_pdf, pedir una URL firmada del
    // bucket privado 'trips' y abrir o guardar el archivo.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Descargando PDF...')));
  }

  @override
  Widget build(BuildContext context) {
    const gris = TextStyle(color: AppColors.gris, fontSize: 13);

    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Vista previa del documento',
            title: nombreArchivo,
          ),
          Expanded(
            child: ListView(
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
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text('Origen: $origen  →  Destino: $destino',
                          style: gris),
                      const SizedBox(height: 8),
                      Text('Fletera: $fletera', style: gris),
                      const SizedBox(height: 8),
                      Text('Peso total: ${pesoTotal.toStringAsFixed(1)} / 35 ton',
                          style: gris),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: AppColors.borde),
                      ),
                      const Text('Materiales incluidos:',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (lineas.isEmpty)
                        const Text(
                            '• F-AAAA-XXXX · Código · Cajas · Parrillas · Lote · Ton',
                            style: TextStyle(
                                color: AppColors.gris, fontSize: 12))
                      else
                        for (final l in lineas)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                                '• ${l.folio} · ${l.codigo} · ${l.cajas} cajas · ${l.parrillas} parrillas · ${l.lote} · ${l.toneladas.toStringAsFixed(1)} ton',
                                style: const TextStyle(
                                    color: AppColors.gris, fontSize: 12)),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                    text: 'Descargar PDF', onPressed: () => _descargar(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}