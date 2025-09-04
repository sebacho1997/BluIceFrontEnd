import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bluicefrontend/src/controllers/order_controller.dart';
import 'package:bluicefrontend/src/services/auth_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../config.dart';
import 'dart:io';

class ClientesDeudoresScreen extends StatefulWidget {
  @override
  _ClientesDeudoresScreenState createState() => _ClientesDeudoresScreenState();
}

class _ClientesDeudoresScreenState extends State<ClientesDeudoresScreen> {
  List<Map<String, dynamic>> clientesDeudores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarClientesDeudores();
  }

  Future<void> cargarClientesDeudores() async {
    setState(() => isLoading = true);

    final usuarios = await OrderService.getClientesDeudores();

    setState(() {
      clientesDeudores = usuarios;
      isLoading = false;
    });
  }

  Future<void> abrirReporteCliente(int clienteId) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final url = '$baseUrl/reporte-deudas-cliente/$clienteId';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reporte_cliente_$clienteId.pdf');
      await file.writeAsBytes(bytes, flush: true);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDFViewerScreen(file.path)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error descargando el PDF: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clientes Deudores')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : clientesDeudores.isEmpty
              ? Center(child: Text('No hay clientes con deuda.'))
              : ListView.separated(
                  itemCount: clientesDeudores.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, index) {
                    final cliente = clientesDeudores[index];
                    return ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text(cliente['nombre']),
                      subtitle: Text(cliente['email'] ?? ''),
                      trailing: Icon(Icons.picture_as_pdf, color: Colors.red),
                      onTap: () => abrirReporteCliente(cliente['usuario_id']),
                    );
                  },
                ),
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String path;
  const PDFViewerScreen(this.path, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reporte Cliente')),
      body: PDFView(
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
      ),
    );
  }
}
