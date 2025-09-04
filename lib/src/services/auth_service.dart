import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  /// Login de usuario
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'contraseña': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar token para sesión persistente
        if (data.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }

        return data;
      } else {
        print('Login fallido: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  /// Signup solo para clientes
  static Future<Map<String, dynamic>?> signupCliente(
      String nombre, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'contraseña': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Guardar token para sesión persistente si viene del signup
        if (data.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }

        return data;
      } else {
        print('Signup fallido: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error en signup: $e');
      return null;
    }
  }

  /// Obtener token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
