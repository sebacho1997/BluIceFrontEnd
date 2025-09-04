import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';
class DireccionService {
  //static const String baseUrl = "http://localhost:5000/direcciones";

  static Future<bool> createUserAddress(int userId, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/direcciones/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error en createUserAddress: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getUserAddresses(int userId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/direcciones/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error en getUserAddresses: $e');
      return [];
    }
  }

  static Future<bool> updateAddress(int id, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/direcciones/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error en updateAddress: $e');
      return false;
    }
  }

  static Future<bool> deleteAddress(int id) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/direcciones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error en deleteAddress: $e');
      return false;
    }
  }
}
