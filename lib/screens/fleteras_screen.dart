import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

class Fletera {
  String nombre;
  String contacto;
  String tipo; // 'Propia' | 'Externa'
  bool activo;
  Fletera(this.nombre, this.contacto, this.tipo, {this.activo = true});
}

class FleterasScreen extends StatefulWidget {
  const FleterasScreen({super.key});

  @override
  State<FleterasScreen> createState() => _FleterasScreenState();
}

class _FleterasScreenState extends State<FleterasScreen> {
  // TODO: cargar desde Supabase (tabla fletera).
  final List<Fletera> _fleteras = [];
  int _filtro = 0; // 0 todas, 1 activas, 2 inactivas

  List<Fletera> get _visibles => _fleteras.where((f) {
    if (_filtro == 1) return f.activo;
    if (_filtro == 2) return !f.activo;
    return true;
  }).toList();

  Future<void> _abrir([Fletera? editar]) async {
    final existentes = _fleteras
        .where((f) => f != editar)
        .map((f) => f.nombre.trim().toLowerCase())
        .toList();

    final r = await showDialog<(String, String, String, bool)>(
      context: context,
      builder: (_) => _FleteraDialog(editar: editar, existentes: existentes),
    );
    if (r == null) return;

    // TODO: insertar o actualizar en Supabase. Las fleteras no se eliminan:
    // se desactivan, y una fletera inactiva no aparece al armar camiones.
    setState(() {
      if (editar == null) {
        _fleteras.add(Fletera(r.$1, r.$2, r.$3));
      } else {
        editar.nombre = r.$1;
        editar.contacto = r.$2;
        editar.tipo = r.$3;
        editar.activo = r.$4;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lista = _visibles;
    return Scaffold(
      body: Column(
        children: [
          BlueHeader(
            onBack: () => Navigator.pop(context),
            subtitle: 'Empresas de transporte',
            title: 'Fleteras',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      PillChip(
                        label: const ['Todas', 'Activas', 'Inactivas'][i],
                        selected: _filtro == i,
                        onTap: () => setState(() => _filtro = i),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                if (lista.isEmpty)
                  EmptyStateCard(
                    title: _fleteras.isEmpty
                        ? 'No hay fleteras registradas'
                        : 'Sin resultados',
                    message: _fleteras.isEmpty
                        ? 'Agrega la primera fletera para poder asignarla a un camión.'
                        : 'No hay fleteras con ese filtro.',
                  )
                else
                  for (final f in lista) _FleteraCard(f, onTap: () => _abrir(f)),
                const SizedBox(height: 16),
                PrimaryButton(
                    text: '+ Agregar fletera', onPressed: () => _abrir()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FleteraCard extends StatelessWidget {
  final Fletera f;
  final VoidCallback onTap;
  const _FleteraCard(this.f, {required this.onTap});

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
                      Text(f.nombre,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          f.contacto.isEmpty
                              ? f.tipo
                              : '${f.tipo} · ${f.contacto}',
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                    f.activo ? AppColors.azulPalido : AppColors.rojoClaro,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f.activo ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: f.activo ? AppColors.verde : AppColors.rojo)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantallas 14 (Agregar fletera) y 14b (Editar fletera).
class _FleteraDialog extends StatefulWidget {
  final Fletera? editar;
  final List<String> existentes;
  const _FleteraDialog({this.editar, required this.existentes});

  @override
  State<_FleteraDialog> createState() => _FleteraDialogState();
}

class _FleteraDialogState extends State<_FleteraDialog> {
  late final TextEditingController _nombre =
  TextEditingController(text: widget.editar?.nombre);
  late final TextEditingController _contacto =
  TextEditingController(text: widget.editar?.contacto);
  late String _tipo = widget.editar?.tipo ?? 'Propia';
  late bool _activo = widget.editar?.activo ?? true;
  String? _error;

  bool get _esEdicion => widget.editar != null;

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe el nombre de la empresa');
      return;
    }
    if (widget.existentes.contains(nombre.toLowerCase())) {
      setState(() => _error = 'Ya existe una fletera con ese nombre');
      return;
    }
    Navigator.pop(context, (nombre, _contacto.text.trim(), _tipo, _activo));
  }

  Widget _chipTipo(String t) {
    final sel = _tipo == t;
    return GestureDetector(
      onTap: () => setState(() => _tipo = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: sel ? AppColors.azul : AppColors.grisClaro,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: sel ? AppColors.blanco : AppColors.texto)),
      ),
    );
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
            Text(_esEdicion ? 'Editar fletera' : 'Agregar fletera',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Nombre',
                hint: 'Nombre de la empresa',
                controller: _nombre),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!,
                  style: const TextStyle(color: AppColors.rojo, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            AppTextField(
                label: 'Contacto',
                hint: 'Teléfono',
                controller: _contacto,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            Row(children: [
              _chipTipo('Propia'),
              const SizedBox(width: 10),
              _chipTipo('Externa'),
            ]),
            if (_esEdicion) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Fletera activa',
                            style: TextStyle(fontSize: 14))),
                    Switch(
                      value: _activo,
                      onChanged: (v) => setState(() => _activo = v),
                      thumbColor:
                      const WidgetStatePropertyAll(AppColors.blanco),
                      trackColor: WidgetStateProperty.resolveWith((s) =>
                      s.contains(WidgetState.selected)
                          ? AppColors.azul
                          : AppColors.borde),
                      trackOutlineColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                    ),
                  ],
                ),
              ),
            ],
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