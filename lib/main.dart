import 'package:bluicefrontend/src/screens/clientes_deudores_screen.dart';
import 'package:bluicefrontend/src/screens/contrato_screen.dart';
import 'package:bluicefrontend/src/screens/driver_pedido_screen.dart';
import 'package:bluicefrontend/src/screens/products_screen.dart.dart';
import 'package:bluicefrontend/src/screens/report_conductor_screen.dart';
import 'package:bluicefrontend/src/screens/report_contratos_screen.dart';
import 'package:flutter/material.dart';
import 'package:bluicefrontend/src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/pedido_screen.dart';
import 'src/screens/admin_screen.dart'; 
import 'src/screens/driver_screen.dart'; 
import 'src/screens/seller_screen.dart'; 
import 'src/screens/UserAddressesScreen.dart';
import 'src/screens/lent_equipment_screen.dart';

class EmpresaBotellonesApp extends StatefulWidget {
  @override
  _EmpresaBotellonesAppState createState() => _EmpresaBotellonesAppState();
}

class _EmpresaBotellonesAppState extends State<EmpresaBotellonesApp> {
  bool isAuthenticated = false;
  String userRole = ''; // Almacena el rol del usuario

  void login(String role) {
    setState(() {
      isAuthenticated = true;
      userRole = role; // Guarda el rol del usuario
    });
  }

  void logout() {
    setState(() {
      isAuthenticated = false;
      userRole = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Botellones y Hielo',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(), // Pantalla de carga
        '/prestamos': (context) => LentEquipmentScreen(),
        '/clientesDeudores': (context) => ClientesDeudoresScreen(),
        '/driverPedidos':(context)=> DriverPedidoScreen(),
        '/contratos': (context) => ContratoScreen(),
        '/reporteContratos' :(context)=> ReportContratoScreen(),
        '/reporteConductor' :(context) => ReportConductorScreen(),
        '/products': (context) => ProductsScreen(),
        '/userAddresses': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return UserAddressesScreen(userId: args);
        },
        '/login': (context) => LoginScreen(onLogin: login),
        '/register': (context) => RegisterScreen(),
        '/home': (context) {
          if (!isAuthenticated) {
            return LoginScreen(onLogin: login);
          }
          return userRole == 'cliente'
              ? HomeScreen()
              : userRole == 'administrador'
                  ? AdminScreen()
                  : userRole == 'conductor'
                      ? DriverScreen()
                      : SellerScreen();
        },
        '/pedido': (context) => PedidoScreen(
              cart: [],
            ),
      },
       
    );
  }
}

void main() {
  runApp(EmpresaBotellonesApp());
}
