import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/consulta_service.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/stock_cedis.dart';
import 'package:intertrack_app/widgets.dart';

/// Inventario físico del CEDIS: todo lo de la última carga, con filtro de bajo reorden.
/// Es independiente de las existencias y los asignados de Planta.
class InventarioCedis extends StatefulWidget {
  const InventarioCedis({super.key});

  @override
  State<InventarioCedis> createState() => _InventarioCedisState();
}

class _InventarioCedisState extends State<InventarioCedis> {
  final _servicio = StockCedisService();
  final _busqueda = TextEditingController();

  List<CargaStock> _cargas = [];
  List<ItemStockCedis> _items = [];
  int? _idSucursal;
  bool _cargando = true;
  bool _importando = false;
  bool _soloBajo = false;
  bool _soloCero = false;
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
      final cargas = await _servicio.cargas(usuario.idSucursal);
      final items = cargas.isEmpty ? <ItemStockCedis>[] : await _servicio.vigente();
      if (!mounted) return;
      setState(() {
        _idSucursal = usuario.idSucursal;
        _cargas = cargas;
        _items = items;
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

      final catalogo = await _servicio.codigosCatalogo();
      final r = validarStockCedis(
        f.name,
        bytes,
        catalogo,
        filasCargaAnterior: _cargas.isEmpty ? null : _cargas.first.filas,
      );
      if (!mounted) return;

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => _ResumenStock(resultado: r, hayCargaPrevia: _cargas.isNotEmpty),
      );
      if (confirmar != true) return;

      setState(() => _importando = true);
      final n = await _servicio.importar(r.archivo, r.filasValidas,
          confirmaFaltantes: r.faltantes.isNotEmpty);
      _mensaje('Se importaron $n artículos');
      await _cargar();
    } catch (e) {
      _mensaje(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  Future<void> _verHistorial() async {
    if (_idSucursal == null) return;
    try {
      final cargas = await _servicio.cargas(_idSucursal!, limite: 20);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cargas de stock'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (var i = 0; i < cargas.length; i++)
                  ListTile(
                    dense: true,
                    title: Text(cargas[i].archivo ?? 'Archivo'),
                    subtitle: Text(
                        '${formatoFechaHora(cargas[i].importadoEn)} · ${cargas[i].filas} artículos${cargas[i].faltantes > 0 ? ' · ${cargas[i].faltantes} quedaron en 0' : ''}'),
                    trailing: i == 0
                        ? const Text('Vigente',
                        style: TextStyle(
                            color: AppColors.verde, fontWeight: FontWeight.w600))
                        : null,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      );
    } catch (e) {
      _mensaje(mensajeDeError(e));
    }
  }

  List<ItemStockCedis> get _filtrados {
    final q = _busqueda.text.trim().toLowerCase();
    return _items.where((i) {
      if (_soloBajo && !i.bajoReorden) return false;
      if (_soloCero && i.cantidad > 0) return false;
      if (q.isEmpty) return true;
      return i.codigo.toLowerCase().contains(q) || i.descripcion.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    final totalCajas = _items.fold<int>(0, (s, i) => s + i.cantidad);
    final bajo = _items.where((i) => i.bajoReorden).length;
    final sinStock = _items.where((i) => i.cantidad == 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inventario físico del CEDIS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
            'Lo que hay en el almacén de la sucursal, según el último Excel que se importó. No incluye lo asignado por Planta.',
            style: TextStyle(color: AppColors.gris, fontSize: 12)),
        const SizedBox(height: 12),
        if (_cargas.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carga vigente: ${_cargas.first.archivo ?? 'Archivo'}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    '${formatoFechaHora(_cargas.first.importadoEn)} · ${_cargas.first.filas} artículos en el archivo\n${_items.length} en el catálogo · $totalCajas cajas · $sinStock en 0 · $bajo bajo reorden',
                    style: const TextStyle(color: AppColors.gris, fontSize: 12)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                      onPressed: _verHistorial, child: const Text('Ver cargas anteriores')),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        PrimaryButton(
          text: _importando ? 'Importando...' : 'Importar stock del CEDIS (Excel / CSV)',
          onPressed: _importando ? null : _importar,
        ),
        const SizedBox(height: 14),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyStateCard(title: 'No se pudo cargar el inventario', message: _error!)
        else if (_cargas.isEmpty)
            const EmptyStateCard(
              title: 'Aún no hay stock del CEDIS',
              message:
              'Importa el Excel de existencias físicas. Necesita las columnas codigo_articulo y cantidad (en cajas).',
            )
          else ...[
              AppTextField(
                label: 'Buscar',
                hint: 'Código o descripción',
                controller: _busqueda,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  PillChip(
                      label: 'Todos',
                      selected: !_soloBajo && !_soloCero,
                      onTap: () => setState(() {
                        _soloBajo = false;
                        _soloCero = false;
                      })),
                  PillChip(
                      label: 'Bajo reorden',
                      selected: _soloBajo,
                      onTap: () => setState(() {
                        _soloBajo = true;
                        _soloCero = false;
                      })),
                  PillChip(
                      label: 'Sin stock (0)',
                      selected: _soloCero,
                      onTap: () => setState(() {
                        _soloCero = true;
                        _soloBajo = false;
                      })),
                ],
              ),
              const SizedBox(height: 12),
              Text('Artículos (${lista.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (lista.isEmpty)
                const EmptyStateCard(
                    title: 'Sin resultados', message: 'Nada coincide con la búsqueda o el filtro.')
              else
                for (final i in lista) _FilaStock(i),
            ],
      ],
    );
  }
}

class _FilaStock extends StatelessWidget {
  final ItemStockCedis i;
  const _FilaStock(this.i);

  @override
  Widget build(BuildContext context) {
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
                Text(i.descripcion,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(i.codigo,
                    style: const TextStyle(color: AppColors.gris, fontSize: 12)),
                if (!i.enCarga)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('No venía en el último archivo (cuenta como 0)',
                        style: TextStyle(color: AppColors.naranja, fontSize: 12)),
                  ),
                if (i.puntoReorden > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        'Reorden: ${i.puntoReorden} · Ideal: ${i.stockIdeal}${i.bajoReorden ? ' · Bajo reorden' : ''}',
                        style: TextStyle(
                            color: i.bajoReorden ? AppColors.rojo : AppColors.gris,
                            fontSize: 12,
                            fontWeight: i.bajoReorden ? FontWeight.w600 : FontWeight.w400)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Text('${i.cantidad}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: i.bajoReorden ? AppColors.rojo : AppColors.azul)),
              const Text('cajas', style: TextStyle(color: AppColors.gris, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenStock extends StatefulWidget {
  final ResultadoStock resultado;
  final bool hayCargaPrevia;
  const _ResumenStock({required this.resultado, required this.hayCargaPrevia});

  @override
  State<_ResumenStock> createState() => _ResumenStockState();
}

class _ResumenStockState extends State<_ResumenStock> {
  bool _confirmado = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;
    final hayFaltantes = r.faltantes.isNotEmpty;
    final puedeImportar = r.sePuedeImportar && (!hayFaltantes || _confirmado);

    return AlertDialog(
      title: const Text('Revisar archivo de stock'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.archivo, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Filas leídas: ${r.filasLeidas}'),
            Text('Filas válidas: ${r.validas} (${r.totalCajas} cajas)'),
            Text('Filas con error: ${r.errores.length}',
                style: TextStyle(color: r.errores.isEmpty ? null : AppColors.rojo)),
            if (r.errores.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final e in r.errores.take(6))
                Text('Fila ${e.fila}: ${e.mensaje}',
                    style: const TextStyle(fontSize: 12, color: AppColors.rojo)),
              if (r.errores.length > 6)
                Text('…y ${r.errores.length - 6} más',
                    style: const TextStyle(fontSize: 12, color: AppColors.gris)),
              const SizedBox(height: 6),
              const Text(
                  'Corrige los errores y vuelve a subir el archivo. La carga debe estar completa: un artículo que falte se contaría como sin stock.',
                  style: TextStyle(fontSize: 12)),
            ],
            if (r.errores.isEmpty && r.validas > 0) ...[
              const SizedBox(height: 10),
              if (!hayFaltantes)
                const Text('El archivo incluye todos los artículos del catálogo.',
                    style: TextStyle(fontSize: 12, color: AppColors.verde))
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.naranja),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Atención: faltan ${r.faltantes.length} artículos del catálogo en este archivo',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.naranja)),
                      const SizedBox(height: 4),
                      const Text(
                          'Si importas, esos artículos quedarán registrados con 0 cajas. Si se te olvidaron filas en el Excel, cancela y corrige el archivo.',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                          '${r.faltantes.take(8).join(', ')}${r.faltantes.length > 8 ? ' …y ${r.faltantes.length - 8} más' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _confirmado,
                        onChanged: (v) => setState(() => _confirmado = v ?? false),
                        title: const Text(
                            'Confirmo que el archivo está completo y que esos artículos realmente no tienen existencias',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
            for (final a in r.advertencias) ...[
              const SizedBox(height: 8),
              Text(a, style: const TextStyle(fontSize: 12, color: AppColors.naranja)),
            ],
            if (r.columnasIgnoradas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Columnas que no se usan: ${r.columnasIgnoradas.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gris)),
            ],
            if (widget.hayCargaPrevia && r.sePuedeImportar) ...[
              const SizedBox(height: 10),
              const Text(
                  'Esta carga reemplaza al stock vigente. La anterior queda guardada como historial.',
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
            onPressed: puedeImportar ? () => Navigator.pop(context, true) : null,
            child: Text(hayFaltantes
                ? 'Importar (${r.faltantes.length} quedarán en 0)'
                : 'Importar ${r.validas} artículos')),
      ],
    );
  }
}
