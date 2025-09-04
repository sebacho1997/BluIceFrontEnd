import 'package:bluicefrontend/src/screens/ContratoConsumoScreen.dart';
import 'package:flutter/material.dart';
import '../controllers/contrato_controller.dart';
import '../controllers/contrato_controller.dart';

class DriverContratoScreen extends StatefulWidget {
  const DriverContratoScreen({super.key});

  @override
  State<DriverContratoScreen> createState() => _DriverContratoScreenState();
}

class _DriverContratoScreenState extends State<DriverContratoScreen> {
  late Future<List<Map<String, dynamic>>?> _contratosFuture;

  @override
  void initState() {
    super.initState();
    _contratosFuture = ContratoController.getContratos();
  }

  Future<void> _refreshContratos() async {
    setState(() {
      _contratosFuture = ContratoController.getContratos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contratos")),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _contratosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("❌ Error cargando contratos: ${snapshot.error}"),
            );
          }

          final contratos = snapshot.data;
          if (contratos == null || contratos.isEmpty) {
            return const Center(child: Text("No hay contratos asignados"));
          }

          return RefreshIndicator(
            onRefresh: _refreshContratos,
            child: ListView.builder(
              itemCount: contratos.length,
              itemBuilder: (context, index) {
                final contrato = contratos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      contrato['nombre_cliente'] ??
                          "Contrato #${contrato['id']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Monto total: \Bs${contrato['monto_total'] ?? 0}\n"
                      "Consumido: \Bs${contrato['monto_consumido'] ?? 0}",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContratoConsumoScreen(
                            contratoId: contrato['id'],
                            nombreCliente:
                                contrato['nombre_cliente'] ?? "Cliente",
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
