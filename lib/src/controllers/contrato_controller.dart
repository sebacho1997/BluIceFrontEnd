import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';

class ContratoController {
  // ===== Crear contrato =====
  static Future<bool> crearContrato(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/contratos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = json.decode(response.body);
        // Si el backend devuelve un objeto con id, asumimos que se creó
        return respData != null && respData['id'] != null;
      } else {
        print(
          'Error crearContrato: ${response.statusCode} -> ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error crearContrato: $e');
      return false;
    }
  }

  // ===== Obtener todos los contratos =====
  static Future<List<Map<String, dynamic>>?> getContratos() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/contratos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      print('Error getContratos: $e');
      return null;
    }
  }

  // ===== Registrar consumo de contrato =====
  static Future<int?> crearConsumo(
    int contratoId,
    double montoConsumido, {
    String? observaciones,
  }) async {
    try {
      final token = await AuthService.getToken();
      final body = jsonEncode({
        'contrato_id': contratoId,
        'monto_consumido': montoConsumido,
        'observaciones': observaciones ?? '',
      });

      final response = await http.post(
        Uri.parse('$baseUrl/contratos/consumos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('POST /consumos body: $body');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id']; // <--- aquí depende que backend devuelva id
      } else {
        print('Error crearConsumo: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error crearConsumo: $e');
      return null;
    }
  }

  static Future<bool> crearDetalleConsumo(
    int consumoId,
    int productoId,
    int cantidad,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/contratos/consumo-detalle"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "consumo_id": consumoId,
          "producto_id": productoId,
          "cantidad": cantidad,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.statusCode);
        return true;
      } else {
        print("❌ Error backend: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error en crearDetalleConsumo: $e");
      return false;
    }
  }
  static Future<bool> marcarEntregado(int consumoId) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final now = DateTime.now().toIso8601String();

    final response = await http.put(
      Uri.parse('$baseUrl/contratos/$consumoId/entregado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'observaciones': 'entregado',
        'fecha_entrega': now,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print(
          'Error marcarEntregado: ${response.statusCode} -> ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error marcarEntregado: $e');
    return false;
  }
}
  // ===== Obtener consumos de un contrato =====
  static Future<List<Map<String, dynamic>>?> getConsumos(int contratoId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/contratos/$contratoId/consumos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      print('Error getConsumos: $e');
      return null;
    }
  }

  static Future<bool> asignarConductor(int contratoId, int conductorId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/contratos/$contratoId/asignar-conductor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'conductor_id': conductorId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en asignarConductor: $e');
      return false;
    }
  }

  // ===== Obtener detalles de un consumo =====
  static Future<List<Map<String, dynamic>>?> getDetallesConsumo(
    int consumoId,
  ) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/consumos/detalles/$consumoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return null;
    } catch (e) {
      print('Error getDetallesConsumo: $e');
      return null;
    }
  }
}
