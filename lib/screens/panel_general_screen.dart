import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/consulta_service.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/screens/seguimiento_pedido_screen.dart';
import 'package:intertrack_app/widgets.dart';

class PanelGeneralScreen extends StatefulWidget {
  const PanelGeneralScreen({super.key});

  @override
  State<PanelGeneralScreen> createState() => _PanelGeneralScreenState();
}

class _PanelGeneralScreenState extends State<PanelGeneralScreen> {
  final _servicio = ConsultaService();
  MetricasGenerales? _m;
  List<Pedido> _recientes = [];
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
      final m = await _servicio.metricas();
      final recientes = await PedidoService().listar(limite: 8);
      if (mounted) {
        setState(() {
          _m = m;
          _recientes = recientes;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrir(BuildContext context, String? ruta) {
    if (ruta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponible próximamente')));
      return;
    }
    Navigator.pushNamed(context, ruta).then((_) => _cargar());
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final opciones = <(String, String?)>[
      ('Registrar pedido', '/registrar'),
      ('Gestión de usuarios y roles', '/usuarios'),
      ('Ver historial completo y auditoría', '/historial'),
    ];

    return Scaffold(
      body: Column(
        children: [
          const BlueHeader(
            subtitle: 'Rol: Gerente General',
            title: 'Panel General',
            trailing: CerrarSesionLink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _Metrica(
                              valor: m?.pedidosMes ?? 0,
                              etiqueta: 'Pedidos/mes',
                              color: AppColors.azul)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _Metrica(
                              valor: m?.urgentes ?? 0,
                              etiqueta: 'Urgentes',
                              color: AppColors.azul)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _Metrica(
                              valor: m?.rechazos ?? 0,
                              etiqueta: 'Rechazos',
                              color: AppColors.rojo)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Métricas por sucursal',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    EmptyStateCard(
                        title: 'No se pudieron cargar las métricas',
                        message: _error!)
                  else if (m == null || m.porSucursal.isEmpty)
                      const EmptyStateCard(
                        title: 'Sin actividad registrada',
                        message:
                        'Las métricas por sucursal aparecerán cuando haya pedidos este mes.',
                      )
                    else
                      for (final s in m.porSucursal) _FilaSucursal(s),
                  const SizedBox(height: 20),
                  const Text('Pedidos recientes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_recientes.isEmpty && !_cargando)
                    const EmptyStateCard(
                      title: 'No hay pedidos registrados',
                      message: 'Cuando se registre un pedido aparecerá aquí.',
                    )
                  else
                    for (final p in _recientes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: AppColors.blanco,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        SeguimientoPedidoScreen(idPedido: p.idPedido)),
                              );
                              _cargar();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.folio,
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.w700)),
                                        Text('${p.cliente} · ${p.asesor}',
                                            style: const TextStyle(
                                                color: AppColors.gris, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text(p.estado,
                                            style: const TextStyle(
                                                color: AppColors.azul,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.gris),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/reportes'),
                      child: const Text('Ver todos los pedidos'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final o in opciones)
                    _OpcionMenu(
                        texto: o.$1, onTap: () => _abrir(context, o.$2)),
                ],
              ),
            ),
          ),
        ],
      ),
      // 👇 AQUÍ VA LA BARRA INFERIOR QUE SE VE EN LA IMAGEN:
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _FilaSucursal extends StatelessWidget {
  final MetricaSucursal s;
  const _FilaSucursal(this.s);

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
            child: Text(s.sucursal,
                style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text('${s.pedidos} pedidos · ${s.urgentes} urgentes',
              style: const TextStyle(color: AppColors.gris, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final Color color;

  const _Metrica(
      {required this.valor, required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$valor',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(etiqueta,
              style: const TextStyle(color: AppColors.gris, fontSize: 12)),
        ],
      ),
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  const _OpcionMenu({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                    child: Text(texto, style: const TextStyle(fontSize: 14))),
                const Icon(Icons.arrow_forward,
                    color: AppColors.azul, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}