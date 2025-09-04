import 'dart:convert';
import 'package:bluicefrontend/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pedido_screen.dart';
import '../controllers/order_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> productos = [];
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> pedidosUsuario = [];
  int _selectedIndex = 1; // Por defecto mostrar Productos

  final String apiUrl = "$baseUrl/productos";

  @override
  void initState() {
    super.initState();
    obtenerProductos();
    cargarPedidosUsuario();
  }

  Future<void> obtenerProductos() async {
    try {
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        setState(() {
          productos = jsonDecode(res.body);
          for (var p in productos) {
            p['cantidadSeleccionada'] = 0;
          }
        });
      } else {
        print("Error al cargar productos: ${res.statusCode}");
      }
    } catch (e) {
      print("Error al obtener productos: $e");
    }
  }

  Future<void> cargarPedidosUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('userId');
      if (usuarioId == null) return;
      final pedidosPendientes = await OrderService.getOrdersByUser(usuarioId);
      setState(() {
        pedidosUsuario = pedidosPendientes ?? [];
      });
    } catch (e) {
      print("Error al cargar pedidos del usuario: $e");
    }
  }

  void agregarAlCarrito(Map<String, dynamic> producto) {
    int cantidad = producto['cantidadSeleccionada'];
    if (cantidad <= 0) return;

    var index =
        cart.indexWhere((item) => item['idproducto'] == producto['idproducto']);
    if (index != -1) {
      cart[index]['quantity'] += cantidad;
    } else {
      cart.add({
        'idproducto': producto['idproducto'],
        'name': producto['nombre'],
        'price': double.tryParse(producto['preciounitario'].toString()) ?? 0.0,
        'quantity': cantidad,
        'imageUrl': producto['imagen'] ?? '',
      });
    }

    setState(() {
      producto['cantidadSeleccionada'] = 0;
    });
  }

  // Contenido de cada pestaña
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Perfil
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
                      backgroundImage: AssetImage(
                          'assets/logo.jpg'), // Reemplaza con tu logo
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
          // Footer parecido al de PedidosYa
        );
      case 1: // Inicio -> Productos
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                leading:
                    producto['imagen'] != null && producto['imagen'].isNotEmpty
                        ? Image.network(producto['imagen'],
                            width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported),
                title: Text(producto['nombre']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio: Bs${producto['preciounitario']}'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (producto['cantidadSeleccionada'] > 0)
                                producto['cantidadSeleccionada']--;
                            });
                          },
                        ),
                        Text('${producto['cantidadSeleccionada']}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              producto['cantidadSeleccionada']++;
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => agregarAlCarrito(producto),
                          child: const Text("Agregar al carrito"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case 2: // Pedidos
        if (pedidosUsuario.isEmpty) {
          return const Center(
              child: Text('No tienes pedidos pendientes o asignados.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pedidosUsuario.length,
          itemBuilder: (context, index) {
            final pedido = pedidosUsuario[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Text(
                    'Pedido #${pedido['id']} - Estado: ${pedido['estado']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monto total: Bs${pedido['monto_total']}'),
                    if (pedido['direccion'] != null)
                      Text('Dirección: ${pedido['direccion']}'),
                  ],
                ),
              ),
            );
          },
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? "Perfil"
            : _selectedIndex == 1
                ? "Productos"
                : "Mis Pedidos"),
        actions: _selectedIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PedidoScreen(cart: cart),
                      ),
                    );
                  },
                )
              ]
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Pedidos"),
        ],
      ),
    );
  }
}
