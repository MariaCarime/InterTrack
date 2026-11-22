import 'package:flutter/material.dart';
import 'package:intertrack_app/colors.dart';
import 'package:intertrack_app/widgets.dart';
import 'package:intertrack_app/screens/seguimiento_pedido_screen.dart';

class ConfirmacionPedidoScreen extends StatelessWidget {
  final String folio;
  final int? idPedido;

  const ConfirmacionPedidoScreen(
      {super.key, this.folio = 'F-AAAA-XXXX', this.idPedido});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                        color: AppColors.verde, shape: BoxShape.circle),
                    child: const Icon(Icons.check,
                        color: AppColors.blanco, size: 36),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('¡Pedido guardado con éxito!',
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                    'Folio $folio registrado correctamente. El estado inicial es "Pendiente".',
                    style: const TextStyle(
                        color: AppColors.gris, fontSize: 14, height: 1.35)),
                const SizedBox(height: 22),
                PrimaryButton(
                  text: 'Ver detalle',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            SeguimientoPedidoScreen(idPedido: idPedido)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/registrar'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.blanco,
                      foregroundColor: AppColors.azul,
                      side: const BorderSide(color: AppColors.azul),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Crear otro pedido'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/dashboard', (_) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grisClaro,
                      foregroundColor: AppColors.texto,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Volver al inicio'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}