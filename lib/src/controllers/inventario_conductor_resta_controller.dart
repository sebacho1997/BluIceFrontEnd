import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class InventarioRestaController {
  // Crear inventario
  Future<Map<String, dynamic>?> crearInventario(int conductorId, List<Map<String, dynamic>> productos) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inventario-resta/inventario-resta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conductorId': conductorId,
          'productos': productos,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Error creando inventario: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error HTTP crearInventario: $e');
      return null;
    }
  }

   /// Restar productos del inventario_resta
  static Future<bool> restarInventarioPedido(int inventarioId, List<dynamic> productos) async {
    try {
      final url = Uri.parse('$baseUrl/inventario-resta/inventario-resta/restar');

      final body = jsonEncode({
        "inventarioId": inventarioId,
        "productos": productos.map((p) => {
          "producto_id": p['producto_id'],
          "cantidad": p['cantidad'],
        }).toList(),
      });

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error restando inventario: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción al restar inventario: $e');
      return false;
    }
  }

  // Verificar si existe inventario hoy
  Future<bool> existeInventarioHoy(int conductorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventario-resta/existe/$conductorId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['existe'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error HTTP existeInventarioHoy: $e');
      return false;
    }
  }

  // Obtener inventario del día
  Future<List<dynamic>> getInventarioHoy(int conductorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventario-resta/hoy/$conductorId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error HTTP getInventarioHoy: $e');
      return [];
    }
  }

  // Obtener todos los inventarios de un conductor
  Future<List<dynamic>> obtenerInventarios(int conductorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventario-resta/todos/$conductorId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error HTTP obtenerInventarios: $e');
      return [];
    }
  }

  // Obtener detalle de un inventario
  Future<List<dynamic>> obtenerDetalleInventario(int inventarioId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/inventario-resta/detalle/$inventarioId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error HTTP obtenerDetalleInventario: $e');
      return [];
    }
  }

  // Actualizar inventario y sus detalles
  Future<bool> actualizarInventario(int inventarioId, List<Map<String, dynamic>> productos) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/inventario-resta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inventarioId': inventarioId,
          'productos': productos,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error HTTP actualizarInventario: $e');
      return false;
    }
  }

  // Cerrar inventario
  Future<bool> cerrarInventario(int inventarioId) async {
    try {
      final response = await http.put(Uri.parse('$baseUrl/inventario-resta/cerrar/$inventarioId'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error HTTP cerrarInventario: $e');
      return false;
    }
  }
}
