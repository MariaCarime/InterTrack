import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/screens/seguimiento_pedido_screen.dart';

class PedidoResumen {
  final String folio;
  final String cliente;
  final int estado; // índice en kEstadosPedido; -1 = cancelado
  const PedidoResumen(this.folio, this.cliente, this.estado);
}

class VistaAsesorScreen extends StatelessWidget {
  const VistaAsesorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: cargar SOLO los pedidos donde pedido.id_usuario sea el asesor
    // que inició sesión (RLS en Supabase). Horario permitido: 9:00 a 20:00.
    const pedidos = <PedidoResumen>[];

    return Scaffold(
      body: Column(
        children: [
          const BlueHeader(
            subtitle: 'Rol: Asesor · Solo consulta',
            title: 'Mis Pedidos',
            trailing: CerrarSesionLink(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Solo puedes consultar el estado, no editar.',
                    style: TextStyle(color: AppColors.gris, fontSize: 13)),
                const SizedBox(height: 12),
                if (pedidos.isEmpty)
                  const EmptyStateCard(
                    title: 'Aún no tienes pedidos',
                    message:
                    'Cuando el Gerente de Compras registre un pedido tuyo, podrás seguir su estado aquí.',
                  )
                else
                  for (final p in pedidos) _PedidoTile(p),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoTile extends StatelessWidget {
  final PedidoResumen p;
  const _PedidoTile(this.p);

  @override
  Widget build(BuildContext context) {
    final estado = p.estado < 0 ? 'Cancelado' : kEstadosPedido[p.estado];
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

              ),
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
                      Text(estado,
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