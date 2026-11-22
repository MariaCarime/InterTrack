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

  /// Los camiones más recientes, para abrir su Trip o registrar la recepción.
  Future<List<CamionResumen>> recientes({int limite = 15}) async {
    final datos = await supabase
        .from('camion')
        .select('id_camion, ship_to, toneladas_totales, fecha_recepcion, fletera(nombre)')
        .order('id_camion', ascending: false)
        .limit(limite);
    return datos.map<CamionResumen>((j) => CamionResumen.fromJson(j)).toList();
  }

  /// Los camiones donde va material de un pedido.
  Future<List<CamionResumen>> deUnPedido(int idPedido) async {
    final datos = await supabase
        .from('camion_detalle_pedido')
        .select('id_camion, '
        'camion(id_camion, ship_to, toneladas_totales, fecha_recepcion, fletera(nombre)), '
        'detalle_pedido!inner(id_pedido)')
        .eq('detalle_pedido.id_pedido', idPedido);
    final vistos = <int>{};
    final lista = <CamionResumen>[];
    for (final j in datos) {
      final c = j['camion'];
      if (c is Map<String, dynamic> && vistos.add(c['id_camion'] as int)) {
        lista.add(CamionResumen.fromJson(c));
      }
    }
    lista.sort((a, b) => b.idCamion.compareTo(a.idCamion));
    return lista;
  }

  Future<DatosTrip> datosTrip(int idCamion) async {
    final dato = await supabase
        .from('camion')
        .select('id_camion, planta_origen, ship_to, toneladas_totales, ruta_pdf, '
        'tarifa_tonelada, costo_flete, numero_trip, placas, chofer, economico, sello, '
        'fecha_recepcion, '
        'fletera(nombre), '
        'camion_detalle_pedido(cantidad_asignada, '
        'detalle_pedido(codigo_articulo, lote, '
        'material(descripcion, peso_caja, cajas_por_parrilla), pedido(folio, documento_erp)))')
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

  /// Datos que lleva el Trip y que se capturan al embarcar.
  Future<void> guardarEmbarque(
      int idCamion, {
        String? numeroTrip,
        String? placas,
        String? chofer,
        String? economico,
        String? sello,
      }) async {
    String? limpio(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    await supabase.from('camion').update({
      'numero_trip': limpio(numeroTrip),
      'placas': limpio(placas),
      'chofer': limpio(chofer),
      'economico': limpio(economico),
      'sello': limpio(sello),
    }).eq('id_camion', idCamion);
  }

  /// Registra la recepción. Devuelve cuántos pedidos pasaron a Entregado.
  Future<int> recibir(int idCamion) async {
    final r = await supabase.rpc('recibir_camion', params: {'p_id_camion': idCamion});
    return (r as num).toInt();
  }

  Future<Uint8List> descargarPdf(String ruta) =>
      supabase.storage.from('trips').download(ruta);

  /// Pasa a "En Ruta / Trip Creado" los pedidos que quedaron cargados por completo.
  Future<void> finalizar(int idCamion, String? rutaPdf) async {
    await supabase.rpc('finalizar_camion',
        params: {'p_id_camion': idCamion, 'p_ruta_pdf': rutaPdf});
  }
}