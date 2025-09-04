import 'package:flutter/material.dart';
import '../controllers/prestamo_equipo_controller.dart';
import '../services/user_service.dart';

class LentEquipmentScreen extends StatefulWidget {
  @override
  _LentEquipmentScreenState createState() => _LentEquipmentScreenState();
}

class _LentEquipmentScreenState extends State<LentEquipmentScreen> {
  final PrestamoEquipoController controller = PrestamoEquipoController();

  List<dynamic> prestamos = [];
  List<dynamic> clientes = [];
  Map<String, dynamic>? selectedCliente;

  final TextEditingController equipoCtrl = TextEditingController();
  final TextEditingController estadoPrestamoCtrl = TextEditingController();
  final TextEditingController cantidadCtrl = TextEditingController();
  final TextEditingController clienteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPrestamos();
    fetchClientes();
  }

  Future<void> fetchPrestamos() async {
    final data = await controller.getPrestamos();
    setState(() => prestamos = data);
  }

  Future<void> fetchClientes() async {
    final data = await UserService.getUsers();
    if (data != null) setState(() => clientes = data);
  }
  void showDevolucionModal(Map<String, dynamic> prestamo) {
  final TextEditingController estadoDevolucionCtrl = TextEditingController(
    text: prestamo['estado_devolucion'] ?? '',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Devolución de Equipo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          TextField(
            controller: estadoDevolucionCtrl,
            decoration: InputDecoration(
              labelText: "Estado de devolución",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            child: Text("Confirmar devolución"),
            onPressed: () async {
              try {
                await controller.updatePrestamo(
                  id: prestamo['id'],
                  estadoDevolucion: estadoDevolucionCtrl.text,
                  fechaDevolucion: DateTime.now().toIso8601String(),
                  equipo: prestamo['equipo'],
                  estadoPrestamo: prestamo['estado_entrega'],
                  cantidad: prestamo['cantidad'],
                );
                Navigator.pop(context);
                fetchPrestamos();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al actualizar devolución: $e")),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}
  /// Modal para crear un nuevo préstamo
  void showCreatePrestamoModal() {
    equipoCtrl.clear();
    estadoPrestamoCtrl.clear();
    cantidadCtrl.clear();
    selectedCliente = null;
    clienteCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Nuevo Préstamo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),

            // Selección de cliente
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty)
                  return clientes.cast<Map<String, dynamic>>();
                return clientes
                    .where((c) => (c['nombre'] as String)
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()))
                    .cast<Map<String, dynamic>>();
              },
              displayStringForOption: (option) => option['nombre'],
              onSelected: (option) {
                selectedCliente = option;
                clienteCtrl.text = option['nombre'];
              },
              fieldViewBuilder: (context, controllerText, focusNode, onSubmit) {
                clienteCtrl.text = controllerText.text;
                return TextField(
                  controller: controllerText,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Cliente",
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            SizedBox(height: 12),

            // Equipo
            TextField(
              controller: equipoCtrl,
              decoration: InputDecoration(
                labelText: "Equipo",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            // Estado de préstamo
            TextField(
              controller: estadoPrestamoCtrl,
              decoration: InputDecoration(
                labelText: "Estado de préstamo",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            // Cantidad
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Cantidad",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            ElevatedButton(
              child: Text("Crear"),
              onPressed: () async {
                if (selectedCliente == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Selecciona un cliente")));
                  return;
                }
                final cantidad = int.tryParse(cantidadCtrl.text);
                if (cantidad == null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Cantidad inválida")));
                  return;
                }

                await controller.createPrestamo(
                  idCliente: selectedCliente!['id'],
                  equipo: equipoCtrl.text,
                  estadoPrestamo: estadoPrestamoCtrl.text,
                  cantidad: cantidad,
                );

                Navigator.pop(context);
                fetchPrestamos();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Modal para editar un préstamo existente
  void showEditPrestamoModal(Map<String, dynamic> prestamo) {
    equipoCtrl.text = prestamo['equipo'] ?? '';
    estadoPrestamoCtrl.text = prestamo['estado_entrega'] ?? '';
    cantidadCtrl.text = prestamo['cantidad']?.toString() ?? '';
    selectedCliente = prestamo['cliente'];
    clienteCtrl.text = selectedCliente?['nombre'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Editar Préstamo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),

            // Selección de cliente
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty)
                  return clientes.cast<Map<String, dynamic>>();
                return clientes
                    .where((c) => (c['nombre'] as String)
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()))
                    .cast<Map<String, dynamic>>();
              },
              displayStringForOption: (option) => option['nombre'],
              onSelected: (option) {
                selectedCliente = option;
                clienteCtrl.text = option['nombre'];
              },
              fieldViewBuilder: (context, controllerText, focusNode, onSubmit) {
                controllerText.text = selectedCliente?['nombre'] ?? '';
                return TextField(
                  controller: controllerText,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Cliente",
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            SizedBox(height: 12),

            // Equipo
            TextField(
              controller: equipoCtrl,
              decoration: InputDecoration(
                labelText: "Equipo",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            // Estado de préstamo
            TextField(
              controller: estadoPrestamoCtrl,
              decoration: InputDecoration(
                labelText: "Estado de préstamo",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            // Cantidad
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Cantidad",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            ElevatedButton(
              child: Text("Actualizar"),
              onPressed: () async {
                if (selectedCliente == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Selecciona un cliente")));
                  return;
                }
                final cantidad = int.tryParse(cantidadCtrl.text);
                if (cantidad == null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Cantidad inválida")));
                  return;
                }

                await controller.updatePrestamo(
                  id: prestamo['id'],
                  equipo: equipoCtrl.text,
                  estadoPrestamo: estadoPrestamoCtrl.text,
                  cantidad: cantidad,
                );

                Navigator.pop(context);
                fetchPrestamos();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
Widget build(BuildContext context) {
  // Filtramos solo los clientes que tengan al menos un préstamo
  final clientesConPrestamos = clientes.where((c) {
    return prestamos.any((p) => p['id_cliente'] == c['id']);
  }).toList();

  return Scaffold(
    appBar: AppBar(title: Text("Préstamos de Equipo")),
    body: ListView.builder(
      itemCount: clientesConPrestamos.length,
      itemBuilder: (context, index) {
        final cliente = clientesConPrestamos[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(cliente['nombre']),
            subtitle: Text("Clic para ver sus préstamos"),
            trailing: Icon(Icons.keyboard_arrow_down),
            onTap: () {
              // Modal mostrando los préstamos de este cliente
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  final prestamosCliente = prestamos
                      .where((p) => p['id_cliente'] == cliente['id'])
                      .toList();

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: prestamosCliente.length,
                      itemBuilder: (context, i) {
                        final p = prestamosCliente[i];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text("${p['equipo']}"),
                            subtitle: Text(
                                "Estado: ${p['estado_entrega']} - Cantidad: ${p['cantidad']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.pop(context); // Cerramos modal
                                    showEditPrestamoModal(p);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    await controller.deletePrestamo(p['id']);
                                    fetchPrestamos();
                                    Navigator.pop(context);
                                  },
                                ),
                                if (p['estado_prestamo'] != 'devuelto')
                                  IconButton(
                                    icon: Icon(Icons.assignment_return),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showDevolucionModal(p);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: showCreatePrestamoModal, // Botón + permanece aquí
    ),
  );
}
}
