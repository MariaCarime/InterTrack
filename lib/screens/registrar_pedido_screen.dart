import 'package:flutter/material.dart';
import 'package:intertrack_app/models/etiquetas.dart';
import 'package:intertrack_app/models/sucursal.dart';
import 'package:intertrack_app/models/sucursal_service.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/articulo.dart';
import 'package:intertrack_app/models/cliente.dart';
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/solicitud_service.dart';
import 'package:intertrack_app/screens/confirmacion_pedido_screen.dart';

class _LineaForm {
  Articulo? articulo;
  final TextEditingController cantidad = TextEditingController();
  void dispose() => cantidad.dispose();
}

class RegistrarPedidoScreen extends StatefulWidget {
  /// Si viene un pedido, la pantalla funciona como edición.
  final Pedido? editar;
  const RegistrarPedidoScreen({super.key, this.editar});

  @override
  State<RegistrarPedidoScreen> createState() => _RegistrarPedidoScreenState();
}

class _RegistrarPedidoScreenState extends State<RegistrarPedidoScreen> {
  final _servicio = PedidoService();
  final _numeroFactura = TextEditingController();
  final _notaPlanta = TextEditingController();
  final List<_LineaForm> _lineas = [_LineaForm()];

  List<Cliente> _clientes = [];
  List<({int id, String nombre})> _asesores = [];
  List<Articulo> _articulos = [];

  List<Sucursal> _sucursales = [];

  String? _cliente;
  String? _asesor;
  String? _sucursalFactura;

  Map<String, Cliente> get _clientesPorEtiqueta =>
      etiquetasUnicas(_clientes, (c) => c.nombre, (c) => c.contacto ?? '');
  Map<String, ({int id, String nombre})> get _asesoresPorEtiqueta =>
      etiquetasUnicas(_asesores, (a) => a.nombre);
  Map<String, Sucursal> get _sucursalesPorSigla => {
    for (final s in _sucursales.where((s) => s.sigla.isNotEmpty))
      '${s.sigla} · ${s.nombre}': s,
  };

  String? get _facturaCompleta {
    final suc = _sucursalesPorSigla[_sucursalFactura];
    final num = _numeroFactura.text.trim();
    if (suc == null || num.isEmpty) return null;
    return '${suc.sigla}-$num';
  }
  bool _urgente = false;
  bool _cargando = true;
  bool _guardando = false;

  bool get _esEdicion => widget.editar != null;

  @override
  void initState() {
    super.initState();
    _numeroFactura.addListener(() => setState(() {}));
    _cargarOpciones();
  }

  @override
  void dispose() {
    _numeroFactura.dispose();
    _notaPlanta.dispose();
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
      final sucursales = await SucursalService().listar();
      if (!mounted) return;
      setState(() {
        _clientes = clientes;
        _asesores = asesores;
        _articulos = articulos;
        _sucursales = sucursales;
      });
      if (_esEdicion) _precargar();
    } catch (e) {
      _mensaje('No se pudieron cargar los datos: ${mensajeDeError(e)}');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Llena el formulario con los datos del pedido que se edita.
  void _precargar() {
    final p = widget.editar!;
    String? etiquetaCliente;
    for (final e in _clientesPorEtiqueta.entries) {
      if (e.value.idCliente == p.idCliente) etiquetaCliente = e.key;
    }
    String? etiquetaAsesor;
    for (final e in _asesoresPorEtiqueta.entries) {
      if (e.value.id == p.idAsesor) etiquetaAsesor = e.key;
    }

    // Factura = SIGLA-NÚMERO. Si es un dato antiguo sin ese formato, se deja vacío.
    String? etiquetaSucursal;
    var numero = '';
    final doc = p.documentoErp ?? '';
    final guion = doc.indexOf('-');
    if (guion > 0) {
      final sigla = doc.substring(0, guion);
      numero = doc.substring(guion + 1);
      for (final e in _sucursalesPorSigla.entries) {
        if (e.value.sigla == sigla) etiquetaSucursal = e.key;
      }
    }

    final lineas = <_LineaForm>[];
    for (final l in p.lineas) {
      final f = _LineaForm();
      for (final a in _articulos) {
        if (a.codigoArticulo == l.codigoArticulo) f.articulo = a;
      }
      f.cantidad.text = l.cantidad.toString();
      lineas.add(f);
    }

    setState(() {
      _cliente = etiquetaCliente;
      _asesor = etiquetaAsesor;
      _sucursalFactura = etiquetaSucursal;
      _numeroFactura.text = numero;
      _urgente = p.urgente;
      if (lineas.isNotEmpty) {
        for (final l in _lineas) {
          l.dispose();
        }
        _lineas
          ..clear()
          ..addAll(lineas);
      }
    });
  }

  /// Corre la verificación de asignación sin que nadie tenga que pulsar nada.
  /// Si falla, el pedido queda Pendiente y se puede verificar desde Seguimiento.
  Future<String> _verificarAuto(int idPedido, {String nota = ''}) async {
    try {
      // Se consulta antes de aplicar para saber qué material no está asignado.
      var faltantes = <VerificacionLinea>[];
      try {
        final lineas = await _servicio.verificarAsignacion(idPedido);
        faltantes = lineas.where((l) => l.estado == 'sin_asignar').toList();
      } catch (_) {}

      final r = await _servicio.aplicarVerificacion(idPedido);

      if (r == 'solicitud') {
        // Planta recibe, como comentarios, qué material se necesita y la nota.
        try {
          final sol = SolicitudService();
          final lista = await sol.delPedido(idPedido);
          final pendientes = lista.where((x) => x.estado == 'pendiente');
          if (pendientes.isNotEmpty) {
            final idOrden = pendientes.first.idOrden;
            final textos = <String>[
              for (final l in faltantes)
                'Se necesitan ${l.cantidad > l.asignado ? l.cantidad - l.asignado : l.cantidad} cajas de ${l.codigo} (${l.descripcion}). Asignado: ${l.asignado}, disponible: ${l.disponible}.',
              if (nota.trim().isNotEmpty) nota.trim(),
            ];
            for (final t in textos) {
              await sol.comentar(idOrden, t.length > 500 ? t.substring(0, 500) : t);
            }
          }
        } catch (_) {}
      }
      return switch (r) {
        'solicitud' => 'Pedido registrado. Solicitud enviada a Planta',
        'en_pausa' => 'Pedido registrado. Quedó En Pausa por falta de material',
        _ => 'Pedido registrado y aprobado. Listo para cargar',
      };
    } catch (_) {
      return 'Pedido registrado. No se pudo verificar la asignación; hazlo desde Seguimiento';
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
    if (_sucursalFactura == null) {
      _mensaje('Selecciona la sucursal de la factura');
      return;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(_numeroFactura.text.trim())) {
      _mensaje('Escribe el número de factura (solo dígitos)');
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
      if (_esEdicion) {
        await _servicio.editar(
          idPedido: widget.editar!.idPedido,
          idCliente: _clientesPorEtiqueta[_cliente]!.idCliente,
          idAsesor: _asesoresPorEtiqueta[_asesor]!.id,
          documentoErp: _facturaCompleta!,
          urgente: _urgente,
          lineas: lineas,
        );
        await _verificarAuto(widget.editar!.idPedido);
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      }
      final r = await _servicio.crear(
        idCliente: _clientesPorEtiqueta[_cliente]!.idCliente,
        idAsesor: _asesoresPorEtiqueta[_asesor]!.id,
        documentoErp: _facturaCompleta!,
        urgente: _urgente,
        lineas: lineas,
      );
      final aviso = await _verificarAuto(r.idPedido, nota: _notaPlanta.text);
      if (!mounted) return;
      _mensaje(aviso);
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
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: _esEdicion ? 'Pedido ${widget.editar!.folio}' : 'Gerente de Compras',
            title: _esEdicion ? 'Editar Pedido' : 'Registrar Pedido',
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
                AppSelectField(
                  label: 'Sucursal de la factura',
                  hint: 'Seleccionar sucursal',
                  options: _sucursalesPorSigla.keys.toList(),
                  value: _sucursalFactura,
                  onSelected: (v) => setState(() => _sucursalFactura = v),
                  emptyMessage:
                  'Aún no hay sucursales con siglas. El Gerente General debe registrarlas en Catálogos.',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Número de factura',
                  hint: 'Solo el número, sin las siglas',
                  controller: _numeroFactura,
                  keyboardType: TextInputType.number,
                ),
                if (_facturaCompleta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Factura: $_facturaCompleta',
                        style: const TextStyle(
                            color: AppColors.azul,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
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
                if (!_esEdicion) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Nota para Planta (opcional)',
                    hint: 'Se envía con la solicitud si falta material asignado',
                    controller: _notaPlanta,
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                    'El folio se genera automáticamente al guardar.',
                    style:
                    TextStyle(color: AppColors.gris, fontSize: 12)),
                const SizedBox(height: 14),
                PrimaryButton(
                  text: _guardando
                      ? 'Guardando...'
                      : (_esEdicion ? 'Guardar cambios' : 'Guardar pedido'),
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