import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/asignados.dart';
import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/consulta_service.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/widgets.dart';

class AsignadosPlantaScreen extends StatefulWidget {
  const AsignadosPlantaScreen({super.key});

  @override
  State<AsignadosPlantaScreen> createState() => _AsignadosPlantaScreenState();
}

class _AsignadosPlantaScreenState extends State<AsignadosPlantaScreen> {
  final _servicio = AsignadosService();
  final _busqueda = TextEditingController();

  CargaAsignados? _carga;
  List<AsignadoPlanta> _lineas = [];
  bool _cargando = true;
  bool _importando = false;
  String? _error;

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
      final usuario = await AuthService().obtenerUsuarioActual();
      if (usuario == null) throw 'Sesión no disponible';
      final carga = await _servicio.ultimaCarga(usuario.idSucursal);
      final lineas = carga == null ? <AsignadoPlanta>[] : await _servicio.lineas(carga.idCarga);
      if (!mounted) return;
      setState(() {
        _carga = carga;
        _lineas = lineas;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is String ? e : mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _importar() async {
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) {
        _mensaje('No se pudo leer el archivo');
        return;
      }

      final r = validarAsignados(f.name, bytes);
      if (!mounted) return;
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => _ResumenImportacion(resultado: r, hayCargaPrevia: _carga != null),
      );
      if (confirmar != true) return;

      setState(() => _importando = true);
      final n = await _servicio.importar(r.archivo, r.filasValidas);
      _mensaje('Se importaron $n filas');
      await _cargar();
    } catch (e) {
      _mensaje(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  List<AsignadoPlanta> get _filtradas {
    final q = _busqueda.text.trim().toLowerCase();
    if (q.isEmpty) return _lineas;
    return _lineas.where((a) {
      return a.codigoArticulo.toLowerCase().contains(q) ||
          (a.descripcion ?? '').toLowerCase().contains(q) ||
          (a.numeroOrden ?? '').toLowerCase().contains(q) ||
          (a.ordenCompra ?? '').toLowerCase().contains(q) ||
          (a.tono ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String _cant(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Gestión de Stock',
            title: 'Asignados de Planta',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_carga != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Carga vigente',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${_carga!.archivo ?? 'Archivo'} · ${_carga!.filas} filas\nImportada: ${formatoFechaHora(_carga!.importadoEn)}',
                              style: const TextStyle(color: AppColors.gris, fontSize: 13)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: _importando ? 'Importando...' : 'Importar archivo de Planta',
                    onPressed: _importando ? null : _importar,
                  ),
                  const SizedBox(height: 18),
                  if (_carga != null) ...[
                    AppTextField(
                      label: 'Buscar',
                      hint: 'Artículo, descripción, orden o tono',
                      controller: _busqueda,
                    ),
                    const SizedBox(height: 14),
                    Text('Asignado (${lista.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                  ],
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    EmptyStateCard(title: 'No se pudo cargar', message: _error!)
                  else if (_carga == null)
                      const EmptyStateCard(
                        title: 'Aún no hay asignados cargados',
                        message:
                        'Importa el archivo que Planta envía cada día a las 9:00 AM.',
                      )
                    else if (lista.isEmpty)
                        const EmptyStateCard(
                            title: 'Sin resultados', message: 'Nada coincide con la búsqueda.')
                      else
                        for (final a in lista) _FilaAsignado(a, _cant(a.cantidad)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaAsignado extends StatelessWidget {
  final AsignadoPlanta a;
  final String cantidad;
  const _FilaAsignado(this.a, this.cantidad);

  @override
  Widget build(BuildContext context) {
    final detalle = [
      if ((a.tono ?? '').isNotEmpty) 'Tono ${a.tono}',
      if ((a.plantaOrigen ?? '').isNotEmpty) a.plantaOrigen!,
      if ((a.numeroOrden ?? '').isNotEmpty) 'Orden ${a.numeroOrden}',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.codigoArticulo,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                if ((a.descripcion ?? '').isNotEmpty)
                  Text(a.descripcion!,
                      style: const TextStyle(color: AppColors.gris, fontSize: 13)),
                if (detalle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(detalle,
                        style: const TextStyle(color: AppColors.gris, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(cantidad,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.azul)),
        ],
      ),
    );
  }
}

class _ResumenImportacion extends StatelessWidget {
  final ResultadoAsignados resultado;
  final bool hayCargaPrevia;
  const _ResumenImportacion({required this.resultado, required this.hayCargaPrevia});

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final cant = r.totalCantidad;
    final total = cant == cant.roundToDouble() ? cant.toInt().toString() : cant.toStringAsFixed(2);
    return AlertDialog(
      title: const Text('Revisar archivo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.archivo, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Filas leídas: ${r.filasLeidas}'),
            Text('Filas válidas: ${r.validas} (cantidad total: $total)'),
            Text('Filas con error: ${r.errores.length}',
                style: TextStyle(color: r.errores.isEmpty ? null : AppColors.rojo)),
            if (r.errores.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final e in r.errores.take(5))
                Text('Fila ${e.fila}: ${e.mensaje}',
                    style: const TextStyle(fontSize: 12, color: AppColors.rojo)),
              if (r.errores.length > 5)
                Text('…y ${r.errores.length - 5} más',
                    style: const TextStyle(fontSize: 12, color: AppColors.gris)),
            ],
            if (r.columnasSinUsar.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Columnas que no se usan: ${r.columnasSinUsar.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gris)),
            ],
            if (hayCargaPrevia && r.validas > 0) ...[
              const SizedBox(height: 10),
              const Text(
                  'Esta carga reemplaza a la vigente. La anterior queda guardada como historial.',
                  style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        TextButton(
            onPressed: r.validas == 0 ? null : () => Navigator.pop(context, true),
            child: Text(r.errores.isEmpty
                ? 'Importar ${r.validas} filas'
                : 'Importar solo las ${r.validas} válidas')),
      ],
    );
  }
}