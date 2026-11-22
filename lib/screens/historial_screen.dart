import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/filtros.dart';
import 'package:intertrack_app/models/archivos.dart';
import 'package:intertrack_app/models/consulta_service.dart';
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/reporte_pdf.dart';
import 'package:intertrack_app/widgets.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _servicio = ConsultaService();
  final _busqueda = TextEditingController();

  List<Movimiento> _movimientos = [];
  bool _cargando = true;
  String? _error;

  String? _usuario;
  String? _estado;
  DateTimeRange? _fechas;

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
      final datos = await _servicio.movimientos();
      if (mounted) setState(() => _movimientos = datos);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Movimiento> get _filtrados {
    final q = _busqueda.text.trim().toLowerCase();
    return _movimientos.where((m) {
      if (_usuario != null && m.usuario != _usuario) return false;
      if (_estado != null && m.estadoNuevo != _estado) return false;
      if (!enRango(m.fechaHora, _fechas)) return false;
      if (q.isEmpty) return true;
      return m.folio.toLowerCase().contains(q) ||
          m.usuario.toLowerCase().contains(q) ||
          m.descripcion.toLowerCase().contains(q) ||
          m.estadoNuevo.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _filtroUsuario() async {
    if (_usuario != null) return setState(() => _usuario = null);
    final nombres = _movimientos.map((m) => m.usuario).toSet().toList()..sort();
    final r = await elegirOpcion(context, 'Filtrar por usuario', nombres);
    if (r != null) setState(() => _usuario = r);
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
        titulo: 'Historial y auditoría - InterTrack',
        encabezados: ['Fecha y hora', 'Folio', 'Usuario', 'Cambio', 'Detalle'],
        filas: [
          for (final m in filas)
            [
              formatoFechaHora(m.fechaHora),
              m.folio,
              m.usuario,
              '${m.estadoAnterior ?? 'Registro inicial'} -> ${m.estadoNuevo}',
              m.descripcion,
            ]
        ],
      );
      final ruta = await guardarArchivo('Historial_InterTrack.pdf', bytes);
      if (ruta != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PDF guardado')));
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
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Rol: Gerente General',
            title: 'Historial y auditoría',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
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
                      PillChip(
                        label: _usuario == null ? 'Usuario' : 'Usuario: $_usuario',
                        selected: _usuario != null,
                        onTap: _filtroUsuario,
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
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Movimientos',
                      style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    EmptyStateCard(
                        title: 'No se pudo cargar el historial', message: _error!)
                  else if (_movimientos.isEmpty)
                      const EmptyStateCard(
                        title: 'Sin movimientos registrados',
                        message: 'Los cambios de estado aparecerán aquí.',
                      )
                    else if (lista.isEmpty)
                        const EmptyStateCard(
                          title: 'Sin resultados',
                          message: 'Ningún movimiento coincide con la búsqueda o los filtros.',
                        )
                      else
                        for (final m in lista) _MovimientoCard(m),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Exportar historial (PDF)',
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
          Text('${m.estadoAnterior ?? 'Registro inicial'} → ${m.estadoNuevo}',
              style: const TextStyle(
                  color: AppColors.azul,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (m.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(m.descripcion, style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 4),
          Text('${formatoFechaHora(m.fechaHora)} · ${m.usuario}', style: gris),
        ],
      ),
    );
  }
}