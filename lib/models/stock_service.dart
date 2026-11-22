import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/stock.dart';

class StockService {
  Future<List<MaterialStock>> bajoReorden() async {
    final r = await supabase.rpc('materiales_bajo_reorden');
    return (r as List)
        .map((j) => MaterialStock.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<bool> hayMateriales() async {
    final r = await supabase.from('material').select('codigo_articulo').limit(1);
    return r.isNotEmpty;
  }

  /// Devuelve 'orden' (nació aprobada) o 'solicitud' (queda pendiente de Planta)
  Future<String> crearOrden(String codigo) async {
    final r = await supabase.rpc('crear_orden_stock', params: {'p_codigo': codigo});
    return r as String;
  }
}