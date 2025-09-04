// =================== contrato_screen.dart ===================
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../controllers/contrato_controller.dart';
import '../controllers/product_controller.dart';
import 'consumo_screen.dart';

class ContratoScreen extends StatefulWidget {
  @override
  _ContratoScreenState createState() => _ContratoScreenState();
}

class _ContratoScreenState extends State<ContratoScreen> {
  List<Map<String, dynamic>> clientes = [];
  bool isLoadingClientes = true;

  List<Map<String, dynamic>> contratos = [];
  bool isLoadingContratos = true;

  int? selectedClienteId;
  TextEditingController montoController = TextEditingController();
  DateTime? fechaInicio;
  DateTime? fechaFin;

  @override
  void initState() {
    super.initState();
    fetchClientes();
    fetchContratos();
  }

  Future<void> fetchClientes() async {
    final data = await UserService.getUsersByType('cliente');
    setState(() {
      clientes = data ?? [];
      isLoadingClientes = false;
    });
  }

  Future<void> fetchContratos() async {
    setState(() => isLoadingContratos = true);
    final data = await ContratoController.getContratos();
    setState(() {
      contratos = data?.where((c) => c['estado'] != 'finalizado').toList() ?? [];
      isLoadingContratos = false;
    });
  }

  void _openAgregarContratoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevo Contrato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              isLoadingClientes
                  ? Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: selectedClienteId,
                      items: clientes.map((cliente) {
                        return DropdownMenuItem<int>(
                          value: cliente['id'],
                          child: Text(cliente['nombre']),
                        );
                      }).toList(),
                      hint: Text('Selecciona un cliente'),
                      onChanged: (value) => setState(() => selectedClienteId = value),
                    ),
              SizedBox(height: 16),
              TextField(
                controller: montoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto total',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => fechaInicio = picked);
                      },
                      child: Text(fechaInicio == null
                          ? 'Selecciona fecha inicio'
                          : 'Inicio: ${fechaInicio!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => fechaFin = picked);
                      },
                      child: Text(fechaFin == null
                          ? 'Selecciona fecha fin'
                          : 'Fin: ${fechaFin!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (selectedClienteId == null || montoController.text.isEmpty || fechaInicio == null || fechaFin == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Completa todos los campos')));
                    return;
                  }

                  double monto = double.tryParse(montoController.text) ?? 0;
                  if (monto <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Monto inválido')));
                    return;
                  }

                  bool exito = await ContratoController.crearContrato({
                    'cliente_id': selectedClienteId,
                    'monto_total': monto,
                    'monto_restante': monto,
                    'fecha_inicio': fechaInicio!.toIso8601String(),
                    'fecha_fin': fechaFin!.toIso8601String(),
                  });

                  if (exito) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contrato creado con éxito')));
                    setState(() {
                      selectedClienteId = null;
                      montoController.clear();
                      fechaInicio = null;
                      fechaFin = null;
                    });
                    await fetchContratos();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear contrato')));
                  }
                },
                child: Text('Crear Contrato'),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contratos')),
      body: isLoadingContratos
          ? Center(child: CircularProgressIndicator())
          : contratos.isEmpty
              ? Center(child: Text('No hay contratos activos'))
              : ListView.builder(
                  itemCount: contratos.length,
                  itemBuilder: (context, index) {
                    final contrato = contratos[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Cliente: ${contrato['nombre'] ?? contrato['cliente_id']}'),
                        subtitle: Text('Monto restante: ${contrato['monto_restante']}'),
                        trailing: Text('${contrato['estado']}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsumoScreen(contratoId: contrato['id'], contratoEstado: contrato['estado'], ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAgregarContratoModal,
        child: Icon(Icons.add),
      ),
    );
  }
}
