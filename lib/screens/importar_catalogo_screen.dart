import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

class ImportarCatalogoScreen extends StatefulWidget {
  const ImportarCatalogoScreen({super.key});

  @override
  State<ImportarCatalogoScreen> createState() => _ImportarCatalogoScreenState();
}

class _ImportarCatalogoScreenState extends State<ImportarCatalogoScreen> {
  String? _archivo; // nombre del archivo elegido

  void _seleccionar() {
    // TODO: con el paquete file_picker, permitir solo ['xlsx', 'csv'] y
    // guardar los bytes del archivo para la vista previa (pantalla 19b).
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selector de archivos próximamente')));
  }

  void _descargarPlantilla() {
    // TODO: entregar una plantilla .xlsx con las columnas de abajo.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descarga de plantilla próximamente')));
  }

  void _continuar() {
    // TODO: leer el archivo, validar columnas y filas, y pasar el resultado
    // real a la vista previa (ResultadoValidacion).
    Navigator.pushNamed(context, '/importar-vista-previa');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Gestión de Stock',
            title: 'Importar catálogo',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CustomPaint(
                  painter: _BordeDiscontinuo(AppColors.azul),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                              color: AppColors.azulPalido,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(height: 14),
                        Text(_archivo ?? 'Selecciona un archivo',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text('Formatos permitidos: .xlsx y .csv',
                            style: TextStyle(
                                color: AppColors.gris, fontSize: 13)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _seleccionar,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.blanco,
                              foregroundColor: AppColors.azul,
                              side: const BorderSide(color: AppColors.azul),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            child: Text(_archivo == null
                                ? 'Seleccionar archivo'
                                : 'Cambiar archivo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Columnas del archivo',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text(
                          'Obligatorias: codigo_articulo, descripcion, peso_caja',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Text('Opcionales: cajas_por_parrilla, unidad_medida',
                          style:
                          TextStyle(color: AppColors.gris, fontSize: 12)),
                      SizedBox(height: 6),
                      Text(
                          'Existencias (reemplazan las actuales): bodega, disponible, asignado, remesa, en_produccion',
                          style:
                          TextStyle(color: AppColors.gris, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _descargarPlantilla,
                    child: const Text('Descargar plantilla',
                        style: TextStyle(
                            color: AppColors.azul,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 4),
                PrimaryButton(
                  text: 'Continuar',
                  onPressed: _archivo == null ? null : _continuar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Borde punteado redondeado de la zona de carga.
class _BordeDiscontinuo extends CustomPainter {
  final Color color;
  _BordeDiscontinuo(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(16)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordeDiscontinuo old) => old.color != color;
}