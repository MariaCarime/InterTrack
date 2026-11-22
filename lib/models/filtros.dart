import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';

/// Hoja inferior para elegir un valor de una lista. Devuelve null si se cierra.
Future<String?> elegirOpcion(
    BuildContext context, String titulo, List<String> opciones) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.blanco,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: ConstrainedBox(
        constraints:
        BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            Flexible(
              child: opciones.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay opciones disponibles todavía.',
                    style: TextStyle(color: AppColors.gris)),
              )
                  : ListView(
                shrinkWrap: true,
                children: [
                  for (final o in opciones)
                    ListTile(
                        title: Text(o),
                        onTap: () => Navigator.pop(context, o)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<DateTimeRange?> elegirRangoFechas(BuildContext context) =>
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

bool enRango(DateTime fecha, DateTimeRange? r) {
  if (r == null) return true;
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  return !dia.isBefore(r.start) && !dia.isAfter(r.end);
}