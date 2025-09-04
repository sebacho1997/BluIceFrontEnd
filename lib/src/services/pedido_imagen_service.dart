import 'dart:io';
import 'dart:convert';
import 'package:bluicefrontend/src/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../config.dart';

class PedidoImagenesService {
  // ===== Subir imagen de un pedido =====
  static Future<bool> subirImagenPedido(int pedidoId, File archivo) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final uri = Uri.parse('$baseUrl/pedidoImagenes/$pedidoId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final mimeTypeData =
          lookupMimeType(archivo.path, headerBytes: [0xFF, 0xD8])?.split('/') ??
              ['image', 'jpeg'];

      request.files.add(await http.MultipartFile.fromPath(
        'imagen',
        archivo.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response body: $respStr');

      return response.statusCode == 200;
    } catch (e) {
      print('Error al subir imagen del pedido: $e');
      return false;
    }
  }

  // ===== Obtener imágenes de un pedido =====
  static Future<List<Map<String, dynamic>>?> getImagenesPedido(int pedidoId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/pedidoImagenes/$pedidoId'),
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
      print('Error al obtener imágenes del pedido: $e');
      return null;
    }
  }
}
