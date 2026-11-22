import 'package:intertrack_app/models/auth_service.dart'; // aquí vive `supabase`
import 'package:intertrack_app/models/sucursal.dart';

class SucursalService {
  Future<List<Sucursal>> listar() async {
    final datos = await supabase.from('sucursal').select().order('nombre');
    return datos.map<Sucursal>((j) => Sucursal.fromJson(j)).toList();
  }

  Future<void> crear(String nombre, String zona) async {
    await supabase.from('sucursal').insert({'nombre': nombre, 'zona': zona});
  }

  Future<void> actualizar(int idSucursal, String nombre, String zona) async {
    await supabase
        .from('sucursal')
        .update({'nombre': nombre, 'zona': zona}).eq('id_sucursal', idSucursal);
  }
}