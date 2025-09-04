import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:bluicefrontend/src/controllers/order_controller.dart';
import 'package:bluicefrontend/src/controllers/product_controller.dart';
import 'package:bluicefrontend/src/services/user_service.dart';
import 'package:bluicefrontend/src/services/pedido_imagen_service.dart';
import 'package:bluicefrontend/src/screens/map_screen.dart';

class DriverPedidoScreen extends StatefulWidget {
  const DriverPedidoScreen({super.key});

  @override
  State<DriverPedidoScreen> createState() => _DriverPedidoScreenState();
}

class _DriverPedidoScreenState extends State<DriverPedidoScreen> {
  TextEditingController extraDataController = TextEditingController();

  List<Map<String, dynamic>> productosDisponibles = [];
  Map<int, int> productosSeleccionados = {};

  List<Map<String, dynamic>> clientes = [];
  Map<String, dynamic>? clienteSeleccionado;

  List<Map<String, dynamic>> direcciones = [];
  Map<String, dynamic>? direccionSeleccionada;

  bool isLoadingProductos = true;
  bool isLoadingClientes = true;
  File? imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    fetchProductos();
    fetchClientesAsignados();
  }

  Future<void> fetchProductos() async {
    try {
      final data = await ProductController().fetchProducts();
      setState(() {
        productosDisponibles = data;
        isLoadingProductos = false;
      });
    } catch (e) {
      debugPrint("Error cargando productos: $e");
      setState(() => isLoadingProductos = false);
    }
  }

  Future<void> fetchClientesAsignados() async {
    try {
      final data = await UserService.getUsers();
      setState(() {
        clientes = List<Map<String, dynamic>>.from(
          data?.where((u) => u['tipo_usuario'] == 'cliente') ?? [],
        );
        isLoadingClientes = false;
      });
    } catch (e) {
      debugPrint("Error cargando clientes: $e");
      setState(() => isLoadingClientes = false);
    }
  }

  Future<void> cargarDireccionesCliente(int userId) async {
    try {
      final data = await UserService.getUserAddresses(userId);
      setState(() {
        direcciones = List<Map<String, dynamic>>.from(data ?? []);
        direccionSeleccionada =
            direcciones.isNotEmpty ? direcciones.first : null;
      });
    } catch (e) {
      debugPrint("Error cargando direcciones: $e");
    }
  }

  Future<void> seleccionarImagen({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      setState(() => imagenSeleccionada = File(pickedFile.path));
    }
  }

  void seleccionarProducto(int productoId, int cantidad) {
    setState(() {
      if (cantidad > 0) {
        productosSeleccionados[productoId] = cantidad;
      } else {
        productosSeleccionados.remove(productoId);
      }
    });
  }

  Future<void> registrarPedido() async {
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un cliente")),
      );
      return;
    }
    if (productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos un producto")),
      );
      return;
    }

    final pedidoData = {
      "usuario_id": clienteSeleccionado!['id'],
      "direccion_id": direccionSeleccionada?['id'],
      "direccion": direccionSeleccionada?['direccion'] ?? '',
      "latitud": direccionSeleccionada?['latitud'],
      "longitud": direccionSeleccionada?['longitud'],
      "info_extra": extraDataController.text.isNotEmpty
          ? extraDataController.text
          : direccionSeleccionada?['info_extra'] ?? '',
      "productos": productosSeleccionados.entries
          .map((e) => {"producto_id": e.key, "cantidad": e.value})
          .toList(),
    };

    final pedidoId = await OrderService.crearPedido(pedidoData);
    if (pedidoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar pedido")),
      );
      return;
    }

    // Subir imagen si hay
    if (imagenSeleccionada != null) {
      final ok =
          await PedidoImagenesService.subirImagenPedido(pedidoId, imagenSeleccionada!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? "Pedido registrado con imagen"
              : "Pedido registrado, error subiendo imagen"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido registrado exitosamente")),
      );
    }

    // limpiar
    setState(() {
      clienteSeleccionado = null;
      direccionSeleccionada = null;
      productosSeleccionados.clear();
      extraDataController.clear();
      imagenSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Pedido Conductor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cliente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            isLoadingClientes
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<Map<String, dynamic>>(
                    hint: const Text("Selecciona un cliente"),
                    value: clienteSeleccionado,
                    items: clientes.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        clienteSeleccionado = value;
                      });
                      if (value != null) cargarDireccionesCliente(value['id']);
                    },
                  ),
            const SizedBox(height: 20),

            if (clienteSeleccionado != null) ...[
              const Text("Dirección",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<Map<String, dynamic>>(
                hint: const Text("Selecciona dirección"),
                value: direccionSeleccionada,
                items: direcciones
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d['direccion']),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => direccionSeleccionada = val);
                },
              ),
            ],
            const SizedBox(height: 20),

            const Text("Productos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            isLoadingProductos
                ? const CircularProgressIndicator()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productosDisponibles.length,
                    itemBuilder: (context, i) {
                      final p = productosDisponibles[i];
                      final cantidad = productosSeleccionados[p['idproducto']] ?? 0;
                      return Card(
                        child: ListTile(
                          title: Text(
                              "${p['nombre']} - ${p['preciounitario']} Bs"),
                          subtitle: Text("Stock: ${p['cantidad']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () =>
                                    seleccionarProducto(p['idproducto'], cantidad - 1),
                              ),
                              Text("$cantidad"),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    seleccionarProducto(p['idproducto'], cantidad + 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 20),
            TextField(
              controller: extraDataController,
              decoration:
                  const InputDecoration(labelText: "Información adicional"),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => seleccionarImagen(fromCamera: false),
                  child: const Text("Seleccionar Imagen"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => seleccionarImagen(fromCamera: true),
                  child: const Text("Tomar Foto"),
                ),
              ],
            ),
            if (imagenSeleccionada != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(imagenSeleccionada!, height: 150),
              ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: registrarPedido,
              child: const Text("Registrar Pedido"),
            ),
          ],
        ),
      ),
    );
  }
}
