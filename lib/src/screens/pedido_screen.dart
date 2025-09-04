import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../controllers/order_controller.dart';
import 'map_screen.dart';
import 'package:latlong2/latlong.dart';
import '../screens/home_screen.dart';

class PedidoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  PedidoScreen({required this.cart});

  @override
  _PedidoScreenState createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  String selectedPaymentMethod = '';
  double totalAmount = 0.0;

  List<Map<String, dynamic>> direcciones = [];
  Map<String, dynamic>? direccionSeleccionada;
  bool agregarNueva = false;

  LatLng? selectedLatLng;
  TextEditingController infoExtraController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculateTotal();
    _cargarDirecciones();
  }

  void _calculateTotal() {
    totalAmount = widget.cart.fold(0.0, (sum, item) {
      double price = 0.0;
      int quantity = 0;

      if (item['price'] is String) {
        price = double.tryParse(item['price']) ?? 0.0;
      } else if (item['price'] is int) {
        price = (item['price'] as int).toDouble();
      } else {
        price = item['price'];
      }

      if (item['quantity'] is String) {
        quantity = int.tryParse(item['quantity']) ?? 0;
      } else {
        quantity = item['quantity'];
      }

      return sum + (price * quantity);
    });
    setState(() {});
  }

  Future<void> _cargarDirecciones() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    try {
      final listaDirecciones = await UserService.getUserAddresses(userId);
      if (listaDirecciones != null) {
        setState(() {
          direcciones = listaDirecciones
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
          if (direcciones.isNotEmpty) direccionSeleccionada = direcciones.first;
        });
      }
    } catch (e) {
      print("Error cargando direcciones: $e");
    }
  }

  Future<void> _agregarNuevaDireccion() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    final direccionController = TextEditingController();
    final infoExtraLocalController = TextEditingController();
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
                controller: infoExtraLocalController,
                decoration:
                    const InputDecoration(labelText: "Información extra"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final selected = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        onLocationSelected: (LatLng point) {},
                      ),
                    ),
                  );
                  if (selected != null && selected is LatLng) {
                    latitud = selected.latitude;
                    longitud = selected.longitude;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Ubicación seleccionada: ${latitud!.toStringAsFixed(5)}, ${longitud!.toStringAsFixed(5)}"),
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
            child: const Text("Cancelar"),
          ),
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
                "info_extra": infoExtraLocalController.text,
                "latitud": latitud,
                "longitud": longitud,
              };

              bool success =
                  await UserService.createUserAddress(userId, data);

              if (success) {
                Navigator.pop(context);
                _cargarDirecciones();
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

  Future<void> _confirmarPedido() async {
  if (direccionSeleccionada == null && !agregarNueva) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona o agrega una dirección')),
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');
  if (userId == null) return;

  final pedido = {
    "usuario_id": userId,
    "direccion_id": direccionSeleccionada != null ? direccionSeleccionada!['id'] : null,
    "direccion": direccionSeleccionada != null ? direccionSeleccionada!['direccion'] : '',
    "latitud": direccionSeleccionada != null ? direccionSeleccionada!['latitud'] : null,
    "longitud": direccionSeleccionada != null ? direccionSeleccionada!['longitud'] : null,
    "info_extra": infoExtraController.text.isNotEmpty
        ? infoExtraController.text
        : direccionSeleccionada != null ? direccionSeleccionada!['info_extra'] ?? '' : '',
    "productos": widget.cart.map((item) {
      return {
        "producto_id": item['idproducto'] ?? item['id'],
        "cantidad": item['quantity']
      };
    }).toList(),
  };

  final exito = await OrderService.crearPedido(pedido);

  if (exito != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido registrado exitosamente')),
    );

    // Limpiar campos
    setState(() {
      direccionSeleccionada = null;
      selectedLatLng = null;
      infoExtraController.clear();
    });

    // Navegar a HomeScreen y limpiar pila
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (Route<dynamic> route) => false,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error al registrar pedido')),
    );
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Confirmar Pedido')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                const Text(
                  'Productos en tu pedido:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...widget.cart.map((product) {
                  double price = product['price'] is String
                      ? double.tryParse(product['price']) ?? 0
                      : (product['price'] as num).toDouble();
                  int quantity = product['quantity'] is String
                      ? int.tryParse(product['quantity']) ?? 0
                      : product['quantity'];
                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text('Cantidad: $quantity x Bs${price.toStringAsFixed(2)}'),
                    trailing: Text('Bs${(price * quantity).toStringAsFixed(2)}'),
                  );
                }).toList(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: direccionSeleccionada,
                        hint: const Text("Selecciona tu dirección"),
                        items: direcciones
                            .map((dir) => DropdownMenuItem(
                                  value: dir,
                                  child: Text(dir['direccion']),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            direccionSeleccionada = value;
                            agregarNueva = false;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: _agregarNuevaDireccion,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Total a pagar: Bs${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _confirmarPedido,
            child: const Text('Confirmar Pedido'),
          ),
        ],
      ),
    ),
  );
}
}
