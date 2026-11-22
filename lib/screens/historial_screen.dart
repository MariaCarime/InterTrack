import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

/// Un movimiento de la bitácora (historial_pedido). Es de solo lectura:
/// la bitácora no se puede editar ni borrar (RNF-009).
class Movimiento {
  final String folio;
  final String usuario;
  final String estadoAnterior;
  final String estadoNuevo;
  final String descripcion;
  final String fechaHora; // dd/mm/aaaa hh:mm
  const Movimiento({
    required this.folio,
    required this.usuario,
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.descripcion,
    required this.fechaHora,
  });
}

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _busqueda = TextEditingController();
  final Set<String> _filtros = {};

  // TODO: cargar desde Supabase (historial_pedido) según búsqueda y filtros.
  final List<Movimiento> _movimientos = [];

  static const _opciones = ['Usuario', 'Fecha', 'Estado'];

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  void _alternar(String f) {
    // TODO: abrir el selector de valor (usuario, rango de fechas, estado).
    setState(() {
      if (!_filtros.remove(f)) _filtros.add(f);
    });
  }

  void _exportar() {
    // TODO: generar el PDF del historial.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Historial exportado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Rol: Gerente General',
            title: 'Historial y auditoría',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                  label: 'Buscar por folio, usuario o acción',
                  hint: 'Folio, usuario o acción',
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
                const Text('Movimientos',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_movimientos.isEmpty)
                  const EmptyStateCard(
                    title: 'Sin movimientos registrados',
                    message: 'Los cambios de estado aparecerán aquí.',
                  )
                else
                  for (final m in _movimientos) _MovimientoCard(m),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Exportar historial (PDF)',
                  onPressed: _movimientos.isEmpty ? null : _exportar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  final Movimiento m;
  const _MovimientoCard(this.m);

  @override
  Widget build(BuildContext context) {
    const gris = TextStyle(color: AppColors.gris, fontSize: 12);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.folio,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${m.estadoAnterior} → ${m.estadoNuevo}',
              style: const TextStyle(
                  color: AppColors.azul,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (m.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(m.descripcion, style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 4),
          Text('${m.fechaHora} · ${m.usuario}', style: gris),
        ],
      ),
    );
  }
}