import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const MapScreen({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedLatLng;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Servicios de ubicación deshabilitados');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permiso de ubicación denegado');
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permiso de ubicación denegado permanentemente');
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng current = LatLng(position.latitude, position.longitude);
    setState(() {
      selectedLatLng = current;
    });
    _mapController.move(current, 15);
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1");
    final response = await http.get(url);
    final data = jsonDecode(response.body) as List;
    setState(() {
      _suggestions = data.map((e) => e['display_name'] as String).toList();
      _showSuggestions = true;
    });
  }

  Future<void> _selectAddress(String address) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1");
    final response = await http.get(url);
    final data = jsonDecode(response.body) as List;
    if (data.isNotEmpty) {
      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);
      LatLng point = LatLng(lat, lon);
      setState(() {
        selectedLatLng = point;
        _showSuggestions = false;
      });
      _mapController.move(point, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(-17.3935, -66.1568),
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() {
                  selectedLatLng = point;
                  _showSuggestions = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.miempresa.miapp',
              ),
              if (selectedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLatLng!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _selectAddress(_searchController.text),
                      ),
                    ),
                    onChanged: _searchAddress,
                  ),
                ),
                if (_showSuggestions)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_suggestions[index]),
                          onTap: () => _selectAddress(_suggestions[index]),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'current_location',
                  mini: true,
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          if (selectedLatLng != null)
            Positioned(
              bottom: 30,
              right: 15,
              child: FloatingActionButton(
                heroTag: 'select_location',
                onPressed: () {
                  widget.onLocationSelected(selectedLatLng!);
                  Navigator.pop(context, selectedLatLng);
                },
                child: const Icon(Icons.check),
              ),
            ),
        ],
      ),
    );
  }
}
