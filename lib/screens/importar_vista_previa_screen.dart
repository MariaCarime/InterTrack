import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

class ErrorFila {
  final int fila;
  final String mensaje;
  const ErrorFila(this.fila, this.mensaje);
}

/// Resultado de validar el archivo. Por defecto está vacío (sin archivo leído).
class ResultadoValidacion {
  final String archivo;
  final int filasLeidas;
  final int validas;
  final List<ErrorFila> errores;

  const ResultadoValidacion({
    this.archivo = 'Nombre del archivo.xlsx',
    this.filasLeidas = 0,
    this.validas = 0,
    this.errores = const [],
  });

  int get conError => errores.length;
}

class ImportarVistaPreviaScreen extends StatelessWidget {
  final ResultadoValidacion resultado;

  const ImportarVistaPreviaScreen(
      {super.key, this.resultado = const ResultadoValidacion()});

  static const _maxErroresVisibles = 10;

  void _importar(BuildContext context) {
    // TODO: Edge Function de importación: los materiales existentes se
    // actualizan y los nuevos se crean según codigo_articulo; las existencias
    // del archivo REEMPLAZAN las actuales. Solo se importan las filas válidas.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Importando...')));
  }

  void _descargarReporte(BuildContext context) {
    // TODO: generar un archivo con las filas con error y su motivo.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descarga del reporte próximamente')));
  }

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final visibles = r.errores.take(_maxErroresVisibles).toList();
    final ocultos = r.errores.length - visibles.length;

    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Vista previa y validación',
            title: 'Importar catálogo',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Archivo
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.azulPalido,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(r.archivo,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Contadores
                Row(
                  children: [
                    Expanded(
                        child: _Dato(
                            valor: r.filasLeidas,
                            etiqueta: 'Filas leídas',
                            color: AppColors.texto)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _Dato(
                            valor: r.validas,
                            etiqueta: 'Válidas',
                            color: AppColors.verde)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _Dato(
                            valor: r.conError,
                            etiqueta: 'Con error',
                            color: AppColors.rojo)),
                  ],
                ),
                const SizedBox(height: 12),

                // Errores
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
                      const Text('Errores encontrados',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (visibles.isEmpty)
                        const Text('Sin errores por mostrar.',
                            style:
                            TextStyle(color: AppColors.gris, fontSize: 13))
                      else ...[
                        for (final e in visibles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('Fila ${e.fila} · ${e.mensaje}',
                                style: const TextStyle(
                                    color: AppColors.rojo, fontSize: 13)),
                          ),
                        if (ocultos > 0)
                          Text('y $ocultos más en el reporte de errores',
                              style: const TextStyle(
                                  color: AppColors.gris, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Los materiales que ya existen se actualizan y los nuevos se crean, según su código de artículo. Las existencias del archivo reemplazan las actuales.',
                    style: TextStyle(
                        color: AppColors.gris, fontSize: 12, height: 1.4)),
                const SizedBox(height: 14),

                PrimaryButton(
                  text: r.validas > 0
                      ? 'Importar ${r.validas} filas válidas'
                      : 'Importar filas válidas',
                  onPressed: r.validas > 0 ? () => _importar(context) : null,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: r.errores.isEmpty
                        ? null
                        : () => _descargarReporte(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.blanco,
                      foregroundColor: AppColors.azul,
                      disabledForegroundColor: AppColors.deshabilitado,
                      side: BorderSide(
                          color: r.errores.isEmpty
                              ? AppColors.borde
                              : AppColors.azul),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Descargar reporte de errores'),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(
                          color: AppColors.azul,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final Color color;

  const _Dato(
      {required this.valor, required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$valor',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(etiqueta,
              style: const TextStyle(color: AppColors.gris, fontSize: 12)),
        ],
      ),
    );
  }
}