import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class InventarioConductorController {
  // -----------------------------
  // INVENTARIO
  // -----------------------------

  // Crear un inventario
  Future<bool> crearInventario(
    int conductorId,
    List<Map<String, dynamic>> productos,
  ) async {
    try {
      final body = {
        "conductor_id": conductorId,
        "productos": productos, // [{producto_id: 1, cantidad: 5}, ...]
      };

      final response = await http.post(
        Uri.parse("$baseUrl/inventario"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Error al crear inventario: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception crearInventario: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getInventarioHoy(int conductorId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/inventario/hoy/$conductorId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data ya es una lista
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Error getInventarioHoy: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception getInventarioHoy: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRegreso(int conductorId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/inventario/regreso/$conductorId"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => {
        "id_producto": e["id_producto"],
        "nombre": e["nombre"],
        "cantidad_cargada": e["cantidad_cargada"],
        "cantidad_entregada": e["cantidad_entregada"],
        "cantidad_restante": e["cantidad_restante"],
      }).toList();
    } else {
      throw Exception("Error obteniendo inventario de regreso");
    }
  }

  static Future<bool> existeInventarioHoy(int conductorId) async {
    print("entro al existe inventario conductorid: "+ conductorId.toString());
    final response = await http.get(
      Uri.parse('$baseUrl/inventario/existe/$conductorId'),
    );
  
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['existe'] == true;
    } else {
      throw Exception('Error al verificar inventario');
    }
  }

  // Obtener inventarios de un conductor
  Future<List<Map<String, dynamic>>> getInventariosByConductor(
    int conductorId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/inventario/$conductorId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Error al obtener inventarios: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception getInventariosByConductor: $e");
      return [];
    }
  }

  // Obtener detalle de un inventario
  Future<Map<String, dynamic>?> getInventarioDetalle(int inventarioId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/inventario/$inventarioId"),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        print("Error al obtener detalle de inventario: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception getInventarioDetalle: $e");
      return null;
    }
  }

  Future<bool> cerrarInventario(int inventarioId) async {
    try {
      final body = {"inventario_id": inventarioId};

      final response = await http.put(
        Uri.parse("$baseUrl/cerrar"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Error al cerrar inventario: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception cerrarInventario: $e");
      return false;
    }
  }

  // -----------------------------
  // DEVOLUCIONES
  // -----------------------------

  // Crear una devolución
  Future<bool> crearDevolucion(
    int conductorId,
    List<Map<String, dynamic>> productos,
  ) async {
    try {
      final body = {"conductor_id": conductorId, "productos": productos};

      final response = await http.post(
        Uri.parse("$baseUrl/inventario/devolucion"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) return true;
      print("Error al crear devolución: ${response.body}");
      return false;
    } catch (e) {
      print("Exception crearDevolucion: $e");
      return false;
    }
  }

  // Obtener devoluciones de un conductor
  Future<List<Map<String, dynamic>>> getDevolucionesByConductor(
    int conductorId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/inventario/devolucion/$conductorId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Error al obtener devoluciones: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception getDevolucionesByConductor: $e");
      return [];
    }
  }

  // Obtener detalle de una devolución
  Future<List<Map<String, dynamic>>> getDevolucionDetalle(
    int devolucionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/inventario/devolucion/detalle/$devolucionId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Error al obtener detalle de devolución: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception getDevolucionDetalle: $e");
      return [];
    }
  }
}
