import 'dart:convert';
import 'dart:io';
import 'package:bluicefrontend/src/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../config.dart';

class OrderService {
  // ===== Crear pedido =====
  static Future<int?> crearPedido(Map<String, dynamic> data) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      // Preparamos el body sin metodo_pago
      final pedidoData = {
        "usuario_id": data["usuario_id"],
        "direccion_id": data["direccion_id"],
        "direccion": data["direccion"],
        "latitud": data["latitud"],
        "longitud": data["longitud"],
        "info_extra": data["info_extra"],
        "productos": data["productos"],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/pedidos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(pedidoData),
      );

      if (response.statusCode == 201) {
        final respData = jsonDecode(response.body);
        return respData['id'];
      } else {
        print('Error: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al crear pedido: $e');
      return null;
    }
  }

  static Future<bool> addPago(int pedidoId, String metodoPago, double monto, {File? comprobante}) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Token no encontrado');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/pedidos/$pedidoId/pagos'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['metodo_pago'] = metodoPago;
    request.fields['monto'] = monto.toString();

    if (comprobante != null) {
      request.files.add(await http.MultipartFile.fromPath('comprobante', comprobante.path));
    }

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Pago registrado correctamente: ${responseData.body}');
      return true;
    } else {
      print('Error al registrar pago: ${response.statusCode} - ${responseData.body}');
      return false;
    }
  } catch (e) {
    print('Error addPago: $e');
    return false;
  }
}

static Future<List<Map<String, dynamic>>> getClientesDeudores() async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final response = await http.get(
      Uri.parse('$baseUrl/pedidos/deudores'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) throw Exception('Error al obtener clientes deudores');

    final List data = jsonDecode(response.body);

    // Cada fila ya es un usuario deudor
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (e) {
    print('Error en getClientesDeudores: $e');
    return [];
  }
}

  // ===== Obtener pedidos de un usuario =====
  static Future<List<Map<String, dynamic>>?> getOrdersByUser(
      int usuarioId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/usuario/$usuarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('Error: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getOrdersByUser: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getPendingConductor() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final uri = Uri.parse('$baseUrl/pedidos/sinconductor');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print(
            'Error al obtener pedidos: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getPendingConductor: $e');
      return null;
    }
  }
static Future<bool> marcarEntregado(int pedidoId) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final response = await http.post(
      Uri.parse('$baseUrl/pedidos/$pedidoId/entregado'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  } catch (e) {
    print('Error marcarEntregado: $e');
    return false;
  }
}
static Future<bool> marcarCompletado(int pedidoId) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Token no encontrado');

    final response = await http.patch(
      Uri.parse('$baseUrl/pedidos/$pedidoId/completado'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  } catch (e) {
    print('Error marcarCompletado: $e');
    return false;
  }
}

  static Future<List<Map<String, dynamic>>?> getOrdersByConductor(
      int conductorId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');
      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/conductor/$conductorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('Error: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getOrdersByConductor: $e');
      return null;
    }
  }

  // ===== Obtener pedidos por usuario y estado =====
  static Future<List<Map<String, dynamic>>?> getOrdersByUserAndEstado(
      int usuarioId, String estado) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/usuario/$usuarioId/estado/$estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('Error: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getOrdersByUserAndEstado: $e');
      return null;
    }
  }

  // ===== Obtener pedidos por estado =====
  static Future<List<Map<String, dynamic>>?> getOrdersByEstado(
      String estado) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/estado/$estado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('Error: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getOrdersByEstado: $e');
      return null;
    }
  }

  // ===== Confirmar entrega =====
  static Future<bool> confirmarEntrega(int pedidoId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/entregar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al confirmar entrega: $e');
      return false;
    }
  }

  // ===== Agregar recibo =====
  static Future<bool> agregarRecibo(int pedidoId, String numeroRecibo) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/recibo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'numeroRecibo': numeroRecibo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al agregar recibo: $e');
      return false;
    }
  }

  // ===== Subir comprobante =====
  static Future<bool> subirComprobante(int pedidoId, File archivo) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final uri = Uri.parse('$baseUrl/pedidos/$pedidoId/pago');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeTypeData =
          lookupMimeType(archivo.path)?.split('/') ?? ['image', 'jpeg'];
      request.files.add(await http.MultipartFile.fromPath(
        'comprobante',
        archivo.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error al subir comprobante: $e');
      return false;
    }
  }

  // ===== Obtener productos de un pedido =====
  static Future<List<Map<String, dynamic>>?> getOrderProducts(
      int pedidoId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/$pedidoId/productos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('Error: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getOrderProducts: $e');
      return null;
    }
  }

  // ===== Asignar pedido a conductor =====
  static Future<bool> assignOrder(int pedidoId, int conductorId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.put(
        Uri.parse('$baseUrl/pedidos/$pedidoId/assign/$conductorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error assignOrder: $e');
      return false;
    }
  }

  // ===== Obtener pedidos pendientes sin conductor =====
  static Future<List<Map<String, dynamic>>?> getPendingSinConductor() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/conductor/sinconductor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print('Error: ${response.statusCode} -> ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getPendingSinConductor: $e');
      return null;
    }
  }
}
