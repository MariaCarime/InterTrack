import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/articulo.dart';
import 'package:intertrack_app/models/cliente.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/etiquetas.dart';
import 'package:intertrack_app/screens/confirmacion_pedido_screen.dart';

class _LineaForm {
  Articulo? articulo;
  final TextEditingController cantidad = TextEditingController();
  void dispose() => cantidad.dispose();
}

class RegistrarPedidoScreen extends StatefulWidget {
  const RegistrarPedidoScreen({super.key});

  @override
  State<RegistrarPedidoScreen> createState() => _RegistrarPedidoScreenState();
}

class _RegistrarPedidoScreenState extends State<RegistrarPedidoScreen> {
  final _servicio = PedidoService();
  final _documentoErp = TextEditingController();
  final List<_LineaForm> _lineas = [_LineaForm()];

  List<Cliente> _clientes = [];
  List<({int id, String nombre})> _asesores = [];
  List<Articulo> _articulos = [];

  String? _cliente;
  String? _asesor;
  bool _urgente = false;
  bool _cargando = true;
  bool _guardando = false;

  // Getters requeridos para manejar las etiquetas únicas de clientes y asesores
  Map<String, Cliente> get _clientesPorEtiqueta =>
      etiquetasUnicas(_clientes, (c) => c.nombre, (c) => c.contacto ?? '');
  Map<String, ({int id, String nombre})> get _asesoresPorEtiqueta =>
      etiquetasUnicas(_asesores, (a) => a.nombre);

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  @override
  void dispose() {
    _documentoErp.dispose();
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  void _mensaje(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _cargarOpciones() async {
    try {
      final clientes = await _servicio.clientesActivos();
      final asesores = await _servicio.asesoresActivos();
      final articulos = await _servicio.articulos();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _asesores = asesores;
        _articulos = articulos;
      });
    } catch (e) {
      _mensaje('No se pudieron cargar los datos: ${mensajeDeError(e)}');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (_cliente == null) {
      _mensaje('Selecciona un cliente');
      return;
    }
    if (_asesor == null) {
      _mensaje('Selecciona un asesor responsable');
      return;
    }
    final lineas = <({String codigo, int cantidad})>[];
    for (final l in _lineas) {
      final cant = int.tryParse(l.cantidad.text.trim());
      if (l.articulo == null || cant == null || cant <= 0) {
        _mensaje('Cada producto necesita un material y una cantidad mayor a 0');
        return;
      }
      lineas.add((codigo: l.articulo!.codigoArticulo, cantidad: cant));
    }

    setState(() => _guardando = true);
    try {
      final r = await _servicio.crear(
        idCliente: _clientesPorEtiqueta[_cliente]!.idCliente,
        idAsesor: _asesoresPorEtiqueta[_asesor]!.id,
        documentoErp: _documentoErp.text,
        urgente: _urgente,
        lineas: lineas,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ConfirmacionPedidoScreen(folio: r.folio, idPedido: r.idPedido),
        ),
      );
    } catch (e) {
      _mensaje(mensajeDeError(e));
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BlueHeader(
            onBack: null, // Deja que el botón de volver use la lógica automática que configuramos antes
            subtitle: 'Gerente de Compras',
            title: 'Registrar Pedido',
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const AppTextField(
                  label: 'Folio',
                  hint: 'Automático al guardar (no editable)',
                  enabled: false,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Documento ERP',
                  hint: 'Número de pedido o factura',
                  controller: _documentoErp,
                ),
                const SizedBox(height: 16),
                AppSelectField(
                  label: 'Cliente',
                  hint: 'Seleccionar cliente',
                  options: _clientesPorEtiqueta.keys.toList(),
                  value: _cliente,
                  onSelected: (v) => setState(() => _cliente = v),
                  emptyMessage: 'Aún no hay clientes registrados.',
                ),
                const SizedBox(height: 16),
                AppSelectField(
                  label: 'Asesor responsable',
                  hint: 'Seleccionar asesor',
                  options: _asesoresPorEtiqueta.keys.toList(),
                  value: _asesor,
                  onSelected: (v) => setState(() => _asesor = v),
                  emptyMessage: 'Aún no hay asesores registrados.',
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _lineas.length; i++) ...[
                  _SelectorArticulo(
                    label: i == 0 ? 'Producto' : 'Producto ${i + 1}',
                    articulos: _articulos,
                    valor: _lineas[i].articulo,
                    onSelected: (a) =>
                        setState(() => _lineas[i].articulo = a),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Cantidad',
                    hint: 'Número de cajas',
                    controller: _lineas[i].cantidad,
                    keyboardType: TextInputType.number,
                  ),
                  if (i > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final quitada = _lineas[i];
                          setState(() => _lineas.removeAt(i));
                          WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => quitada.dispose());
                        },
                        child: const Text('Quitar producto',
                            style: TextStyle(
                                color: AppColors.rojo, fontSize: 13)),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _lineas.add(_LineaForm())),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('+ Agregar otro producto',
                          style: TextStyle(
                              color: AppColors.azul,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                            'Marcar como urgente (entrega en 7–9 días)',
                            style: TextStyle(fontSize: 14)),
                      ),
                      Switch(
                        value: _urgente,
                        onChanged: (v) => setState(() => _urgente = v),
                        thumbColor: const WidgetStatePropertyAll(
                            AppColors.blanco),
                        trackColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected)
                            ? AppColors.naranja
                            : AppColors.borde),
                        trackOutlineColor: const WidgetStatePropertyAll(
                            Colors.transparent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                    'El folio se genera automáticamente al guardar.',
                    style:
                    TextStyle(color: AppColors.gris, fontSize: 12)),
                const SizedBox(height: 14),
                PrimaryButton(
                  text: _guardando ? 'Guardando...' : 'Guardar pedido',
                  onPressed: _guardando ? null : _guardar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo que abre un buscador de materiales por código o descripción.
class _SelectorArticulo extends StatelessWidget {
  final String label;
  final List<Articulo> articulos;
  final Articulo? valor;
  final ValueChanged<Articulo> onSelected;

  const _SelectorArticulo({
    required this.label,
    required this.articulos,
    required this.valor,
    required this.onSelected,
  });

  Future<void> _abrir(BuildContext context) async {
    final elegido = await showModalBottomSheet<Articulo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blanco,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BuscadorArticulos(articulos: articulos),
    );
    if (elegido != null) onSelected(elegido);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrir(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(valor?.etiqueta ?? 'Buscar material (código)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          color: valor == null
                              ? AppColors.gris
                              : AppColors.texto)),
                ),
                const Icon(Icons.search, color: AppColors.gris),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BuscadorArticulos extends StatefulWidget {
  final List<Articulo> articulos;
  const _BuscadorArticulos({required this.articulos});

  @override
  State<_BuscadorArticulos> createState() => _BuscadorArticulosState();
}

class _BuscadorArticulosState extends State<_BuscadorArticulos> {
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texto = _q.text.trim().toLowerCase();
    final lista = widget.articulos
        .where((a) =>
    texto.isEmpty ||
        a.codigoArticulo.toLowerCase().contains(texto) ||
        a.descripcion.toLowerCase().contains(texto))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AppTextField(
                  hint: 'Buscar por código o descripción', controller: _q),
              const SizedBox(height: 12),
              Expanded(
                child: lista.isEmpty
                    ? Center(
                  child: Text(
                    widget.articulos.isEmpty
                        ? 'Aún no hay materiales registrados.'
                        : 'Sin resultados.',
                    style: const TextStyle(color: AppColors.gris),
                  ),
                )
                    : ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final a = lista[i];
                    return ListTile(
                      title: Text(a.codigoArticulo,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      subtitle: Text(a.descripcion,
                          style: const TextStyle(fontSize: 12)),
                      onTap: () => Navigator.pop(context, a),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}