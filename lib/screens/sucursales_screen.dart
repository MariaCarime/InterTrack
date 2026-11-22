import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/permisos.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/sucursal.dart';
import 'package:intertrack_app/models/sucursal_service.dart';
import 'package:intertrack_app/widgets.dart';

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key});

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  final _servicio = SucursalService();
  List<Sucursal> _sucursales = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _servicio.listar();
      if (mounted) setState(() => _sucursales = datos);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrir([Sucursal? editar]) async {
    final existentes = _sucursales
        .where((s) => s.idSucursal != editar?.idSucursal)
        .map((s) => s.nombre.trim().toLowerCase())
        .toList();

    final siglas = _sucursales
        .where((s) => s.idSucursal != editar?.idSucursal)
        .map((s) => s.sigla.toUpperCase())
        .toList();

    final r = await showDialog<(String, String, String)>(
      context: context,
      builder: (_) => _SucursalDialog(
          editar: editar, existentes: existentes, siglasExistentes: siglas),
    );
    if (r == null) return;

    try {
      if (editar == null) {
        await _servicio.crear(r.$1, r.$2, r.$3);
      } else {
        await _servicio.actualizar(editar.idSucursal, r.$1, r.$2, r.$3);
      }
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: ${mensajeDeError(e)}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Rol: Gerente General',
            title: 'Sucursales',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    EmptyStateCard(
                        title: 'No se pudieron cargar las sucursales',
                        message: _error!)
                  else if (_sucursales.isEmpty)
                      const EmptyStateCard(
                        title: 'No hay sucursales registradas',
                        message:
                        'Registra la primera sucursal para poder asignarla a usuarios y pedidos.',
                      )
                    else
                      for (final s in _sucursales)
                        _SucursalTile(s,
                            onTap: puedeEditarCatalogos() ? () => _abrir(s) : () {}),
                  const SizedBox(height: 16),
                  if (puedeEditarCatalogos())
                    PrimaryButton(
                        text: '+ Registrar nueva sucursal',
                        onPressed: () => _abrir()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SucursalTile extends StatelessWidget {
  final Sucursal s;
  final VoidCallback onTap;
  const _SucursalTile(this.s, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.sigla.isEmpty ? s.nombre : '${s.sigla} · ${s.nombre}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      if (s.zona.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Zona ${s.zona}',
                            style: const TextStyle(
                                color: AppColors.gris, fontSize: 13)),
                      ],
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

/// Pantallas 25 (Agregar sucursal) y 26 (Editar sucursal).
class _SucursalDialog extends StatefulWidget {
  final Sucursal? editar;
  final List<String> existentes;
  final List<String> siglasExistentes;
  const _SucursalDialog(
      {this.editar, required this.existentes, required this.siglasExistentes});

  @override
  State<_SucursalDialog> createState() => _SucursalDialogState();
}

class _SucursalDialogState extends State<_SucursalDialog> {
  late final TextEditingController _nombre =
  TextEditingController(text: widget.editar?.nombre);
  late final TextEditingController _zona =
  TextEditingController(text: widget.editar?.zona);
  late final TextEditingController _sigla =
  TextEditingController(text: widget.editar?.sigla);
  String? _error;

  bool get _esEdicion => widget.editar != null;

  @override
  void dispose() {
    _nombre.dispose();
    _zona.dispose();
    _sigla.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe el nombre de la sucursal');
      return;
    }
    if (widget.existentes.contains(nombre.toLowerCase())) {
      setState(() => _error = 'Ya existe una sucursal con ese nombre');
      return;
    }
    final sigla = _sigla.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{2,6}$').hasMatch(sigla)) {
      setState(() => _error = 'Las siglas son de 2 a 6 letras o números, sin espacios');
      return;
    }
    if (widget.siglasExistentes.contains(sigla)) {
      setState(() => _error = 'Esas siglas ya las usa otra sucursal');
      return;
    }
    Navigator.pop(context, (nombre, _zona.text.trim(), sigla));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.blanco,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_esEdicion ? 'Editar sucursal' : 'Agregar sucursal',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Nombre',
                hint: 'Nombre de la sucursal',
                controller: _nombre),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!,
                  style: const TextStyle(color: AppColors.rojo, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            AppTextField(
                label: 'Siglas',
                hint: 'Ej. CRCR (van al inicio de la factura)',
                controller: _sigla),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Zona',
                hint: 'Ej. Norte, Centro, Sur',
                controller: _zona),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grisClaro,
                        foregroundColor: AppColors.texto,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azul,
                        foregroundColor: AppColors.blanco,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      child: Text(_esEdicion ? 'Guardar cambios' : 'Guardar'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}