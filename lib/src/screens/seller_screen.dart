import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bluicefrontend/src/controllers/order_controller.dart';
import 'package:bluicefrontend/src/services/user_service.dart';
import 'package:bluicefrontend/src/services/pedido_imagen_service.dart';
import 'package:bluicefrontend/src/screens/profile_seller_screen.dart';
import 'package:bluicefrontend/src/screens/map_screen.dart';
import 'package:bluicefrontend/src/controllers/product_controller.dart';

class SellerScreen extends StatefulWidget {
  @override
  _SellerScreenState createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  int _selectedIndex = 1;

  TextEditingController clientNameController = TextEditingController();
  TextEditingController extraDataController = TextEditingController();

  List<Map<String, dynamic>> productosDisponibles = [];
  Map<int, int> productosSeleccionados = {}; // productoId -> cantidad
  bool isLoadingProducts = true;

  List<Map<String, dynamic>> clientes = [];
  Map<String, dynamic>? clienteSeleccionado;
  bool isLoadingClientes = true;

  List<Map<String, dynamic>> direcciones = [];
  Map<String, dynamic>? direccionSeleccionada;

  String metodoPago = 'efectivo'; // nuevo campo
  File? imagenSeleccionada; // imagen del pedido

  @override
  void initState() {
    super.initState();
    fetchProductosDisponibles();
    fetchClientes();
  }

  Future<void> fetchProductosDisponibles() async {
    try {
      final data = await ProductController().fetchProducts();
      setState(() {
        productosDisponibles = data;
        isLoadingProducts = false;
      });
    } catch (e) {
      print('Error al cargar productos: $e');
      setState(() => isLoadingProducts = false);
    }
  }

  Future<void> fetchClientes() async {
    try {
      final data = await UserService.getUsers();
      setState(() {
        clientes = List<Map<String, dynamic>>.from(
            data?.where((u) => u['tipo_usuario'] == 'cliente') ?? []);
        isLoadingClientes = false;
      });
    } catch (e) {
      print('Error al cargar clientes: $e');
      setState(() => isLoadingClientes = false);
    }
  }

  Future<void> cargarDireccionesCliente(int userId) async {
    try {
      final listaDirecciones = await UserService.getUserAddresses(userId);
      setState(() {
        direcciones = listaDirecciones
                ?.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        direccionSeleccionada =
            direcciones.isNotEmpty ? direcciones.first : null;
      });
    } catch (e) {
      print("Error cargando direcciones: $e");
    }
  }

  Future<void> agregarNuevaDireccion(int userId) async {
    final direccionController = TextEditingController();
    final infoExtraControllerLocal = TextEditingController();
    double? latitud;
    double? longitud;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar nueva dirección"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: "Dirección"),
              ),
              TextField(
                controller: infoExtraControllerLocal,
                decoration: const InputDecoration(labelText: "Información extra"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        onLocationSelected: (LatLng loc) {},
                      ),
                    ),
                  );
                  if (result != null && result is LatLng) {
                    latitud = result.latitude;
                    longitud = result.longitude;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Ubicación seleccionada: ${latitud!.toStringAsFixed(5)}, ${longitud!.toStringAsFixed(5)}",
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text("Seleccionar ubicación en mapa"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (direccionController.text.isEmpty ||
                  latitud == null ||
                  longitud == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Completa todos los campos")),
                );
                return;
              }

              final data = {
                "direccion": direccionController.text,
                "info_extra": infoExtraControllerLocal.text,
                "latitud": latitud,
                "longitud": longitud,
              };

              bool success = await UserService.createUserAddress(userId, data);

              if (success) {
                Navigator.pop(context);
                cargarDireccionesCliente(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dirección agregada con éxito")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error al agregar dirección")),
                );
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
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

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null) {
      setState(() {
        imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  Future<void> tomarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 800, maxHeight: 800);
    if (pickedFile != null) {
      setState(() {
        imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  Future<void> _addSale() async {
  if (clienteSeleccionado == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')));
    return;
  }
  if (productosSeleccionados.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un producto')));
    return;
  }

  // Construir datos del pedido
  final pedidoData = {
    "usuario_id": clienteSeleccionado!['id'],
    "direccion_id": direccionSeleccionada != null ? direccionSeleccionada!['id'] : null,
    "direccion": direccionSeleccionada != null ? direccionSeleccionada!['direccion'] : '',
    "latitud": direccionSeleccionada != null ? direccionSeleccionada!['latitud'] : null,
    "longitud": direccionSeleccionada != null ? direccionSeleccionada!['longitud'] : null,
    "info_extra": extraDataController.text.isNotEmpty
        ? extraDataController.text
        : direccionSeleccionada != null ? direccionSeleccionada!['info_extra'] ?? '' : '',
    "productos": productosSeleccionados.entries
        .map((e) => {"producto_id": e.key, "cantidad": e.value})
        .toList(),
  };

  // Crear pedido
  final int? pedidoId = await OrderService.crearPedido(pedidoData);

  if (pedidoId != null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido registrado exitosamente')));

    // Subir imagen si hay
    if (imagenSeleccionada != null) {
      bool imgExito = await PedidoImagenesService.subirImagenPedido(
          pedidoId, imagenSeleccionada!);
      if (imgExito) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen subida correctamente')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir imagen')));
      }
    }

    // Limpiar campos
    setState(() {
      clienteSeleccionado = null;
      direccionSeleccionada = null;
      clientNameController.clear();
      extraDataController.clear();
      productosSeleccionados.clear();
      metodoPago = 'efectivo';
      imagenSeleccionada = null;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar pedido')));
  }
}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    clientNameController.dispose();
    extraDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla Vendedor')),
      body: _selectedIndex == 1
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Registrar Pedido',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // ===== Dropdown Clientes =====
                    isLoadingClientes
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            hint: const Text('Selecciona un cliente'),
                            value: clienteSeleccionado,
                            items: clientes.map((cliente) {
                              return DropdownMenuItem(
                                value: cliente,
                                child: Text(cliente['nombre']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                clienteSeleccionado = value;
                                clientNameController.text =
                                    value?['nombre'] ?? '';
                                if (value != null) {
                                  cargarDireccionesCliente(value['id']);
                                }
                              });
                            },
                          ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: clientNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del Cliente'),
                    ),

                    const SizedBox(height: 20),

                    // ===== Dropdown Direcciones =====
                    if (clienteSeleccionado != null)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<Map<String, dynamic>>(
                              value: direccionSeleccionada,
                              hint: const Text("Selecciona dirección"),
                              items: direcciones
                                  .map((dir) => DropdownMenuItem(
                                        value: dir,
                                        child: Text(dir['direccion']),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  direccionSeleccionada = value;
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              if (clienteSeleccionado != null) {
                                agregarNuevaDireccion(clienteSeleccionado!['id']);
                              }
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // ===== Productos =====
                    const Text('Productos',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    isLoadingProducts
                        ? const CircularProgressIndicator()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: productosDisponibles.length,
                            itemBuilder: (context, index) {
                              final p = productosDisponibles[index];
                              int cantidad =
                                  productosSeleccionados[p['idproducto']] ?? 0;
                              return Card(
                                child: ListTile(
                                  title: Text(
                                      '${p['nombre']} - ${p['preciounitario']} Bs'),
                                  subtitle: Text('Stock: ${p['cantidad']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () => seleccionarProducto(
                                              p['idproducto'], cantidad - 1)),
                                      Text('$cantidad'),
                                      IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => seleccionarProducto(
                                              p['idproducto'], cantidad + 1)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 20),

                    // ===== Imagen Pedido =====
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: seleccionarImagen,
                          child: const Text('Seleccionar imagen'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: tomarFoto,
                          child: const Text('Tomar foto'),
                        ),
                      ],
                    ),
                    if (imagenSeleccionada != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.file(
                          imagenSeleccionada!,
                          height: 150,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ===== Botón Registrar Pedido =====
                    ElevatedButton(
                      child: const Text('Registrar Pedido'),
                      onPressed: _addSale,
                    ),
                  ],
                ),
              ),
            )
          : ProfileSellerScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Venta',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
