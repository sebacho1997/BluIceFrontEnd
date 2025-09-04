import 'package:flutter/material.dart';
import '../controllers/gastos_dia_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/historial_gastos_screen.dart';

class GastosScreen extends StatefulWidget {
  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final GastosDiaController _controller = GastosDiaController();
  List<dynamic> _gastos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGastos();
  }

  Future<void> _fetchGastos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
    final conductorId = prefs.getInt('userId');
      final gastos = await _controller.listarHoy(conductorId!.toInt());
      setState(() {
        _gastos = gastos;
        _isLoading = false;
      });
    } catch (e) {
      print("Error al cargar gastos: $e");
    }
  }

  void _openGastoDialog({Map<String, dynamic>? gasto}) async {
    final prefs = await SharedPreferences.getInstance();
    final conductorId = prefs.getInt('userId');
    final descripcionCtrl = TextEditingController(text: gasto?['descripcion'] ?? "");
    final montoCtrl = TextEditingController(text: gasto?['monto']?.toString() ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(gasto == null ? "Nuevo Gasto" : "Editar Gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descripcionCtrl,
              decoration: InputDecoration(labelText: "Descripción"),
            ),
            TextField(
              controller: montoCtrl,
              decoration: InputDecoration(labelText: "Monto"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          ElevatedButton(
            child: Text(gasto == null ? "Guardar" : "Actualizar"),
            onPressed: () async {
              final newGasto = {
                "descripcion": descripcionCtrl.text,
                "monto": double.tryParse(montoCtrl.text) ?? 0,
                "fecha_gasto": DateTime.now().toIso8601String(),
                "id_conductor": conductorId, // ⚡ Aquí deberías poner el id real del conductor logueado
              };

              if (gasto == null) {
                await _controller.createGasto(newGasto);
              } else {
                await _controller.updateGasto(gasto['id'], newGasto);
              }

              Navigator.pop(ctx);
              _fetchGastos();
            },
          ),
        ],
      ),
    );
  }

  void _deleteGasto(int id) async {
    await _controller.deleteGasto(id);
    _fetchGastos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gastos del Día")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _gastos.isEmpty
              ? Center(child: Text("No hay gastos registrados 📋"))
              : ListView.builder(
                  itemCount: _gastos.length,
                  itemBuilder: (ctx, i) {
                    final gasto = _gastos[i];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(gasto['descripcion']),
                        subtitle: Text("Monto: ${gasto['monto']} Bs\nFecha: ${gasto['fecha_gasto']}"),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openGastoDialog(gasto: gasto),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteGasto(gasto['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnHistorial",
            backgroundColor: Colors.blueGrey,
            child: Icon(Icons.history), // 📜 Historial
            onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>HistorialGastosScreen() ),
        );
      },
          ),
          SizedBox(width: 12),
          FloatingActionButton(
            heroTag: "btnAgregar",
            child: Icon(Icons.add), // ➕ Agregar gasto
            onPressed: () => _openGastoDialog(),
          ),
        ],
      ),
    );
  }
}
