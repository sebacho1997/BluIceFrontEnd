import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> productos = [];
  

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  File? imagenSeleccionada;
  int? editProductId;

  @override
  void initState() {
    super.initState();
    obtenerProductos();
  }

  Future<void> obtenerProductos() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/productos"));
      if (res.statusCode == 200) {
        setState(() {
          productos = jsonDecode(res.body);
        });
      } else {
        print("Error al cargar productos: ${res.statusCode}");
      }
    } catch (e) {
      print("Error al obtener productos: $e");
    }
  }

  void mostrarDialogoProducto({dynamic producto}) {
    if (producto != null) {
      nombreController.text = producto['nombre'];
      precioController.text = producto['preciounitario'].toString();
      cantidadController.text = producto['cantidad'].toString();
      editProductId = producto['idproducto'];
      imagenSeleccionada = null;
    } else {
      nombreController.clear();
      precioController.clear();
      cantidadController.clear();
      editProductId = null;
      imagenSeleccionada = null;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(producto == null ? "Agregar Producto" : "Editar Producto"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: "Precio"),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: "Cantidad"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                imagenSeleccionada != null
                    ? Image.file(imagenSeleccionada!, height: 100)
                    : (producto != null && producto['imagen'] != null
                        ? Image.network(producto['imagen'], height: 100)
                        : const Text("No se seleccionó imagen")),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setStateDialog(() {
                        imagenSeleccionada = File(pickedFile.path);
                      });
                    }
                  },
                  child: const Text("Seleccionar Imagen"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                imagenSeleccionada = null;
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                String nombre = nombreController.text.trim();
                double? precio = double.tryParse(precioController.text.trim());
                int? cantidad = int.tryParse(cantidadController.text.trim());

                if (nombre.isEmpty || precio == null || cantidad == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Completa todos los campos")),
                  );
                  return;
                }

                if (editProductId == null) {
                  await agregarProducto(nombre, precio, cantidad, imagenSeleccionada);
                } else {
                  await editarProducto(editProductId!, nombre, precio, cantidad, imagenSeleccionada);
                }

                Navigator.pop(context);
                imagenSeleccionada = null;
              },
              child: Text(producto == null ? "Agregar" : "Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> agregarProducto(String nombre, double precio, int cantidad, File? imagen) async {
    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/productos"));
    request.fields['nombre'] = nombre;
    request.fields['preciounitario'] = precio.toString();
    request.fields['cantidad'] = cantidad.toString();

    if (imagen != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        obtenerProductos();
      } else {
        print("Error al agregar producto: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción al agregar producto: $e");
    }
  }

  Future<void> editarProducto(int id, String nombre, double precio, int cantidad, File? imagen) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/productos/$id'));
    request.fields['nombre'] = nombre;
    request.fields['preciounitario'] = precio.toString();
    request.fields['cantidad'] = cantidad.toString();

    if (imagen != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        obtenerProductos();
      } else {
        print("Error al editar producto: ${response.statusCode}");
      }
    } catch (e) {
      print("Excepción al editar producto: $e");
    }
  }

  Future<void> eliminarProducto(int id) async {
    try {
      final res = await http.delete(Uri.parse("$baseUrl/productos/$id"));
      if (res.statusCode == 200) {
        obtenerProductos();
      } else {
        print("Error al eliminar producto");
      }
    } catch (e) {
      print("Excepción al eliminar producto: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Productos")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: productos.length,
        itemBuilder: (context, index) {
          final producto = productos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              leading: producto['imagen'] != null
                  ? Image.network(
                      producto['imagen'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image_not_supported),
              title: Text(producto['nombre']),
              subtitle: Text(
                  'Cantidad: ${producto['cantidad']} | Precio: Bs${producto['preciounitario'].toString()}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => mostrarDialogoProducto(producto: producto),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => eliminarProducto(producto['idproducto']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarDialogoProducto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
