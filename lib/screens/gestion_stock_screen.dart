import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/stock.dart';
import 'package:intertrack_app/models/stock_service.dart';

const double _limiteCamion = 35;

class GestionStockScreen extends StatefulWidget {
  const GestionStockScreen({super.key});

  @override
  State<GestionStockScreen> createState() => _GestionStockScreenState();
}

class _GestionStockScreenState extends State<GestionStockScreen> {
  final _servicio = StockService();
  List<MaterialStock> _enReposicion = [];
  bool _hayMateriales = false;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _mensaje(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final hay = await _servicio.hayMateriales();
      final lista = await _servicio.bajoReorden();
      if (!mounted) return;
      setState(() {
        _hayMateriales = hay;
        _enReposicion = lista;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _importar() async {
    await Navigator.pushNamed(context, '/importar');
    _cargar();
  }

  Future<void> _accion(MaterialStock m) async {
    try {
      final r = await _servicio.crearOrden(m.codigo);
      await _cargar();
      _mensaje(r == 'orden' ? 'Orden de compra generada' : 'Solicitud enviada a Planta');
    } catch (e) {
      _mensaje(mensajeDeError(e));
    }
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
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Materiales por debajo de su punto de reorden',
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null) ...[
                    EmptyStateCard(
                        title: 'No se pudo cargar el stock', message: _error!),
                    TextButton(
                        onPressed: _cargar, child: const Text('Reintentar')),
                  ] else if (!_hayMateriales)
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
                  if (!_hayMateriales)
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
          Text(m.descripcion,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(m.codigo, style: gris),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: Text('Existencia: ${m.disponible} cajas', style: gris)),
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
              m.tieneParrilla
                  ? 'Parrilla: ${m.cajasPorParrilla} cajas → ${m.parrillasAReponer} parrillas = ${m.cajasAReponer} cajas'
                  : 'Sin parrilla definida: se pide el faltante exacto (${m.cajasAReponer} cajas)',
              style: gris),
          const SizedBox(height: 4),
          Text(
              'Peso: ${m.cajasAReponer} cajas × ${_kg(m.pesoCaja)} kg = ${m.toneladasAReponer.toStringAsFixed(2)} ton',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          PrimaryButton(
            text: m.pendiente
                ? 'Solicitud pendiente de Planta'
                : (m.asignadoCubre ? 'Generar OC' : 'Solicitar a Planta'),
            onPressed: m.pendiente ? null : onAccion,
          ),
        ],
      ),
    );
  }
}