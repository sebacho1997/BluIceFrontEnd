import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class UserService {
  static Future<List<dynamic>?> getUserAddresses(int userId) async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/direcciones/usuario/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error al obtener direcciones: ${response.body}');
      return null;
    }
  }

  // ================= Crear dirección =================
  static Future<bool> createUserAddress(
      int userId, Map<String, dynamic> data) async {
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

  // ================= Actualizar dirección =================
  static Future<bool> updateUserAddress(
      int addressId, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/direcciones/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en updateUserAddress: $e');
      return false;
    }
  }

  // ================= Eliminar dirección =================
  static Future<bool> deleteUserAddress(int addressId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.delete(
        Uri.parse('$baseUrl/direcciones/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en deleteUserAddress: $e');
      return false;
    }
  }

  // ================= Listar users =================
  static Future<List<dynamic>?> getUsers() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error al obtener users: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error en getUsers: $e');
      return null;
    }
  }
  
 static Future<List<Map<String, dynamic>>> getUsersByType(String tipoUsuario) async {
  final response = await http.get(Uri.parse("$baseUrl/users/type/$tipoUsuario"));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception("Error al obtener usuarios de tipo $tipoUsuario");
  }
}

  // ================= Listar users por id =================
  static Future<List<dynamic>?> getUsersId(Int id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error al obtener users: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error en getUsers: $e');
      return null;
    }
  }

  // ================= Editar usuario =================
  static Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en updateUser: $e');
      return false;
    }
  }

  // ================= Eliminar usuario =================
  static Future<bool> deleteUser(String id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en deleteUser: $e');
      return false;
    }
  }

  // ================= Crear usuario =================
  static Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error en createUser: $e');
      return false;
    }
  }
}
