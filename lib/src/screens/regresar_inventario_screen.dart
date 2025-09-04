import 'package:flutter/material.dart';
import '../controllers/inventario_conductor_controler.dart';

class RegresarInventarioScreen extends StatefulWidget {
  final int conductorId;

  const RegresarInventarioScreen({Key? key, required this.conductorId})
      : super(key: key);

  @override
  _RegresarInventarioScreenState createState() =>
      _RegresarInventarioScreenState();
}

class _RegresarInventarioScreenState extends State<RegresarInventarioScreen> {
  final InventarioConductorController inventarioController =
      InventarioConductorController();

  List<Map<String, dynamic>> productos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInventarioHoy();
  }

  Future<void> fetchInventarioHoy() async {
    setState(() => isLoading = true);

    try {
      final List<dynamic> response =
          await inventarioController.getInventarioHoy(widget.conductorId);

      if (response.isNotEmpty) {
        setState(() {
          productos = List<Map<String, dynamic>>.from(response);
        });
      } else {
        setState(() => productos = []);
      }
    } catch (e) {
      print('Error al obtener inventario de hoy: $e');
      setState(() => productos = []);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void actualizarCantidad(int index, int cambio) {
    setState(() {
      final nuevaCantidad = productos[index]['cantidad'] + cambio;
      if (nuevaCantidad >= 0) {
        productos[index]['cantidad'] = nuevaCantidad;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Regresar Inventario")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : productos.isEmpty
              ? const Center(child: Text("No hay productos para regresar"))
              : ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (ctx, i) {
                    final p = productos[i];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(p['producto_nombre'] ?? 'Producto'),
                        subtitle: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: () => actualizarCantidad(i, -1),
                            ),
                            Text('${p['cantidad']}'),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () => actualizarCantidad(i, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () async {
          print(productos);

          // Filtrar productos con cantidad > 0 para enviar
          final productosADevolver = productos
              .where((p) => p['cantidad'] > 0)
              .map((p) => {
                    "producto_id": p['producto_id'], 
                    "cantidad": p['cantidad'],
                  })
              .toList();

          if (productosADevolver.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No hay productos para devolver")),
            );
            return;
          }

          // 1️⃣ Registrar devolución
          final success = await inventarioController.crearDevolucion(
            widget.conductorId,
            productosADevolver,
          );

          if (success) {
            // 2️⃣ Obtener inventario_id del primer producto
            final inventarioId = productos.first['inventario_id'];
            print("Inventario a cerrar: $inventarioId");

            // 3️⃣ Llamar al método para cerrar inventario
            final cerrado =
                await inventarioController.cerrarInventario(inventarioId);

            if (cerrado) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Inventario cerrado exitosamente ✅")),
              );
              setState(() => productos = []);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al cerrar el inventario ❌")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error al registrar la devolución ❌")),
            );
          }
        },
      ),
    );
  }
}
