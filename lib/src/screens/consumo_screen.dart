import 'package:bluicefrontend/src/services/user_service.dart';
import 'package:flutter/material.dart';
import '../controllers/contrato_controller.dart';
import '../controllers/product_controller.dart';

class ConsumoScreen extends StatefulWidget {
  final int contratoId;
  final String contratoEstado;

  const ConsumoScreen({Key? key, required this.contratoId,required this.contratoEstado,}) : super(key: key);

  @override
  _ConsumoScreenState createState() => _ConsumoScreenState();
}

class _ConsumoScreenState extends State<ConsumoScreen> {
  List<Map<String, dynamic>> consumos = [];
  List<Map<String, dynamic>> productos = [];
  bool isLoadingProductos = true;
  Map<int, int> cantidades = {}; // clave: productoId, valor: cantidad
  TextEditingController montoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchConsumos();
    fetchProductos();
  }

  Future<void> fetchConsumos() async {
    final data = await ContratoController.getConsumos(widget.contratoId) ?? [];
    setState(() {
      consumos = data;
    });
  }

  Future<void> fetchProductos() async {
    setState(() => isLoadingProductos = true);
    final data = await ProductController().fetchProducts();
    print(data);
    setState(() {
      productos =
          data.where((p) => p['idproducto'] != null).toList(); // filtramos nulos
      isLoadingProductos = false;
    });
  }

  void _agregarProducto(int productoId, int delta) {
    setState(() {
      final current = cantidades[productoId] ?? 0;
      final nueva = current + delta;
      if (nueva <= 0) {
        cantidades.remove(productoId);
      } else {
        cantidades[productoId] = nueva;
      }
    });
  }
void _asignarConductor() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: UserService.getUsersByType("conductor"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: Text("Error"),
              content: Text("No se pudieron cargar los conductores"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cerrar"),
                ),
              ],
            );
          } else {
            final conductores = snapshot.data ?? [];
            return AlertDialog(
              title: Text("Seleccionar conductor"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: conductores.length,
                  itemBuilder: (context, index) {
                    final c = conductores[index];
                    return ListTile(
                      title: Text(c['nombre'] ?? ''),
                      subtitle: Text("ID: ${c['id']}"),
                      onTap: () async {
                        // Asignar el conductor al contrato
                        bool exito = await ContratoController.asignarConductor(
                          widget.contratoId,
                          c['id'],
                        );
                        if (exito) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Conductor ${c['nombre']} asignado"),
                            ),
                          );
                          Navigator.pop(context);
                          // Recargar consumos u otra info si es necesario
                          fetchConsumos();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error al asignar conductor"),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancelar"),
                ),
              ],
            );
          }
        },
      );
    },
  );
}
  void _guardarConsumo() async {
    if (montoController.text.isEmpty || cantidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa monto y selecciona productos')),
      );
      return;
    }

    double monto = double.tryParse(montoController.text) ?? 0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Monto inválido')),
      );
      return;
    }

    // 1️⃣ Crear consumo
    int? consumoId =
        await ContratoController.crearConsumo(widget.contratoId, monto);
        print("id del consumo: "+ consumoId.toString());
    if (consumoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear consumo')),
      );
      return;
    }

    // 2️⃣ Crear detalles de consumo
    bool allOk = true;
    for (var entry in cantidades.entries) {
      final exito = await ContratoController.crearDetalleConsumo(
        consumoId,
        entry.key,
        entry.value,
      );
      if (!exito){
        print("❌ Error guardando productoId ${entry.key} con cantidad ${entry.value}");
        allOk = false;
        }
    }

    if (allOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consumo y detalles agregados con éxito')),
      );
      montoController.clear();
      cantidades.clear();
      fetchConsumos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar algunos productos')),
      );
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consumos contrato #${widget.contratoId}')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Consumidos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (widget.contratoEstado != 'entregado' &&
                    widget.contratoEstado != 'completado')
                  ElevatedButton(
                    onPressed: _asignarConductor,
                    child: Text('Asignar conductor'),
                  ),
              ],
            ),
            SizedBox(height: 8),
            consumos.isEmpty
                ? Text('No hay consumos registrados')
                : Column(
                    children: consumos.map((consumo) {
                      final detalles = consumo['detalles'] ?? [];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Fecha: ${consumo['fecha']?.split('T')[0] ?? ''}',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Monto consumido: ${consumo['monto_consumido']}'),
                              Text('Observaciones: ${consumo['observaciones'] ?? ''}'),
                              SizedBox(height: 8),
                              Text('Productos:'),
                              ...detalles.map<Widget>((d) => Text(
                                  '${d['producto_nombre']} - Cantidad: ${d['cantidad']}',
                                  style: TextStyle(fontSize: 14))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            Divider(height: 32),
            Text('Agregar nuevo consumo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto consumido',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            isLoadingProductos
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: productos.map((prod) {
                      final productoId = prod['idproducto'] as int;
                      final cantidad = cantidades[productoId] ?? 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(prod['nombre']),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () => _agregarProducto(productoId, -1),
                              ),
                              Text('$cantidad', style: TextStyle(fontSize: 16)),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => _agregarProducto(productoId, 1),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _guardarConsumo,
              child: Text('Agregar Consumo'),
            ),
          ],
        ),
      ),
    );
  }
}