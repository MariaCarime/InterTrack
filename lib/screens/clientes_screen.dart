import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/permisos.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/cliente.dart';
import 'package:intertrack_app/models/cliente_service.dart';

typedef _DatosCliente = ({String nombre, String contacto, bool activo});

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _servicio = ClienteService();
  List<Cliente> _clientes = [];
  bool _cargando = true;
  String? _error;
  int _filtro = 0; // 0 todos, 1 activos, 2 inactivos

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  List<Cliente> get _visibles => _clientes.where((c) {
    if (_filtro == 1) return c.activo;
    if (_filtro == 2) return !c.activo;
    return true;
  }).toList();

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _servicio.listar();
      if (!mounted) return;
      setState(() => _clientes = datos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _abrirFormulario([Cliente? editar]) async {
    final resultado = await showModalBottomSheet<_DatosCliente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blanco,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FormularioCliente(editar: editar),
    );
    if (resultado == null) return;

    try {
      if (editar == null) {
        await _servicio.crear(resultado.nombre, contacto: resultado.contacto);
      } else {
        await _servicio.actualizar(editar.idCliente,
            nombre: resultado.nombre,
            contacto: resultado.contacto,
            activo: resultado.activo);
      }
      await _cargar();
    } catch (_) {
      _mensaje(
          'No se pudo guardar. Solo el Gerente General puede crear o editar clientes.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _visibles;
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Rol: Gerente General',
            title: 'Clientes',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      PillChip(
                        label: const ['Todos', 'Activos', 'Inactivos'][i],
                        selected: _filtro == i,
                        onTap: () => setState(() => _filtro = i),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null) ...[
                  EmptyStateCard(
                      title: 'No se pudieron cargar los clientes',
                      message: _error!),
                  TextButton(
                      onPressed: _cargar, child: const Text('Reintentar')),
                ] else if (lista.isEmpty)
                  EmptyStateCard(
                    title: _clientes.isEmpty
                        ? 'No hay clientes registrados'
                        : 'Sin resultados',
                    message: _clientes.isEmpty
                        ? 'Registra el primer cliente para poder usarlo en los pedidos.'
                        : 'No hay clientes con ese filtro.',
                  )
                else
                  for (final c in lista)
                    _ClienteCard(c,
                        onTap: puedeEditarCatalogos() ? () => _abrirFormulario(c) : () {}),
                const SizedBox(height: 16),
                if (puedeEditarCatalogos())
                  PrimaryButton(
                      text: '+ Registrar nuevo cliente',
                      onPressed: _abrirFormulario),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final Cliente c;
  final VoidCallback onTap;
  const _ClienteCard(this.c, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final contacto = c.contacto ?? '';
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
                      Text(c.nombre,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      if (contacto.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        // Mismo estilo que el nombre.
                        Text(contacto,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                    c.activo ? AppColors.azulPalido : AppColors.rojoClaro,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.activo ? AppColors.verde : AppColors.rojo)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal "Agregar cliente" (también sirve para editar y desactivar).
class _FormularioCliente extends StatefulWidget {
  final Cliente? editar;
  const _FormularioCliente({this.editar});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  late final TextEditingController _nombre =
  TextEditingController(text: widget.editar?.nombre);
  late final TextEditingController _contacto =
  TextEditingController(text: widget.editar?.contacto ?? '');
  late bool _activo = widget.editar?.activo ?? true;

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.editar != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(editando ? 'Editar cliente' : 'Agregar cliente',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Nombre',
                hint: 'Nombre del cliente',
                controller: _nombre),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Contacto',
                hint: 'Teléfono',
                controller: _contacto,
                keyboardType: TextInputType.phone),
            if (editando) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blanco,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Cliente activo',
                            style: TextStyle(fontSize: 15))),
                    Switch(
                        value: _activo,
                        activeColor: AppColors.azul,
                        onChanged: (v) => setState(() => _activo = v)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              text: editando ? 'Guardar cambios' : 'Guardar cliente',
              onPressed: () {
                final nombre = _nombre.text.trim();
                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Escribe el nombre del cliente')));
                  return;
                }
                Navigator.pop(context, (
                nombre: nombre,
                contacto: _contacto.text.trim(),
                activo: _activo,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}