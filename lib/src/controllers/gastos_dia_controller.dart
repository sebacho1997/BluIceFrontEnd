import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
class GastosDiaController {
  //final String baseUrl = "http://localhost:3000/gastos";

  Future<List<dynamic>> getGastos(conductorId) async {
    final res = await http.get(Uri.parse("$baseUrl/gastos?id_conductor=$conductorId"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error al obtener gastos");
    }
  }

  Future<List<dynamic>> listarHoy(int conductorId) async {
  final res = await http.get(Uri.parse("$baseUrl/gastos/hoy?id_conductor=$conductorId"));
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Error al obtener gastos");
  }
}

  Future<Map<String, dynamic>> createGasto(Map<String, dynamic> gasto) async {
    final res = await http.post(
      Uri.parse("$baseUrl/gastos"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(gasto),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error al crear gasto");
    }
  }

  Future<Map<String, dynamic>> updateGasto(int id, Map<String, dynamic> gasto) async {
    final res = await http.put(
      Uri.parse("$baseUrl/gastos/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(gasto),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Error al actualizar gasto");
    }
  }

  Future<void> deleteGasto(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl/gastos/$id"));
    if (res.statusCode != 200) {
      throw Exception("Error al eliminar gasto");
    }
  }
}
