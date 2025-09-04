import 'package:flutter/material.dart';
import '../controllers/contrato_controller.dart';

class ContratoConsumoScreen extends StatefulWidget {
  final int contratoId;
  final String nombreCliente;

  const ContratoConsumoScreen({
    super.key,
    required this.contratoId,
    required this.nombreCliente,
  });

  @override
  State<ContratoConsumoScreen> createState() => _ContratoConsumoScreenState();
}

class _ContratoConsumoScreenState extends State<ContratoConsumoScreen> {
  List<Map<String, dynamic>> consumos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchConsumos();
  }

  Future<void> fetchConsumos() async {
    setState(() => isLoading = true);
    final data = await ContratoController.getConsumos(widget.contratoId) ?? [];
    setState(() {
      consumos = data;
      isLoading = false;
    });
  }

  Future<void> _refresh() async {
    await fetchConsumos();
  }

  Future<void> _marcarEntregado(int consumoId) async {
    final exito = await ContratoController.marcarEntregado(consumoId);
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Consumo marcado como entregado ✅")),
      );
      fetchConsumos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar consumo ❌")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Consumos - ${widget.nombreCliente}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : consumos.isEmpty
              ? const Center(child: Text("No hay consumos registrados"))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: consumos.length,
                    itemBuilder: (context, index) {
                      final consumo = consumos[index];
                      final detalles = consumo['detalles'] ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Monto: Bs${consumo['monto_consumido'] ?? 0}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text("Obs: ${consumo['observaciones'] ?? '-'}"),
                              Text("Fecha: ${consumo['fecha'] ?? '-'}"),
                              const SizedBox(height: 8),
                              if (detalles.isNotEmpty) ...[
                                const Text(
                                  "Productos:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...detalles.map(
                                  (d) => Text(
                                    "${d['producto_nombre']} x${d['cantidad'] ?? 0}",
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Botón Entregado
                              if (consumo['observaciones'] != 'entregado')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () => _marcarEntregado(consumo['id']),
                                    child: const Text("Entregado"),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
