import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intertrack_app/models/auth_service.dart';
import 'package:intertrack_app/models/camion.dart';
import 'package:intertrack_app/models/fletera.dart';
import 'package:intertrack_app/models/sucursal.dart';

class CamionService {
  Future<List<LineaPorCargar>> lineasPorCargar() async {
    final r = await supabase.rpc('lineas_por_cargar');
    return (r as List)
        .map((j) => LineaPorCargar.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Fletera>> fleterasActivas() async {
    final datos =
    await supabase.from('fletera').select().eq('activo', true).order('nombre');
    return datos.map<Fletera>((j) => Fletera.fromJson(j)).toList();
  }

  Future<List<Sucursal>> sucursales() async {
    final datos = await supabase.from('sucursal').select().order('nombre');
    return datos.map<Sucursal>((j) => Sucursal.fromJson(j)).toList();
  }

  Future<int> crear({
    required int idFletera,
    required String shipTo,
    String? plantaOrigen,
    required List<({int idDetalle, int cajas})> lineas,
  }) async {
    final r = await supabase.rpc('crear_camion', params: {
      'p_id_fletera': idFletera,
      'p_ship_to': shipTo,
      'p_planta_origen': plantaOrigen,
      'p_lineas': lineas
          .map((l) => {'id_detalle': l.idDetalle, 'cajas': l.cajas})
          .toList(),
    });
    return r as int;
  }

  Future<DatosTrip> datosTrip(int idCamion) async {
    final dato = await supabase
        .from('camion')
        .select('id_camion, planta_origen, ship_to, toneladas_totales, ruta_pdf, '
        'tarifa_tonelada, costo_flete, '
        'fletera(nombre), '
        'camion_detalle_pedido(cantidad_asignada, '
        'detalle_pedido(codigo_articulo, lote, '
        'material(descripcion, peso_caja, cajas_por_parrilla), pedido(folio)))')
        .eq('id_camion', idCamion)
        .single();
    return DatosTrip.fromJson(dato);
  }

  /// Guarda el PDF en el bucket privado 'trips'. Si falla devuelve null.
  Future<String?> subirPdf(int idCamion, Uint8List bytes) async {
    try {
      final ruta = 'camion_$idCamion.pdf';
      await supabase.storage.from('trips').uploadBinary(
        ruta,
        bytes,
        fileOptions:
        const FileOptions(contentType: 'application/pdf', upsert: true),
      );
      return ruta;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> descargarPdf(String ruta) =>
      supabase.storage.from('trips').download(ruta);

  /// Pasa a "En Ruta / Trip Creado" los pedidos que quedaron cargados por completo.
  Future<void> finalizar(int idCamion, String? rutaPdf) async {
    await supabase.rpc('finalizar_camion',
        params: {'p_id_camion': idCamion, 'p_ruta_pdf': rutaPdf});
  }
}