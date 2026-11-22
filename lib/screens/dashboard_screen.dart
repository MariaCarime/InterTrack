import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/screens/seguimiento_pedido_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _servicio = PedidoService();
  List<Pedido> _recientes = [];
  Map<String, int> _conteo = {};
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
      final conteo = await _servicio.contarPorEstado();
      final recientes = await _servicio.listar(limite: 10);
      if (!mounted) return;
      setState(() {
        _conteo = conteo;
        _recientes = recientes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirPedido(Pedido p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SeguimientoPedidoScreen(idPedido: p.idPedido)),
    );
    _cargar();
  }

  Future<void> _nuevoPedido() async {
    await Navigator.pushNamed(context, '/registrar');
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _conteo['Pendiente'] ?? 0;
    final espPlanta = _conteo['Esperando Aprobación de Planta'] ?? 0;
    final listos = _conteo['Aprobado/Listo para Cargar'] ?? 0;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: Column(
        children: [
          const BlueHeader(
            subtitle: 'Hola, Gerente de Compras',
            title: 'Panel de Pedidos',
            trailing: CerrarSesionLink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              valor: pendientes,
                              etiqueta: 'Pendientes',
                              color: AppColors.naranja)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              valor: espPlanta,
                              etiqueta: 'Esp. Planta',
                              color: AppColors.rojo)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              valor: listos,
                              etiqueta: 'Listos',
                              color: AppColors.verde)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Pedidos recientes',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  ] else if (_recientes.isEmpty)
                    const EmptyStateCard(
                      title: 'No hay pedidos registrados',
                      message:
                      'Cuando registres tu primer pedido aparecerá aquí.',
                    )
                  else
                    for (final p in _recientes)
                      _PedidoCard(p, onTap: () => _abrirPedido(p)),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: '+ Registrar nuevo pedido',
                    onPressed: _nuevoPedido,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int valor;
  final String etiqueta;
  final Color color;

  const _StatCard(
      {required this.valor, required this.etiqueta, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
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

class _PedidoCard extends StatelessWidget {
  final Pedido p;
  final VoidCallback onTap;
  const _PedidoCard(this.p, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = colorEstadoPedido(p.estado);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
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
                      const SizedBox(height: 2),
                      Text(p.cliente,
                          style: const TextStyle(
                              color: AppColors.gris, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: badge.fondo,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(p.estado,
                              style: TextStyle(
                                  color: badge.texto,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (p.urgente)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.naranjaClaro,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Text('Urgente',
                                style: TextStyle(
                                    color: AppColors.naranja,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ]),
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