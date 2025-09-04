import 'package:flutter/material.dart';
import '../controllers/gastos_dia_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistorialGastosScreen extends StatefulWidget {
  @override
  _HistorialGastosScreenState createState() => _HistorialGastosScreenState();
}

class _HistorialGastosScreenState extends State<HistorialGastosScreen> {
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
      final gastos = await _controller.getGastos(conductorId);
      setState(() {
        _gastos = gastos;
        _isLoading = false;
      });
    } catch (e) {
      print("Error al cargar gastos: $e");
    }
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
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
