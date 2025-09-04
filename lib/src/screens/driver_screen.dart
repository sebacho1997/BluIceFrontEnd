import 'package:bluicefrontend/src/screens/profile_driver_screen.dart';
import 'package:bluicefrontend/src/screens/regresar_inventario_screen.dart';
import 'package:bluicefrontend/src/screens/ver_direccion_screen.dart';
import 'package:flutter/material.dart';
import '../controllers/product_controller.dart';
import '../controllers/inventario_conductor_controler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/order_controller.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pedido_imagen_service.dart';
import '../screens/gastos_screen.dart';
import 'package:bluicefrontend/src/screens/driver_contrato_screen.dart';
import 'dart:io';

class DriverScreen extends StatefulWidget {
  @override
  _DriverScreenState createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  int _selectedIndex = 0;
  bool isTruckOccupied = false;

  final ProductController productController = ProductController();
  final InventarioConductorController inventarioController =
      InventarioConductorController();

  List<Map<String, dynamic>> availableProducts = [];
  bool isLoadingProducts = true;

  List<Map<String, dynamic>> assignedOrders = [];
  bool isLoadingOrders = true;

  // <<<<<< NUEVO: bandera para saber si ya confirmaste el inventario >>>>>>
  bool inventarioConfirmado = false;

  File? qrFile; // archivo temporal del comprobante

  @override
  void initState() {
    super.initState();
    fetchAvailableProducts();
    fetchAssignedOrders();
    checkInventarioHoy();
  }

  Future<void> checkInventarioHoy() async {
    final prefs = await SharedPreferences.getInstance();
    final conductorId = prefs.getInt('userId');
    if (conductorId == null) return;

  final yaExiste = await InventarioConductorController.existeInventarioHoy(conductorId);

  setState(() {
    inventarioConfirmado = yaExiste; 
  });
}

  Future<void> fetchAvailableProducts() async {
    try {
      final products = await productController.fetchProducts();
      setState(() {
        availableProducts = products.map((p) {
          return {
            'id': p['idproducto'],
            'name': p['nombre'],
            'quantity': 0,
          };
        }).toList();
        isLoadingProducts = false;
      });
    } catch (e) {
      print("Error cargando productos: $e");
      setState(() => isLoadingProducts = false);
    }
  }

  Future<void> fetchAssignedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final conductorId = prefs.getInt('userId');
    if (conductorId == null) return;

    setState(() => isLoadingOrders = true);

    final orders = await OrderService.getOrdersByConductor(conductorId);
    if (orders != null) {
      setState(() {
        assignedOrders = orders;
        isLoadingOrders = false;
      });
    } else {
      setState(() => isLoadingOrders = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar pedidos asignados')),
      );
    }
  }

  void toggleTruckStatus() {
    setState(() {
      isTruckOccupied = !isTruckOccupied;
    });
  }

  void addToInventory(int index) {
    setState(() {
      availableProducts[index]['quantity']++;
    });
  }

  // <<<<<< MODIFICADO: ahora primero advierte y si aceptas, confirma y BLOQUEA >>>>>>
  Future<void> confirmInventoryUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final conductorId = prefs.getInt('userId');
    if (conductorId == null) return;

    final productosParaInventario = availableProducts
        .where((p) => p['quantity'] > 0)
        .map((p) => {'producto_id': p['id'], 'cantidad': p['quantity']})
        .toList();

    if (productosParaInventario.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agrega al menos un producto al inventario')),
      );
      return;
    }

    // Diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Inventario'),
        content: Text(
            '¿Seguro que deseas confirmar el inventario?\n\nDespués de confirmar no podrás modificar las cantidades y se habilitará el botón "Regresar Inventario".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Llamada al backend
    final exito =
        await inventarioController.crearInventario(conductorId, productosParaInventario);

    if (exito) {
      // IMPORTANTE: NO limpiamos cantidades; las dejamos visibles pero bloqueadas
      setState(() {
        inventarioConfirmado = true; // bloquea edición y habilita "Regresar Inventario"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventario registrado y bloqueado ✅')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar inventario ❌')),
      );
    }
  }

  Widget _buildInventoryTab() {
    if (isLoadingProducts) return Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: availableProducts.length,
            itemBuilder: (context, index) {
              final product = availableProducts[index];
              return ListTile(
                title: Text(product['name']),
                subtitle: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      // Deshabilitado si inventarioConfirmado o quantity == 0
                      onPressed: (!inventarioConfirmado && product['quantity'] > 0)
                          ? () {
                              setState(() {
                                product['quantity']--;
                              });
                            }
                          : null,
                    ),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: !inventarioConfirmado, // <<<<<< BLOQUEO >>>>>>
                        decoration: InputDecoration(
                          hintText: '${product['quantity']}',
                        ),
                        onSubmitted: (value) {
                          if (inventarioConfirmado) return;
                          setState(() {
                            product['quantity'] =
                                int.tryParse(value) ?? product['quantity'];
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: !inventarioConfirmado
                          ? () => addToInventory(index)
                          : null, // <<<<<< BLOQUEO >>>>>>
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Botón Confirmar Inventario: deshabilitado cuando ya está confirmado
        ElevatedButton(
          onPressed: inventarioConfirmado ? null : confirmInventoryUpdate,
          child: Text('Confirmar Inventario'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.money),
              label: Text("Gastos"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GastosScreen()),
                );
              },
            ),
            // "Regresar Inventario" deshabilitado HASTA confirmar inventario
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_back),
              label: Text("Regresar Inventario"),
              onPressed: !inventarioConfirmado
                  ? null
                  : () async {
                      final prefs = await SharedPreferences.getInstance();
                      final conductorId = prefs.getInt('userId');
                      if (conductorId == null) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegresarInventarioScreen(conductorId: conductorId),
                        ),
                      );
                    },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignedOrdersTab() {
    if (isLoadingOrders) return Center(child: CircularProgressIndicator());

    if (assignedOrders.isEmpty)
      return Center(child: Text('No tienes pedidos asignados'));

    return ListView.builder(
      itemCount: assignedOrders.length,
      itemBuilder: (context, index) {
        final order = assignedOrders[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido #${order['id']} - ${order['cliente_nombre']}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Dirección: ${order['direccion']}'),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['estado']),
                    ElevatedButton(
                      onPressed: () => _showOrderDetails(order),
                      child: Text('Ver'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    final productos = await OrderService.getOrderProducts(order['id']);
    final imagenes = await PedidoImagenesService.getImagenesPedido(order['id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido #${order['id']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // Monto total y pagado
              Text('Monto total: ${order['monto_total']}'),
              Text('Monto pagado: ${order['monto_pagado']}'),
              Text('Direccion: ${order['direccion']}'),
              SizedBox(height: 10),
// Botón Ver Dirección
Center(
  child: ElevatedButton.icon(
    icon: Icon(Icons.location_on),
    label: Text("Ver Dirección"),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerDireccionScreen(
            latitud: order['latitud'],
            longitud: order['longitud'],
          ),
        ),
      );
    },
  ),
),

SizedBox(height: 10),
              Expanded(
                child: productos == null || productos.isEmpty
                    ? Center(child: Text('No hay productos en este pedido'))
                    : ListView.builder(
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final p = productos[index];
                          return ListTile(
                            title: Text(p['nombre']),
                            subtitle: Text('Cantidad: ${p['cantidad']}'),
                          );
                        },
                      ),
              ),
              // Imagen del comprobante si existe
              if (imagenes != null && imagenes.isNotEmpty) ...[
                Text('Imagen Pedido:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Image.network(
                  imagenes[0]['imagen'],
                  height: 120,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 10),
              ],

              SizedBox(height: 10),

              // Botón Recibo
              ElevatedButton.icon(
                icon: Icon(Icons.receipt),
                label: Text('Recibo'),
                onPressed: (order['estado'] != 'entregado' &&
                        order['nro_recibo'] == null)
                    ? () {
                        _showReciboModal(order['id']);
                      }
                    : null,
              ),

              SizedBox(height: 10),

              // Botón Añadir Pago
              ElevatedButton.icon(
                icon: Icon(Icons.payment),
                label: Text("Añadir Pago"),
                onPressed: (order['monto_pagado'] != null &&
                        order['monto_total'] != null &&
                        order['monto_pagado'] == order['monto_total'])
                    ? null
                    : () => _showAddPagoModal(order['id']),
              ),
              if (order['estado'] == 'asignado')
                ElevatedButton.icon(
                  icon: Icon(Icons.check_circle),
                  label: Text('Entregado'),
                  onPressed: () async {
                    final exito = await OrderService.marcarEntregado(order['id']);
                    if (exito) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pedido marcado como entregado ✅')),
                      );
                      Navigator.pop(context);
                      fetchAssignedOrders();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al actualizar pedido ❌')),
                      );
                    }
                  },
                ),
              // Botón Completar Pedido
              if (order['monto_pagado'] != null &&
                  order['monto_total'] != null &&
                  order['monto_pagado'] == order['monto_total'] &&
                  order['estado'] != 'completado')
                ElevatedButton.icon(
                  icon: Icon(Icons.check_circle),
                  label: Text("Completar Pedido"),
                  onPressed: () async {
                    final exito = await OrderService.marcarCompletado(order['id']);
                    if (exito) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Pedido completado ✅")),
                      );
                      Navigator.pop(context);
                      fetchAssignedOrders();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error al completar el pedido ❌")),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReciboModal(int pedidoId) {
    final TextEditingController reciboController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar Recibo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              TextField(
                controller: reciboController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Número de recibo',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final numeroRecibo = reciboController.text.trim();
                  if (numeroRecibo.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ingresa el número de recibo')),
                    );
                    return;
                  }

                  final exito =
                      await OrderService.agregarRecibo(pedidoId, numeroRecibo);

                  if (exito) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recibo registrado con éxito ✅')),
                    );
                    Navigator.pop(context);
                    fetchAssignedOrders();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al registrar el recibo ❌')),
                    );
                  }
                },
                child: Text('Agregar Recibo'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPagoModal(int pedidoId) {
    String metodoPago = "Efectivo";
    final montoController = TextEditingController();
    File? comprobanteLocal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Registrar Pago",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: metodoPago,
                    items: ["Efectivo", "QR"]
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        metodoPago = value!;
                        comprobanteLocal = null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Método de pago",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),

                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "Monto", border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),

                  if (metodoPago == "QR") ...[
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.photo_camera),
                          label: Text("Tomar foto"),
                          onPressed: () async {
                            final picked = await ImagePicker()
                                .pickImage(source: ImageSource.camera);
                            if (picked != null) {
                              setModalState(() {
                                comprobanteLocal = File(picked.path);
                              });
                            }
                          },
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: Icon(Icons.photo_library),
                          label: Text("Subir imagen"),
                          onPressed: () async {
                            final picked = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setModalState(() {
                                comprobanteLocal = File(picked.path);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (comprobanteLocal != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.file(comprobanteLocal!, height: 120),
                      ),
                  ],

                  SizedBox(height: 12),
                  ElevatedButton(
                    child: Text("Guardar Pago"),
                    onPressed: () async {
                      final monto = double.tryParse(montoController.text) ?? 0;
                      if (monto <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Ingresa un monto válido")),
                        );
                        return;
                      }

                      final exito = await OrderService.addPago(
                        pedidoId, metodoPago, monto,
                        comprobante: comprobanteLocal,
                      );

                      if (exito) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Pago registrado ✅")),
                        );
                        fetchAssignedOrders();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error al registrar pago ❌")),
                        );
                      }
                    },
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pantalla Conductor'),
      ),
      body: _selectedIndex == 0
          ? _buildInventoryTab()
          : _selectedIndex == 1
              ? _buildAssignedOrdersTab()
              : _selectedIndex == 2
                  ? DriverContratoScreen()
                  : ProfileDriverScreen(), // 👈 CUARTA SECCIÓN PERFIL
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 👈 importante para 4+ items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Contratos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil', // 👈 nuevo tab
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
