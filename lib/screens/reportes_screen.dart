import 'package:flutter/material.dart';
import 'package:intertrack_app/widgets.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _busqueda = TextEditingController();
  final Set<String> _filtros = {};

  // TODO: reemplazar por resultados reales de Supabase según búsqueda y filtros.
  final List<String> _resultados = [];

  static const _opciones = ['Asesor', 'Fecha', 'Estado', 'Urgencia'];

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _alternar(String f) {
    // TODO: abrir selector de valor (asesor, rango de fechas, estado...).
    setState(() {
      if (!_filtros.remove(f)) _filtros.add(f);
    });
  }

  void _exportar() {
    // TODO: generar el PDF del reporte (RF-006, menos de 3 s).
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reporte generado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: Column(
        children: [
          const BlueHeader(
              subtitle: 'Filtros avanzados', title: 'Búsqueda y Reportes'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                  label: 'Buscar por folio, documento ERP o cliente',
                  hint: 'Folio, documento ERP o cliente',
                  controller: _busqueda,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in _opciones)
                      PillChip(
                        label: f,
                        selected: _filtros.contains(f),
                        onTap: () => _alternar(f),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Resultados',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_resultados.isEmpty)
                  const EmptyStateCard(
                    title: 'Sin resultados',
                    message: 'Aún no hay pedidos registrados.',
                  )
                else
                  for (final r in _resultados) Text(r),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Exportar reporte (PDF)',
                  onPressed: _resultados.isEmpty ? null : _exportar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}