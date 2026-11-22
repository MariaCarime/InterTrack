import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

class PanelGeneralScreen extends StatelessWidget {
  const PanelGeneralScreen({super.key});

  void _abrir(BuildContext context, String? ruta) {
    if (ruta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponible próximamente')));
      return;
    }
    Navigator.pushNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: reemplazar con métricas reales de Supabase.
    const pedidosMes = 0, urgentes = 0, rechazos = 0;

    // Cuando existan las pantallas, cambia null por su ruta.
    final opciones = <(String, String?)>[
      ('Gestión de usuarios y roles', '/usuarios'),
      ('Catálogo de clientes', '/clientes'),
      ('Editar información de pedidos', '/reportes'),
      ('Editar información de stock', '/stock'),
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
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Row(
                  children: [
                    Expanded(
                        child: _Metrica(
                            valor: pedidosMes,
                            etiqueta: 'Pedidos/mes',
                            color: AppColors.azul)),
                    SizedBox(width: 10),
                    Expanded(
                        child: _Metrica(
                            valor: urgentes,
                            etiqueta: 'Urgentes',
                            color: AppColors.azul)),
                    SizedBox(width: 10),
                    Expanded(
                        child: _Metrica(
                            valor: rechazos,
                            etiqueta: 'Rechazos',
                            color: AppColors.rojo)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Métricas por sucursal',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const EmptyStateCard(
                  title: 'Sin actividad registrada',
                  message:
                  'Las métricas por sucursal aparecerán cuando haya pedidos.',
                ),
                const SizedBox(height: 20),
                for (final o in opciones)
                  _OpcionMenu(
                      texto: o.$1, onTap: () => _abrir(context, o.$2)),
              ],
            ),
          ),
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