import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/models/camion.dart';
import 'package:intertrack_app/models/camion_service.dart';
import 'package:intertrack_app/models/consulta_service.dart';
import 'package:intertrack_app/screens/documento_trip_screen.dart';

/// Lista de camiones; al tocar uno se abre su Trip, donde se registra la recepción.
class ListaCamiones extends StatefulWidget {
  final String titulo;
  final Future<List<CamionResumen>> Function(CamionService) cargar;
  final String vacio;
  const ListaCamiones({
    super.key,
    required this.titulo,
    required this.cargar,
    this.vacio = 'Aún no hay camiones armados.',
  });

  @override
  State<ListaCamiones> createState() => _ListaCamionesState();
}

class _ListaCamionesState extends State<ListaCamiones> {
  final _servicio = CamionService();
  List<CamionResumen> _camiones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await widget.cargar(_servicio);
      if (mounted) setState(() => _camiones = datos);
    } catch (_) {
      // Sin permiso o sin conexión: la lista queda vacía.
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_camiones.isEmpty)
          Text(widget.vacio,
              style: const TextStyle(color: AppColors.gris, fontSize: 13))
        else
          for (final c in _camiones)
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
                          builder: (_) => DocumentoTripScreen(idCamion: c.idCamion)),
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
                              Text('Camión ${c.idCamion} · ${c.fletera}',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              Text(
                                  '${c.toneladas.toStringAsFixed(2)} ton${c.destino.isEmpty ? '' : ' · ${c.destino}'}',
                                  style: const TextStyle(
                                      color: AppColors.gris, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                  c.recibido
                                      ? 'Recibido el ${formatoFecha(c.fechaRecepcion!)}'
                                      : 'Por recibir',
                                  style: TextStyle(
                                      color: c.recibido ? AppColors.verde : AppColors.naranja,
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
      ],
    );
  }
}