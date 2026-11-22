import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intertrack_app/models/consulta_service.dart';

/// PDF de tabla simple, usado por Reportes (RF-006) y por Historial.
Future<Uint8List> construirTablaPdf({
  required String titulo,
  required List<String> encabezados,
  required List<List<String>> filas,
}) async {
  final doc = pw.Document();
  final generado = formatoFechaHora(DateTime.now());

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Text(titulo,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Generado: $generado  -  ${filas.length} registros',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: encabezados,
          data: filas,
          headerStyle:
          pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.4),
        ),
      ],
    ),
  );
  return doc.save();
}