import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/existencias.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/widgets.dart';

enum _Filtro { todos, bajoReorden, conAsignado }

class ExistenciasScreen extends StatefulWidget {
  const ExistenciasScreen({super.key});

  @override
  State<ExistenciasScreen> createState() => _ExistenciasScreenState();
}

class _ExistenciasScreenState extends State<ExistenciasScreen> {
  final _servicio = ExistenciasService();
  final _busqueda = TextEditingController();
  List<ExistenciaMaterial> _todas = [];
  bool _cargando = true;
  String? _error;
  _Filtro _filtro = _Filtro.todos;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _servicio.todas();
      if (mounted) setState(() => _todas = datos);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<ExistenciaMaterial> get _filtradas {
    final q = _busqueda.text.trim().toLowerCase();
    return _todas.where((e) {
      if (_filtro == _Filtro.bajoReorden && !e.bajoReorden) return false;
      if (_filtro == _Filtro.conAsignado && e.asignado <= 0) return false;
      if (q.isEmpty) return true;
      return e.codigo.toLowerCase().contains(q) ||
          e.descripcion.toLowerCase().contains(q) ||
          e.bodega.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Gestión de Stock',
            title: 'Existencias de Planta',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppTextField(
                    label: 'Buscar',
                    hint: 'Código, descripción o bodega',
                    controller: _busqueda,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PillChip(
                          label: 'Todos',
                          selected: _filtro == _Filtro.todos,
                          onTap: () => setState(() => _filtro = _Filtro.todos)),
                      PillChip(
                          label: 'Bajo reorden',
                          selected: _filtro == _Filtro.bajoReorden,
                          onTap: () => setState(() => _filtro = _Filtro.bajoReorden)),
                      PillChip(
                          label: 'Con asignado',
                          selected: _filtro == _Filtro.conAsignado,
                          onTap: () => setState(() => _filtro = _Filtro.conAsignado)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Materiales (${lista.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    EmptyStateCard(title: 'No se pudo cargar', message: _error!)
                  else if (_todas.isEmpty)
                      const EmptyStateCard(
                        title: 'Sin existencias registradas',
                        message:
                        'Importa el catálogo con sus existencias desde la pestaña Stock.',
                      )
                    else if (lista.isEmpty)
                        const EmptyStateCard(
                            title: 'Sin resultados',
                            message: 'Nada coincide con la búsqueda o el filtro.')
                      else
                        for (final e in lista) _FilaExistencia(e),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaExistencia extends StatelessWidget {
  final ExistenciaMaterial e;
  const _FilaExistencia(this.e);

  Widget _dato(String etiqueta, int valor, {Color? color}) => Expanded(
    child: Column(
      children: [
        Text('$valor',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color ?? AppColors.azul)),
        const SizedBox(height: 2),
        Text(etiqueta,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gris, fontSize: 11)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
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
          Text(e.descripcion,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text('${e.codigo} · ${e.bodega}',
              style: const TextStyle(color: AppColors.gris, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              _dato('Disponible', e.disponible),
              _dato('Asignado', e.asignado),
              _dato('Remesa', e.remesa),
              _dato('En producción', e.enProduccion),
            ],
          ),
          if (e.puntoReorden > 0) ...[
            const SizedBox(height: 8),
            Text(
                'Reorden: ${e.puntoReorden} · Ideal: ${e.stockIdeal}${e.bajoReorden ? ' · Bajo reorden' : ''}',
                style: TextStyle(
                    color: e.bajoReorden ? AppColors.rojo : AppColors.gris,
                    fontSize: 12,
                    fontWeight: e.bajoReorden ? FontWeight.w600 : FontWeight.w400)),
          ],
        ],
      ),
    );
  }
}