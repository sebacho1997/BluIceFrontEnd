import 'package:flutter/material.dart';
import 'package:bluicefrontend/src/services/auth_service.dart';

class ProfileDriverScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                // Imagen del logo
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/logo.jpg'), // Reemplaza con tu logo
                ),
                SizedBox(height: 10),
                Text(
                  'Una forma diferente de hidratarte',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          Divider(),
          ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Agregar Pedidos'),
            onTap: () {
              Navigator.pushNamed(context, '/driverPedidos');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout_outlined),
            title: Text('Cerrar sesión'),
            onTap: () async {
              await AuthService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
