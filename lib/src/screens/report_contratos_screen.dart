import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bluicefrontend/src/services/user_service.dart';
import 'package:bluicefrontend/src/services/auth_service.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import '../config.dart';
import 'dart:io';

class ReportContratoScreen extends StatefulWidget {
  const ReportContratoScreen({Key? key}) : super(key: key);

  @override
  _ReportContratoScreenState createState() => _ReportContratoScreenState();
}

class _ReportContratoScreenState extends State<ReportContratoScreen> {
  List<dynamic> conductores = [];
  bool isLoading = true;

  DateTime? selectedMonth;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _loadConductores();
  }

  Future<void> _loadConductores() async {
    final users = await UserService.getUsers();
    if (users != null) {
      setState(() {
        conductores = users.where((u) => u['tipo_usuario'] == 'conductor').toList();
        isLoading = false;
      });
    } else {
      setState(() {
        conductores = [];
        isLoading = false;
      });
    }
  }

  Future<void> _downloadAndOpenPDF(int conductorId, String tipoReporte) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    String url = '';

    if (tipoReporte == 'diario') {
      url = '$baseUrl/reporte-consumos-dia/$conductorId';
    } else if (tipoReporte == 'mes' && selectedMonth != null) {
      final mes = selectedMonth!.month.toString().padLeft(2, '0');
      final anio = selectedMonth!.year;
      url = '$baseUrl/reporte-consumos-mes/$conductorId/$anio/$mes';
    } else if (tipoReporte == 'personalizado' &&
        startDate != null &&
        endDate != null) {
      final start = startDate!.toIso8601String().split("T").first;
      final end = endDate!.toIso8601String().split("T").first;
      url = '$baseUrl/reporte-consumos-personalizado/$conductorId/$start/$end';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione la fecha correspondiente')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/reporte_contratos_${conductorId}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDFViewerScreen(file.path)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error descargando el PDF: ${response.statusCode}'),
        ),
      );
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        selectedMonth = picked;
      });
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Widget _buildConductorList(String tipoReporte) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : conductores.isEmpty
            ? const Center(child: Text('No se encontraron conductores'))
            : ListView.separated(
                itemCount: conductores.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final conductor = conductores[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(conductor['nombre']),
                    subtitle: Text('ID: ${conductor['id']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () =>
                          _downloadAndOpenPDF(conductor['id'], tipoReporte),
                    ),
                  );
                },
              );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes Contratos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Diario'),
              Tab(text: 'Mes'),
              Tab(text: 'Personalizado'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Diario
            _buildConductorList('diario'),

            // Mes
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => _pickMonth(context),
                    child: Text(
                      selectedMonth != null
                          ? 'Mes seleccionado: ${selectedMonth!.month}/${selectedMonth!.year}'
                          : 'Seleccionar mes',
                    ),
                  ),
                ),
                Expanded(child: _buildConductorList('mes')),
              ],
            ),

            // Personalizado
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => _pickDateRange(context),
                    child: Text(
                      startDate != null && endDate != null
                          ? 'Desde: ${startDate!.toLocal().toIso8601String().split("T").first} Hasta: ${endDate!.toLocal().toIso8601String().split("T").first}'
                          : 'Seleccionar rango de fechas',
                    ),
                  ),
                ),
                Expanded(child: _buildConductorList('personalizado')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla para visualizar PDF
class PDFViewerScreen extends StatelessWidget {
  final String path;
  const PDFViewerScreen(this.path, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte PDF')),
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
