import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intertrack_app/models/camion.dart';

Future<Uint8List> construirTripPdf(DatosTrip t) async {
  final doc = pw.Document();
  final ahora = DateTime.now();
  String dos(int n) => n.toString().padLeft(2, '0');
  final fecha =
      '${dos(ahora.day)}/${dos(ahora.month)}/${ahora.year} ${dos(ahora.hour)}:${dos(ahora.minute)}';

  pw.Widget celda(String texto,
      {bool negrita = false, pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(texto,
            textAlign: align,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  final totalCajas = t.lineas.fold<int>(0, (s, l) => s + l.cajas);
  final totalParrillas = t.lineas.fold<int>(0, (s, l) => s + (l.parrillas ?? 0));

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Text('TRIP / PREVIO',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Camión ${t.idCamion}  -  $fecha',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 14),
        pw.Text('Origen: ${t.origen ?? 'No indicado'}',
            style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 3),
        pw.Text('Destino: ${t.destino}', style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 3),
        pw.Text('Fletera: ${t.fletera}', style: const pw.TextStyle(fontSize: 11)),
        if (t.numeroTrip != null) ...[
          pw.SizedBox(height: 3),
          pw.Text('Trip: ${t.numeroTrip}', style: const pw.TextStyle(fontSize: 11)),
        ],
        if (t.placas != null || t.economico != null) ...[
          pw.SizedBox(height: 3),
          pw.Text(
              'Placas: ${t.placas ?? '-'}   Económico: ${t.economico ?? '-'}',
              style: const pw.TextStyle(fontSize: 11)),
        ],
        if (t.chofer != null || t.sello != null) ...[
          pw.SizedBox(height: 3),
          pw.Text('Chofer: ${t.chofer ?? '-'}   Sello: ${t.sello ?? '-'}',
              style: const pw.TextStyle(fontSize: 11)),
        ],
        pw.SizedBox(height: 3),
        pw.Text('Peso total: ${t.toneladas.toStringAsFixed(2)} ton (límite: menos de 34.5 ton)',
            style: const pw.TextStyle(fontSize: 11)),
        if (t.costoFlete != null && t.tarifaTonelada != null) ...[
          pw.SizedBox(height: 3),
          pw.Text(
              'Flete: ${t.toneladas.toStringAsFixed(2)} ton x \$${t.tarifaTonelada!.toStringAsFixed(2)} = \$${t.costoFlete!.toStringAsFixed(2)} + IVA (16%): \$${(t.costoFlete! * 0.16).toStringAsFixed(2)} = Total \$${(t.costoFlete! * 1.16).toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 11)),
        ],
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.5),
            1: pw.FlexColumnWidth(2.4),
            2: pw.FlexColumnWidth(3),
            3: pw.FlexColumnWidth(1),
            4: pw.FlexColumnWidth(1.2),
            5: pw.FlexColumnWidth(1.2),
            6: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                celda('Pedido', negrita: true),
                celda('Código', negrita: true),
                celda('Descripción', negrita: true),
                celda('Cajas', negrita: true, align: pw.TextAlign.right),
                celda('Parrillas', negrita: true, align: pw.TextAlign.right),
                celda('Lote', negrita: true),
                celda('Ton', negrita: true, align: pw.TextAlign.right),
              ],
            ),
            for (final l in t.lineas)
              pw.TableRow(children: [
                celda(l.facturaPo == null ? l.folio : '${l.folio}\nP.O. ${l.facturaPo}'),
                celda(l.codigo),
                celda(l.descripcion),
                celda('${l.cajas}', align: pw.TextAlign.right),
                celda(l.parrillas == null ? '-' : '${l.parrillas}',
                    align: pw.TextAlign.right),
                celda(l.lote ?? '-'),
                celda(l.toneladas.toStringAsFixed(2), align: pw.TextAlign.right),
              ]),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                celda('TOTAL', negrita: true),
                celda(''),
                celda(''),
                celda('$totalCajas', negrita: true, align: pw.TextAlign.right),
                celda('$totalParrillas', negrita: true, align: pw.TextAlign.right),
                celda(''),
                celda(t.toneladas.toStringAsFixed(2),
                    negrita: true, align: pw.TextAlign.right),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}