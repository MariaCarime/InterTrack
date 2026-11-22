import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Abre el cuadro "Guardar como" y guarda el archivo.
/// Devuelve la ruta, o null si la persona canceló.
Future<String?> guardarArchivo(String nombre, Uint8List bytes) async {
  final uri = await FilePicker.saveFile(
    dialogTitle: 'Guardar archivo',
    fileName: nombre,
    bytes: bytes,
  );
  if (uri == null) return null;

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await File(uri.toFilePath()).writeAsBytes(bytes);
  }
  return uri.toString();
}