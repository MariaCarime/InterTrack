import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/filtros.dart';
import 'package:intertrack_app/models/archivos.dart';
import 'package:intertrack_app/models/consulta_service.dart';
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/reporte_pdf.dart';
import 'package:intertrack_app/widgets.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _servicio = ConsultaService();
  final _busqueda = TextEditingController();

  List<Pedido> _pedidos = [];
  bool _cargando = true;
  String? _error;

  String? _asesor;
  String? _estado;
  DateTimeRange? _fechas;
  bool _soloUrgentes = false;

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
      final datos = await _servicio.pedidos();
      if (mounted) setState(() => _pedidos = datos);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Pedido> get _filtrados {
    final q = _busqueda.text.trim().toLowerCase();
    return _pedidos.where((p) {
      if (_asesor != null && p.asesor != _asesor) return false;
      if (_estado != null && p.estado != _estado) return false;
      if (_soloUrgentes && !p.urgente) return false;
      if (!enRango(DateTime.parse(p.fecha), _fechas)) return false;
      if (q.isEmpty) return true;
      return p.folio.toLowerCase().contains(q) ||
          (p.documentoErp ?? '').toLowerCase().contains(q) ||
          p.cliente.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _filtroAsesor() async {
    if (_asesor != null) return setState(() => _asesor = null);
    final nombres = _pedidos.map((p) => p.asesor).toSet().toList()..sort();
    final r = await elegirOpcion(context, 'Filtrar por asesor', nombres);
    if (r != null) setState(() => _asesor = r);
  }

  Future<void> _filtroEstado() async {
    if (_estado != null) return setState(() => _estado = null);
    final r = await elegirOpcion(
        context, 'Filtrar por estado', [...kEstadosBd, kEstadoCanceladoBd]);
    if (r != null) setState(() => _estado = r);
  }

  Future<void> _filtroFecha() async {
    if (_fechas != null) return setState(() => _fechas = null);
    final r = await elegirRangoFechas(context);
    if (r != null) setState(() => _fechas = r);
  }

  Future<void> _exportar() async {
    final filas = _filtrados;
    try {
      final bytes = await construirTablaPdf(
        titulo: 'Reporte de pedidos - InterTrack',
        encabezados: [
          'Folio', 'Factura', 'Fecha', 'Cliente', 'Asesor', 'Estado', 'Urgente'
        ],
        filas: [
          for (final p in filas)
            [
              p.folio,
              p.documentoErp ?? '',
              p.fecha,
              p.cliente,
              p.asesor,
              p.estado,
              p.urgente ? 'Sí' : 'No',
            ]
        ],
      );
      final ruta = await guardarArchivo('Reporte_Pedidos_InterTrack.pdf', bytes);
      if (ruta != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reporte guardado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo exportar: ${mensajeDeError(e)}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: Column(
        children: [
          const BlueHeader(
              subtitle: 'Filtros avanzados', title: 'Búsqueda y Reportes'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
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
                      PillChip(
                        label: _asesor == null ? 'Asesor' : 'Asesor: $_asesor',
                        selected: _asesor != null,
                        onTap: _filtroAsesor,
                      ),
                      PillChip(
                        label: _fechas == null
                            ? 'Fecha'
                            : '${formatoFecha(_fechas!.start)} - ${formatoFecha(_fechas!.end)}',
                        selected: _fechas != null,
                        onTap: _filtroFecha,
                      ),
                      PillChip(
                        label: _estado == null ? 'Estado' : 'Estado: $_estado',
                        selected: _estado != null,
                        onTap: _filtroEstado,
                      ),
                      PillChip(
                        label: 'Urgencia',
                        selected: _soloUrgentes,
                        onTap: () =>
                            setState(() => _soloUrgentes = !_soloUrgentes),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Resultados (${lista.length})',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    EmptyStateCard(
                        title: 'No se pudo cargar', message: _error!)
                  else if (_pedidos.isEmpty)
                      const EmptyStateCard(
                        title: 'Sin resultados',
                        message: 'Aún no hay pedidos registrados.',
                      )
                    else if (lista.isEmpty)
                        const EmptyStateCard(
                          title: 'Sin resultados',
                          message: 'Ningún pedido coincide con la búsqueda o los filtros.',
                        )
                      else
                        for (final p in lista) _PedidoFila(p),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Exportar reporte (PDF)',
                    onPressed: lista.isEmpty ? null : _exportar,
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

class _PedidoFila extends StatelessWidget {
  final Pedido p;
  const _PedidoFila(this.p);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              Navigator.pushNamed(context, '/seguimiento', arguments: p.idPedido),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p.folio,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          if (p.urgente) ...[
                            const SizedBox(width: 8),
                            const Text('Urgente',
                                style: TextStyle(
                                    color: AppColors.rojo,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${p.cliente} · ${p.asesor}',
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('${p.estado} · ${p.fecha}',
                          style: const TextStyle(
                              color: AppColors.azul,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gris),
              ],
            ),
          ),
        ),
      ),
    );
  }
}