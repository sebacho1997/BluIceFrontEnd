import 'package:flutter/material.dart';
import 'package:bluicefrontend/src/services/auth_service.dart';

class ProfileSellerScreen extends StatelessWidget {
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
          // Opciones del menú para usuario logueado
          ListTile(
            leading: Icon(Icons.inventory_2_outlined),
            title: Text('Productos'),
            onTap: () {
              Navigator.pushNamed(context, '/products');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.handyman_outlined),
            title: Text('Préstamos de equipo'),
            onTap: () {
              Navigator.pushNamed(context, '/prestamos');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.assignment_outlined),
            title: Text('Reportes Conductor'),
            onTap: () {
              Navigator.pushNamed(context, '/reporteConductor');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.assignment_outlined),
            title: Text('Reportes Contratos'),
            onTap: () {
              Navigator.pushNamed(context, '/reporteContratos');
            },
          ),
          Divider(),
          // Nueva opción para Contratos
          ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Contratos'),
            onTap: () {
              Navigator.pushNamed(context, '/contratos');
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
