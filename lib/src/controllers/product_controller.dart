import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';
class ProductController {
  //final String "$baseUrl/productos = 'http://localhost:5000/api/productos';

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/productos"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }

  Future<void> addProduct(String nombre, int cantidad, double preciounitario, File imagen) async {
    var uri = Uri.parse("$baseUrl/productos");
    var request = http.MultipartRequest("POST", uri);

    // Campos normales
    request.fields['nombre'] = nombre;
    request.fields['cantidad'] = cantidad.toString();
    request.fields['preciounitario'] = preciounitario.toString();

    // Imagen
    request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));

    var response = await request.send();
    if (response.statusCode != 201) {
      throw Exception('Error al agregar producto');
    }
  }

  Future<void> editProduct(int idproducto, String nombre, int cantidad, double preciounitario, {File? imagen}) async {
    var uri = Uri.parse('$baseUrl/productos/$idproducto');
    var request = http.MultipartRequest("PUT", uri);

    request.fields['nombre'] = nombre;
    request.fields['cantidad'] = cantidad.toString();
    request.fields['preciounitario'] = preciounitario.toString();

    // Si se pasa imagen nueva → la sube y borra la anterior en backend
    if (imagen != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
    }

    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Error al editar producto');
    }
  }

  Future<void> deleteProduct(int idproducto) async {
    final response = await http.delete(Uri.parse('$baseUrl/productos/$idproducto'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar producto');
    }
  }
}
