import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class VerDireccionScreen extends StatefulWidget {
  final double latitud;
  final double longitud;

  const VerDireccionScreen({
    Key? key,
    required this.latitud,
    required this.longitud,
  }) : super(key: key);

  @override
  _VerDireccionScreenState createState() => _VerDireccionScreenState();
}

class _VerDireccionScreenState extends State<VerDireccionScreen> {
  late LatLng selectedLatLng;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Inicializamos con la lat/lon que recibimos
    selectedLatLng = LatLng(widget.latitud, widget.longitud);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dirección del Pedido")),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: selectedLatLng,
          initialZoom: 16,
          onTap: (tapPosition, point) {
            // Para que el usuario pueda tocar y mover el marcador si se desea
            setState(() {
              selectedLatLng = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.miempresa.miapp',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLatLng,
                width: 50,
                height: 50,
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
