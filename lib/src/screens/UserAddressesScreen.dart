import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserAddressesScreen extends StatefulWidget {
  final int userId;

  const UserAddressesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserAddressesScreenState createState() => _UserAddressesScreenState();
}

class _UserAddressesScreenState extends State<UserAddressesScreen> {
  List<dynamic> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    final result = await UserService.getUserAddresses(widget.userId);
    setState(() {
      addresses = result ?? [];
      isLoading = false;
    });
  }

  Future<void> addOrEditAddress({Map<String, dynamic>? address}) async {
    final direccionController = TextEditingController(
      text: address != null ? address['direccion'] : '',
    );
    final extraController = TextEditingController(
      text: address != null ? address['info_extra'] : '',
    );
    final latitudController = TextEditingController(
      text: address != null ? address['latitud']?.toString() ?? '' : '',
    );
    final longitudController = TextEditingController(
      text: address != null ? address['longitud']?.toString() ?? '' : '',
    );

    final isEditing = address != null;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? "Editar Dirección" : "Nueva Dirección"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: direccionController,
                  decoration: InputDecoration(labelText: "Dirección"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Ingrese la dirección" : null,
                ),
                TextFormField(
                  controller: extraController,
                  decoration: InputDecoration(labelText: "Información extra"),
                ),
                TextFormField(
                  controller: latitudController,
                  decoration: InputDecoration(labelText: "Latitud"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: longitudController,
                  decoration: InputDecoration(labelText: "Longitud"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(isEditing ? "Guardar" : "Agregar"),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final data = {
                "direccion": direccionController.text,
                "info_extra": extraController.text,
                "latitud": latitudController.text.isNotEmpty
                    ? double.tryParse(latitudController.text)
                    : null,
                "longitud": longitudController.text.isNotEmpty
                    ? double.tryParse(longitudController.text)
                    : null,
              };

              bool success;
              if (isEditing) {
                success = await UserService.updateUserAddress(address['id'], data);
              } else {
                success = await UserService.createUserAddress(widget.userId, data);
              }

              Navigator.pop(context);

              if (success) {
                fetchAddresses();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEditing
                      ? "Dirección actualizada con éxito"
                      : "Dirección agregada con éxito")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error al guardar la dirección")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> deleteAddress(int id) async {
    final success = await UserService.deleteUserAddress(id);
    if (success) {
      fetchAddresses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Dirección eliminada")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar la dirección")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Direcciones del Cliente'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? Center(child: Text('No hay direcciones registradas'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(address['direccion'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (address['info_extra'] != null &&
                                address['info_extra'].toString().isNotEmpty)
                              Text(address['info_extra']),
                            if (address['latitud'] != null &&
                                address['longitud'] != null)
                              Text(
                                  "Lat: ${address['latitud']} | Lng: ${address['longitud']}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => addOrEditAddress(address: address),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteAddress(address['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditAddress(),
        child: Icon(Icons.add),
      ),
    );
  }
}
