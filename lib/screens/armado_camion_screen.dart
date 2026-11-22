import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/widgets_camiones.dart';
import 'package:intertrack_app/models/camion.dart';
import 'package:intertrack_app/models/camion_service.dart';
import 'package:intertrack_app/models/fletera.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/sucursal.dart';
import 'package:intertrack_app/models/trip_pdf.dart';
import 'package:intertrack_app/screens/documento_trip_screen.dart';

/// Regla RF-027: después de las 2:00 PM no se puede subir material.
/// Pon false SOLO para probar fuera de horario y vuelve a dejarlo en true.
const bool kAplicarCorte = true;

class _Asignacion {
  final LineaPorCargar linea;
  final int cajas;
  const _Asignacion(this.linea, this.cajas);
}

class ArmadoCamionScreen extends StatefulWidget {
  const ArmadoCamionScreen({super.key});

  @override
  State<ArmadoCamionScreen> createState() => _ArmadoCamionScreenState();
}

class _ArmadoCamionScreenState extends State<ArmadoCamionScreen> {
  final _servicio = CamionService();

  List<LineaPorCargar> _lineas = [];
  List<Fletera> _fleteras = [];
  List<Sucursal> _sucursales = [];
  bool _cargando = true;
  String? _error;
  bool _generando = false;

  final List<int> _seleccion = []; // ids de pedido, en el orden en que se marcaron
  String? _fletera;
  String? _destino;
  bool _verificadas = false;

  @override
  void initState() {
    super.initState();
    _cargar();
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
      final lineas = await _servicio.lineasPorCargar();
      final fleteras = await _servicio.fleterasActivas();
      final sucursales = await _servicio.sucursales();
      if (!mounted) return;
      setState(() {
        _lineas = lineas;
        _fleteras = fleteras;
        _sucursales = sucursales;
        _seleccion.removeWhere((id) => !lineas.any((l) => l.idPedido == id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Pedidos con cajas por cargar (la base ya los manda con los urgentes primero).
  Map<int, List<LineaPorCargar>> get _porPedido {
    final m = <int, List<LineaPorCargar>>{};
    for (final l in _lineas) {
      m.putIfAbsent(l.idPedido, () => []).add(l);
    }
    return m;
  }

  /// Reparte los pedidos en parrillas completas sin llegar al límite de 34.5 ton.
  ({List<_Asignacion> asignadas, double toneladas}) _calcular(List<int> pedidos) {
    final porPedido = _porPedido;
    final out = <_Asignacion>[];
    var usadas = 0.0;
    for (final id in pedidos) {
      for (final l in porPedido[id] ?? const <LineaPorCargar>[]) {
        final cajas = l.cajasQueCaben(kLimiteToneladas - usadas);
        if (cajas > 0) {
          out.add(_Asignacion(l, cajas));
          usadas += l.toneladas(cajas);
        }
      }
    }
    return (asignadas: out, toneladas: usadas);
  }

  String _etiquetaFletera(Fletera f) => f.tarifaTonelada == null
      ? f.nombre
      : f.nombre + r' · $' + f.tarifaTonelada!.toStringAsFixed(2) + '/ton';

  Map<String, Fletera> get _fleterasPorEtiqueta =>
      {for (final f in _fleteras) _etiquetaFletera(f): f};

  bool get _pasoCorte => kAplicarCorte && DateTime.now().hour >= 14;

  Future<void> _generar() async {
    final calc = _calcular(_seleccion);
    if (calc.asignadas.isEmpty) return;
    final idFletera = _fleterasPorEtiqueta[_fletera]!.idFletera;

    setState(() => _generando = true);
    try {
      final idCamion = await _servicio.crear(
        idFletera: idFletera,
        shipTo: _destino!,
        lineas: calc.asignadas
            .map((a) => (idDetalle: a.linea.idDetalle, cajas: a.cajas))
            .toList(),
      );

      // El PDF se guarda en Supabase; si algo falla, el camión igual queda
      // creado y el documento se genera al momento de abrirlo.
      String? ruta;
      try {
        final datos = await _servicio.datosTrip(idCamion);
        final bytes = await construirTripPdf(datos);
        ruta = await _servicio.subirPdf(idCamion, bytes);
      } catch (_) {
        ruta = null;
      }
      await _servicio.finalizar(idCamion, ruta);

      if (!mounted) return;
      setState(() {
        _seleccion.clear();
        _verificadas = false;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DocumentoTripScreen(idCamion: idCamion)),
      );
      if (mounted) _cargar();
    } catch (e) {
      _mensaje(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = _calcular(_seleccion);
    final t = calc.toneladas;
    const colorTon = AppColors.azul;
    final puedeGenerar = !_pasoCorte &&
        !_generando &&
        calc.asignadas.isNotEmpty &&
        _fletera != null &&
        _destino != null &&
        _verificadas;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: Column(
        children: [
          const BlueHeader(
              subtitle: 'Pre-Armado de Trip', title: 'Armado de Camión'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Text('${t.toStringAsFixed(1)} / 34.5 ton',
                                style: const TextStyle(
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
                            valueColor: const AlwaysStoppedAnimation(colorTon),
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
                                'Disponible: 34.5 − ${t.toStringAsFixed(1)} = ${(kLimiteToneladas - t).toStringAsFixed(1)} ton',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
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
                        'Corte de carga: 2:00 PM. Después de esa hora no se puede subir material.',
                        style: TextStyle(
                            color: AppColors.naranjaOscuro, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),

                  const Text('Pedidos aprobados disponibles',
                      style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null) ...[
                    EmptyStateCard(
                        title: 'No se pudieron cargar los pedidos',
                        message: _error!),
                    TextButton(
                        onPressed: _cargar, child: const Text('Reintentar')),
                  ] else if (_lineas.isEmpty)
                    const EmptyStateCard(
                      title: 'No hay pedidos aprobados',
                      message: 'Los pedidos listos para cargar aparecerán aquí.',
                    )
                  else
                    for (final e in _porPedido.entries)
                      _filaPedido(e.key, e.value, calc),
                  const SizedBox(height: 20),

                  // Fletera y destino
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppSelectField(
                          label: 'Fletera asignada',
                          hint: 'Seleccionar fletera',
                          options: _fleterasPorEtiqueta.keys.toList(),
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
                          options: _sucursales.map((s) => s.nombre).toList(),
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
                          child: Text(
                              'Existencias verificadas antes de la salida',
                              style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: _generando
                        ? 'Generando...'
                        : 'Generar Trip / Previo (PDF)',
                    onPressed: puedeGenerar ? _generar : null,
                  ),
                  if (_pasoCorte) ...[
                    const SizedBox(height: 8),
                    const Text('Ya pasó el corte de las 2:00 PM.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.rojo, fontSize: 12)),
                  ],
                  const SizedBox(height: 28),
                  ListaCamiones(
                    key: ValueKey('camiones-$_generando'),
                    titulo: 'Camiones armados',
                    cargar: (s) => s.recientes(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _kg(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  Widget _filaPedido(int id, List<LineaPorCargar> lineas,
      ({List<_Asignacion> asignadas, double toneladas}) actual) {
    final primera = lineas.first;
    final marcado = _seleccion.contains(id);
    final totalCajas = lineas.fold<int>(0, (s, l) => s + l.restante);
    final totalTon =
    lineas.fold<double>(0, (s, l) => s + l.toneladas(l.restante));

    // Cuánto de este pedido cabe (con la selección actual, o sumándolo)
    final calc = marcado ? actual : _calcular([..._seleccion, id]);
    final caben = calc.asignadas
        .where((a) => a.linea.idPedido == id)
        .fold<int>(0, (s, a) => s + a.cajas);
    final noCabe = caben == 0;
    final parcial = caben > 0 && caben < totalCajas;

    final deshabilitado = !marcado && noCabe;
    final borde = (!marcado && noCabe)
        ? AppColors.rojo
        : parcial
        ? AppColors.naranja
        : (marcado ? AppColors.azul : AppColors.borde);

    String? nota;
    Color colorNota = AppColors.gris;
    if (noCabe) {
      nota = marcado ? 'No cupo en este camión' : 'No cabe en este camión';
      colorNota = AppColors.rojo;
    } else if (parcial) {
      nota = marcado
          ? 'Se cargan $caben de $totalCajas cajas; el resto pasa a otro camión'
          : 'Cabe parcial: $caben de $totalCajas cajas; el resto pasa a otro camión';
      colorNota = AppColors.naranja;
    }

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
            onChanged: deshabilitado
                ? null
                : (v) => setState(() {
              if (v == true) {
                _seleccion.add(id);
              } else {
                _seleccion.remove(id);
              }
            }),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('${primera.folio} · ${primera.cliente}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      if (primera.urgente) ...[
                        const SizedBox(width: 6),
                        const Text('Urgente',
                            style: TextStyle(
                                color: AppColors.naranja,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('$totalCajas cajas · ${totalTon.toStringAsFixed(1)} ton',
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 12)),
                  for (final l in lineas)
                    Text(
                        '• ${l.codigo}: ${l.restante} cajas × ${_kg(l.pesoCaja)} kg',
                        style: const TextStyle(
                            color: AppColors.gris, fontSize: 11)),
                  if (nota != null) ...[
                    const SizedBox(height: 4),
                    Text(nota,
                        style: TextStyle(
                            color: colorNota,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
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