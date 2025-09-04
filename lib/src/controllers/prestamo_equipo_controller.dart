import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class PrestamoEquipoController {
  final String apiUrl = "$baseUrl/prestamos";

  /// Obtener todos los préstamos de equipo
  Future<List<dynamic>> getPrestamos() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener los préstamos");
    }
  }

  /// Crear un préstamo
  Future<Map<String, dynamic>> createPrestamo({
    required int idCliente,
    required String equipo,
    required String estadoPrestamo,
    required int cantidad,
  }) async {
    print("equipo:" +
        equipo +
        " estadoPrestamo:" +
        estadoPrestamo +
        " cantidad:" +
        cantidad.toString());
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_cliente": idCliente,
        "equipo": equipo,
        "estado_entrega": estadoPrestamo,
        "cantidad": cantidad
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al crear préstamo");
    }
  }

  /// Actualizar un préstamo
    /// Actualizar un préstamo
  Future<Map<String, dynamic>> updatePrestamo({
    required int id,
    String? equipo,
    String? estadoPrestamo,
    String? estadoDevolucion,
    String? fechaDevolucion,
    required int cantidad,
  }) async {
    final Map<String, dynamic> body = {
      "cantidad": cantidad, // siempre enviado
      if (equipo != null) "equipo": equipo,
      if (estadoPrestamo != null) "estado_entrega": estadoPrestamo,
      if (estadoDevolucion != null) "estado_devolucion": estadoDevolucion,
      if (fechaDevolucion != null) "fecha_devolucion": fechaDevolucion,
      "estado_prestamo":'devuelto',
    };

    final response = await http.put(
      Uri.parse("$apiUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al actualizar préstamo");
    }
  }
  /// Eliminar un préstamo
  Future<void> deletePrestamo(int id) async {
    final response = await http.delete(Uri.parse("$apiUrl/$id"));

    if (response.statusCode != 200) {
      throw Exception("Error al eliminar préstamo");
    }
  }
}
