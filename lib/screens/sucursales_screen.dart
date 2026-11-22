import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

class Sucursal {
  String nombre;
  String zona;
  Sucursal(this.nombre, this.zona);
}

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key});

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  // TODO: cargar desde Supabase (tabla sucursal).
  final List<Sucursal> _sucursales = [];

  Future<void> _abrir([Sucursal? editar]) async {
    final existentes = _sucursales
        .where((s) => s != editar)
        .map((s) => s.nombre.trim().toLowerCase())
        .toList();

    final r = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _SucursalDialog(editar: editar, existentes: existentes),
    );
    if (r == null) return;

    // TODO: insertar o actualizar en Supabase.
    setState(() {
      if (editar == null) {
        _sucursales.add(Sucursal(r.$1, r.$2));
      } else {
        editar.nombre = r.$1;
        editar.zona = r.$2;
      }
    });
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
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_sucursales.isEmpty)
                  const EmptyStateCard(
                    title: 'No hay sucursales registradas',
                    message:
                    'Registra la primera sucursal para poder asignarla a usuarios y pedidos.',
                  )
                else
                  for (final s in _sucursales)
                    _SucursalTile(s, onTap: () => _abrir(s)),
                const SizedBox(height: 16),
                PrimaryButton(
                    text: '+ Registrar nueva sucursal',
                    onPressed: () => _abrir()),
              ],
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
                      Text(s.nombre,
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
  const _SucursalDialog({this.editar, required this.existentes});

  @override
  State<_SucursalDialog> createState() => _SucursalDialogState();
}

class _SucursalDialogState extends State<_SucursalDialog> {
  late final TextEditingController _nombre =
  TextEditingController(text: widget.editar?.nombre);
  late final TextEditingController _zona =
  TextEditingController(text: widget.editar?.zona);
  String? _error;

  bool get _esEdicion => widget.editar != null;

  @override
  void dispose() {
    _nombre.dispose();
    _zona.dispose();
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
    Navigator.pop(context, (nombre, _zona.text.trim()));
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