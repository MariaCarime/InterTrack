import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

const double kLimiteToneladas = 35;

class PedidoAprobado {
  final String folio;
  final String cliente;
  final int cajas;
  final double pesoCaja; // kg
  const PedidoAprobado(this.folio, this.cliente, this.cajas, this.pesoCaja);

  /// toneladas = cantidad × peso_caja ÷ 1000
  double get toneladas => cajas * pesoCaja / 1000;
}

class ArmadoCamionScreen extends StatefulWidget {
  const ArmadoCamionScreen({super.key});

  @override
  State<ArmadoCamionScreen> createState() => _ArmadoCamionScreenState();
}

class _ArmadoCamionScreenState extends State<ArmadoCamionScreen> {
  // TODO: cargar desde Supabase (pedidos "Aprobado / Listo para Cargar",
  // fleteras activas y sucursales destino).
  final List<PedidoAprobado> _pedidos = [];
  final List<String> _fleteras = [];
  final List<String> _cedis = [];

  final Set<String> _seleccion = {};
  String? _fletera;
  String? _destino;
  bool _verificadas = false;

  double get _toneladas => _pedidos
      .where((p) => _seleccion.contains(p.folio))
      .fold(0.0, (suma, p) => suma + p.toneladas);

  bool get _excede => _toneladas > kLimiteToneladas;
  bool get _pasoCorte => DateTime.now().hour >= 15; // RF-027: corte 3:00 PM

  bool get _puedeGenerar =>
      !_pasoCorte &&
          !_excede &&
          _seleccion.isNotEmpty &&
          _fletera != null &&
          _destino != null &&
          _verificadas;

  void _generar() {
    // TODO: insertar camion + camion_detalle_pedido, generar el PDF Trip,
    // guardarlo en el bucket 'trips' y pasar los pedidos a "En Ruta / Trip Creado".
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Trip generado')));
  }

  @override
  Widget build(BuildContext context) {
    final t = _toneladas;
    final colorTon = _excede ? AppColors.rojo : AppColors.azul;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: Column(
        children: [
          const BlueHeader(
              subtitle: 'Pre-Armado de Trip', title: 'Armado de Camión'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Capacidad
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Capacidad del camión',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text('${t.toStringAsFixed(1)} / 35 ton',
                              style: TextStyle(
                                  color: colorTon,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (t / kLimiteToneladas).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.fondo,
                          valueColor: AlwaysStoppedAnimation(colorTon),
                        ),
                      ),
                      if (_seleccion.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Peso = cajas × peso_caja ÷ 1000',
                              style: TextStyle(
                                  color: AppColors.gris, fontSize: 12)),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              'Disponible: 35 − ${t.toStringAsFixed(1)} = ${(kLimiteToneladas - t).toStringAsFixed(1)} ton',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ],
                      if (_excede) ...[
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Excede el límite de 35 ton por camión.',
                              style: TextStyle(
                                  color: AppColors.rojo, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Aviso de corte
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.naranjaClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                      'Corte de carga: 3:00 PM. Después de esa hora no se puede subir material.',
                      style: TextStyle(
                          color: AppColors.naranjaOscuro, fontSize: 12)),
                ),
                const SizedBox(height: 20),

                const Text('Pedidos aprobados disponibles',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_pedidos.isEmpty)
                  const EmptyStateCard(
                    title: 'No hay pedidos aprobados',
                    message:
                    'Los pedidos listos para cargar aparecerán aquí.',
                  )
                else
                  for (final p in _pedidos) _filaPedido(p),
                const SizedBox(height: 20),

                // Fletera y destino
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppSelectField(
                        label: 'Fletera asignada',
                        hint: 'Seleccionar fletera',
                        options: _fleteras,
                        value: _fletera,
                        onSelected: (v) => setState(() => _fletera = v),
                        emptyMessage: 'Aún no hay fleteras registradas.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppSelectField(
                        label: 'Destino (CEDIS)',
                        hint: 'Seleccionar CEDIS',
                        options: _cedis,
                        value: _destino,
                        onSelected: (v) => setState(() => _destino = v),
                        emptyMessage: 'Aún no hay sucursales registradas.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Verificación
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blanco,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _verificadas,
                        activeColor: AppColors.azul,
                        side: const BorderSide(color: AppColors.borde),
                        onChanged: (v) =>
                            setState(() => _verificadas = v ?? false),
                      ),
                      const Expanded(
                        child: Text('Existencias verificadas antes de la salida',
                            style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  text: 'Generar Trip / Previo (PDF)',
                  onPressed: _puedeGenerar ? _generar : null,
                ),
                if (_pasoCorte) ...[
                  const SizedBox(height: 8),
                  const Text('Ya pasó el corte de las 3:00 PM.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.rojo, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _kg(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  Widget _filaPedido(PedidoAprobado p) {
    final marcado = _seleccion.contains(p.folio);
    // Si al agregarlo se pasa de 35 ton, queda como excedente para otro camión.
    final excedente =
        !marcado && (_toneladas + p.toneladas > kLimiteToneladas);
    final borde = excedente
        ? AppColors.rojo
        : (marcado ? AppColors.azul : AppColors.borde);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borde),
      ),
      child: Row(
        children: [
          Checkbox(
            value: marcado,
            activeColor: AppColors.azul,
            side: BorderSide(color: borde),
            onChanged: excedente
                ? null
                : (v) => setState(() {
              if (v == true) {
                _seleccion.add(p.folio);
              } else {
                _seleccion.remove(p.folio);
              }
            }),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.folio,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    excedente
                        ? '${p.cajas} × ${_kg(p.pesoCaja)} kg = ${p.toneladas.toStringAsFixed(1)} ton → excedente a otro camión'
                        : '${p.cajas} cajas × ${_kg(p.pesoCaja)} kg = ${p.toneladas.toStringAsFixed(1)} ton',
                    style: TextStyle(
                        color: excedente ? AppColors.rojo : AppColors.gris,
                        fontWeight:
                        excedente ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}