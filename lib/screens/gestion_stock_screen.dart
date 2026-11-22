import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

const double _limiteCamion = 35;

class MaterialStock {
  final String codigo;
  final String descripcion;
  final int disponible; // existencia actual en cajas
  final int asignado; // saldo_asignado por Planta
  final int puntoReorden;
  final int stockIdeal;
  final int cajasPorParrilla;
  final double pesoCaja; // kg
  final bool altaRotacion;

  const MaterialStock({
    required this.codigo,
    required this.descripcion,
    required this.disponible,
    this.asignado = 0,
    required this.puntoReorden,
    required this.stockIdeal,
    required this.cajasPorParrilla,
    required this.pesoCaja,
    this.altaRotacion = false,
  });

  bool get bajoReorden => disponible < puntoReorden;

  int get faltante => stockIdeal > disponible ? stockIdeal - disponible : 0;

  /// El faltante se redondea hacia arriba a parrillas completas.
  int get parrillasAReponer => (faltante / cajasPorParrilla).ceil();
  int get cajasAReponer => parrillasAReponer * cajasPorParrilla;
  double get toneladasAReponer => cajasAReponer * pesoCaja / 1000;

  /// Si Planta ya asignó material suficiente, se genera la OC directo.
  bool get asignadoCubre => asignado >= cajasAReponer;
}

class GestionStockScreen extends StatefulWidget {
  const GestionStockScreen({super.key});

  @override
  State<GestionStockScreen> createState() => _GestionStockScreenState();
}

class _GestionStockScreenState extends State<GestionStockScreen> {
  // TODO: cargar desde Supabase (material + existencia_planta) y analizar la
  // rotación con las ventas de los últimos 12 meses.
  final List<MaterialStock> _materiales = [];

  List<MaterialStock> get _enReposicion =>
      _materiales.where((m) => m.bajoReorden).toList();

  void _importar() => Navigator.pushNamed(context, '/importar');

  void _accion(MaterialStock m) {
    // TODO: crear orden_compra de tipo 'stock' (independiente de pedidos).
    // Si no hay asignación suficiente, queda "Esperando Aprobación de Planta".
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m.asignadoCubre
            ? 'Orden de compra generada'
            : 'Solicitud enviada a Planta')));
  }

  @override
  Widget build(BuildContext context) {
    final lista = _enReposicion;
    final totalTon = lista.fold(0.0, (s, m) => s + m.toneladasAReponer);
    final camiones = (totalTon / _limiteCamion).ceil();

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Column(
        children: [
          const BlueHeader(
              subtitle: 'Reposición independiente de pedidos',
              title: 'Gestión de Stock'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Análisis de rotación (últimos 12 meses)',
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_materiales.isEmpty)
                  const EmptyStateCard(
                    title: 'No hay materiales registrados',
                    message:
                    'El catálogo de materiales y sus existencias aparecerán aquí una vez cargados.',
                  )
                else if (lista.isEmpty)
                  const EmptyStateCard(
                    title: 'Sin reposiciones pendientes',
                    message:
                    'Todos los materiales están por encima de su punto de reorden.',
                  )
                else ...[
                    for (final m in lista)
                      _MaterialCard(m, onAccion: () => _accion(m)),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.azulPalido,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Reposición total: ${lista.map((m) => m.toneladasAReponer.toStringAsFixed(2)).join(' + ')} = ${totalTon.toStringAsFixed(2)} ton',
                              style: const TextStyle(
                                  color: AppColors.azul,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              'Equivale a $camiones ${camiones == 1 ? 'camión' : 'camiones'} (máximo 35 ton por camión)',
                              style: const TextStyle(
                                  color: AppColors.gris, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                const SizedBox(height: 16),
                if (_materiales.isEmpty)
                  PrimaryButton(
                      text: 'Importar catálogo (Excel / CSV)',
                      onPressed: _importar)
                else
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _importar,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.blanco,
                        foregroundColor: AppColors.azul,
                        side: const BorderSide(color: AppColors.azul),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Importar catálogo (Excel / CSV)'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialStock m;
  final VoidCallback onAccion;
  const _MaterialCard(this.m, {required this.onAccion});

  String _kg(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    const gris = TextStyle(color: AppColors.gris, fontSize: 12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${m.descripcion}${m.altaRotacion ? ' (alta rotación)' : ''}',
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('Existencia: ${m.disponible} cajas', style: gris)),
              Text('Ideal: ${m.stockIdeal} cajas', style: gris),
            ],
          ),
          const SizedBox(height: 4),
          Text('Faltan ${m.faltante} cajas · Asignado: ${m.asignado}',
              style: const TextStyle(
                  color: AppColors.rojo,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              'Parrilla: ${m.cajasPorParrilla} cajas → ${m.parrillasAReponer} parrillas = ${m.cajasAReponer} cajas',
              style: gris),
          const SizedBox(height: 4),
          Text(
              'Peso: ${m.cajasAReponer} cajas × ${_kg(m.pesoCaja)} kg = ${m.toneladasAReponer.toStringAsFixed(2)} ton',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          PrimaryButton(
              text: m.asignadoCubre ? 'Generar OC' : 'Solicitar a Planta',
              onPressed: onAccion),
        ],
      ),
    );
  }
}