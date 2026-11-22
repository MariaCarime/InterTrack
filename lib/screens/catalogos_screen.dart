import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';

class CatalogosScreen extends StatelessWidget {
  const CatalogosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const opciones = <(String, String)>[
      ('Clientes', '/clientes'),
      ('Fleteras', '/fleteras'),
      ('Sucursales', '/sucursales'),
    ];

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: Column(
        children: [
          const BlueHeader(
            subtitle: 'Información base del sistema',
            title: 'Catálogos',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final o in opciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppColors.blanco,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pushNamed(context, o.$2),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(o.$1,
                                      style: const TextStyle(fontSize: 14))),
                              const Icon(Icons.arrow_forward,
                                  color: AppColors.azul, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}