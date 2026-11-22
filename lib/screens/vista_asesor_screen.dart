import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/pedido.dart';
import 'package:intertrack_app/models/pedido_service.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/screens/seguimiento_pedido_screen.dart';

class VistaAsesorScreen extends StatefulWidget {
  const VistaAsesorScreen({super.key});

  @override
  State<VistaAsesorScreen> createState() => _VistaAsesorScreenState();
}

class _VistaAsesorScreenState extends State<VistaAsesorScreen> {
  final _servicio = PedidoService();
  List<Pedido> _pedidos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Supabase (RLS) solo devuelve los pedidos donde el asesor es el responsable.
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await _servicio.listar(limite: 200);
      if (mounted) setState(() => _pedidos = datos);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BlueHeader(
            subtitle: 'Rol: Asesor · Solo consulta',
            title: 'Mis Pedidos',
            trailing: CerrarSesionLink(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Solo puedes consultar el estado, no editar.',
                      style: TextStyle(color: AppColors.gris, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    EmptyStateCard(
                        title: 'No se pudieron cargar tus pedidos',
                        message: _error!)
                  else if (_pedidos.isEmpty)
                      const EmptyStateCard(
                        title: 'Aún no tienes pedidos',
                        message:
                        'Cuando el Gerente de Compras registre un pedido tuyo, podrás seguir su estado aquí.',
                      )
                    else
                      for (final p in _pedidos) _PedidoTile(p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoTile extends StatelessWidget {
  final Pedido p;
  const _PedidoTile(this.p);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeguimientoPedidoScreen(
                  idPedido: p.idPedido, soloLectura: true),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 6),
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
    );
  }
}