import 'dart:ffi';

import 'package:bluicefrontend/src/controllers/order_controller.dart';
import 'package:bluicefrontend/src/controllers/product_controller.dart';
import 'package:flutter/material.dart';
import 'package:bluicefrontend/src/screens/profile_screen.dart';
import 'package:bluicefrontend/src/screens/map_screen.dart';
import 'package:bluicefrontend/src/controllers/admin_user_controller.dart';
import 'package:bluicefrontend/src/services/user_service.dart'; // Nuevo servicio para usuarios
import 'package:latlong2/latlong.dart';


// ================= AdminScreen principal =================
class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = <Widget>[
    ProfileScreen(),
    UsersScreen(), // Nueva pantalla con 3 subpestañas
    RegisterOrderScreen(),
    AssignOrderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Administrador')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart),
            label: 'Registrar Pedido',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Asignar Pedido',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ================= Pantalla Usuarios con subpestañas =================
class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Agregar'),
            Tab(text: 'Editar/Listar'),
            Tab(text: 'Eliminar'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              CreateUserScreen(), // Agregar usuario
              EditUserScreen(), // Editar/Listar usuarios
              DeleteUserScreen(), // Eliminar usuarios
            ],
          ),
        ),
      ],
    );
  }
}

// ================= Crear usuario =================
class CreateUserScreen extends StatefulWidget {
  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final controller = AdminUserController();
  final _formKey = GlobalKey<FormState>();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text('Usuarios',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // ====== Nombre ======
            TextFormField(
              controller: controller.nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
              validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
            ),

            SizedBox(height: 10),
            // ====== Teléfono ======
            TextFormField(
              controller: controller.phoneController,
              decoration: InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
              validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
            ),

            SizedBox(height: 10),
            // ====== Correo ======
            TextFormField(
              controller: controller.emailController,
              decoration: InputDecoration(labelText: 'Correo Electrónico'),
              validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
            ),
            SizedBox(height: 10),
            // ====== Contraseña ======
            TextFormField(
              controller: controller.passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              validator: (value) =>
                  value!.length < 6 ? 'Debe tener al menos 6 caracteres' : null,
            ),
            SizedBox(height: 10),
            // ====== Repetir contraseña ======
            TextFormField(
              controller: controller.repeatPasswordController,
              decoration: InputDecoration(labelText: 'Repetir Contraseña'),
              obscureText: true,
              validator: (value) => value != controller.passwordController.text
                  ? 'Las contraseñas no coinciden'
                  : null,
            ),
            SizedBox(height: 10),
            // ====== Rol ======
            DropdownButtonFormField<String>(
              value: controller.selectedRole,
              decoration: InputDecoration(labelText: 'Rol'),
              items: [
                DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                DropdownMenuItem(value: 'conductor', child: Text('Conductor')),
                DropdownMenuItem(
                    value: 'administrador', child: Text('Administrador')),
              ],
              onChanged: (value) {
                setState(() {
                  controller.selectedRole = value!;
                });
              },
            ),
            if (error != null) ...[
              SizedBox(height: 10),
              Text(error!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final result = await controller.crearUsuario();
                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Usuario creado exitosamente')),
                    );
                    _formKey.currentState!.reset();
                  } else {
                    setState(() => error = result);
                  }
                }
              },
              child: Text('Crear Usuario'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Editar/Listar usuarios =================
class EditUserScreen extends StatefulWidget {
  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final result = await UserService.getUsers();
    setState(() {
      users = result ?? [];
      isLoading = false;
    });
  }

  void editUser(Map<String, dynamic> user) async {
    TextEditingController nameController =
        TextEditingController(text: user['nombre']);
    TextEditingController phoneController =
        TextEditingController(text: user['telefono'] ?? ''); // <-- nuevo
    TextEditingController emailController =
        TextEditingController(text: user['email']);
    String selectedRole = user['tipo_usuario'];

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar Usuario'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== Nombre =====
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo requerido' : null,
                ),

                SizedBox(height: 10),
                // ===== Teléfono =====
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value!.isEmpty ? 'Campo requerido' : null,
                ),

                SizedBox(height: 10),
                // ===== Correo =====
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Correo'),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo requerido' : null,
                ),

                SizedBox(height: 10),
                // ===== Rol =====
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'Rol'),
                  items: [
                    DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                    DropdownMenuItem(
                        value: 'vendedor', child: Text('Vendedor')),
                    DropdownMenuItem(
                        value: 'conductor', child: Text('Conductor')),
                    DropdownMenuItem(
                        value: 'administrador', child: Text('Administrador')),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                bool success =
                    await UserService.updateUser(user['id'].toString(), {
                  'nombre': nameController.text.trim(),
                  'telefono': phoneController.text.trim(), // <-- nuevo
                  'email': emailController.text.trim(),
                  'rol': selectedRole,
                });
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Usuario actualizado')),
                  );
                  fetchUsers(); // refresca la lista
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar usuario')),
                  );
                }
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            title: Text(user['nombre']),
            subtitle:
                Text('Correo: ${user['email']} - Rol: ${user['tipo_usuario']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Editar
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => editUser(user),
                ),
                // Botón Direcciones solo si el usuario es cliente
                if (user['tipo_usuario'] == 'cliente')
                  IconButton(
                    icon: Icon(Icons.location_on_outlined),
                    tooltip: 'Direcciones',
                    onPressed: () {
                      // Aquí puedes abrir la pantalla de direcciones del usuario
                      Navigator.pushNamed(
                        context,
                        '/userAddresses', // asegúrate de crear esta ruta
                        arguments: user['id'], // pasamos el id del cliente
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= Eliminar usuarios =================
class DeleteUserScreen extends StatefulWidget {
  @override
  _DeleteUserScreenState createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final result = await UserService.getUsers();
    setState(() {
      users = result ?? [];
      isLoading = false;
    });
  }

  void deleteUser(String id) async {
    final success = await UserService.deleteUser(id);
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Usuario eliminado')));
      fetchUsers(); // refresca la lista
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            title: Text(user['nombre']),
            subtitle: Text('Correo: ${user['email']}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => deleteUser(user['id'].toString()),
            ),
          ),
        );
      },
    );
  }
}

// ================= Registrar Pedido =================
class RegisterOrderScreen extends StatefulWidget {
  @override
  _RegisterOrderScreenState createState() => _RegisterOrderScreenState();
}

class _RegisterOrderScreenState extends State<RegisterOrderScreen> {
  TextEditingController clientNameController = TextEditingController();
  TextEditingController additionalInfoController = TextEditingController();

  final ProductController productController = ProductController();
  List<Map<String, dynamic>> productosDisponibles = [];
  Map<int, int> productosSeleccionados = {}; // productoId -> cantidad
  bool isLoadingProducts = true;

  List<Map<String, dynamic>> clientes = [];
  Map<String, dynamic>? clienteSeleccionado;
  bool isLoadingClientes = true;

  List<Map<String, dynamic>> direcciones = [];
  Map<String, dynamic>? direccionSeleccionada;

  @override
  void initState() {
    super.initState();
    fetchProductosDisponibles();
    fetchClientes();
  }

  Future<void> fetchProductosDisponibles() async {
    try {
      final data = await productController.fetchProducts();
      setState(() {
        productosDisponibles = data;
        isLoadingProducts = false;
      });
    } catch (e) {
      print('Error al cargar productos: $e');
      setState(() => isLoadingProducts = false);
    }
  }

  Future<void> fetchClientes() async {
    try {
      final data = await UserService.getUsers();
      setState(() {
        clientes = List<Map<String, dynamic>>.from(
            data?.where((u) => u['tipo_usuario'] == 'cliente') ?? []);
        isLoadingClientes = false;
      });
    } catch (e) {
      print('Error al cargar clientes: $e');
      setState(() => isLoadingClientes = false);
    }
  }

  Future<void> cargarDireccionesCliente(int userId) async {
    try {
      final listaDirecciones = await UserService.getUserAddresses(userId);
      setState(() {
        direcciones = listaDirecciones
                ?.map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e))
                .toList() ??
            [];
        direccionSeleccionada = direcciones.isNotEmpty ? direcciones.first : null;
      });
    } catch (e) {
      print("Error cargando direcciones: $e");
    }
  }

  Future<void> agregarNuevaDireccion(int userId) async {
    final direccionController = TextEditingController();
    final infoExtraControllerLocal = TextEditingController();
    double? latitud;
    double? longitud;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar nueva dirección"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(labelText: "Dirección"),
              ),
              TextField(
                controller: infoExtraControllerLocal,
                decoration: const InputDecoration(labelText: "Información extra"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        onLocationSelected: (LatLng loc) {
                          latitud = loc.latitude;
                          longitud = loc.longitude;
                        },
                      ),
                    ),
                  );
                  if (latitud != null && longitud != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Ubicación seleccionada: ${latitud!.toStringAsFixed(5)}, ${longitud!.toStringAsFixed(5)}",
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text("Seleccionar ubicación en mapa"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (direccionController.text.isEmpty ||
                  latitud == null ||
                  longitud == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Completa todos los campos")),
                );
                return;
              }

              final data = {
                "direccion": direccionController.text,
                "info_extra": infoExtraControllerLocal.text,
                "latitud": latitud,
                "longitud": longitud,
              };

              bool success = await UserService.createUserAddress(userId, data);

              if (success) {
                Navigator.pop(context);
                cargarDireccionesCliente(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Dirección agregada con éxito")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error al agregar dirección")),
                );
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  void seleccionarProducto(int productoId, int cantidad) {
    setState(() {
      if (cantidad > 0) {
        productosSeleccionados[productoId] = cantidad;
      } else {
        productosSeleccionados.remove(productoId);
      }
    });
  }

  @override
  void dispose() {
    clientNameController.dispose();
    additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar Pedido',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ===== Dropdown Clientes =====
            isLoadingClientes
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<Map<String, dynamic>>(
                    hint: const Text('Selecciona un cliente'),
                    value: clienteSeleccionado,
                    items: clientes.map((cliente) {
                      return DropdownMenuItem(
                        value: cliente,
                        child: Text(cliente['nombre']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        clienteSeleccionado = value;
                        clientNameController.text = value?['nombre'] ?? '';
                        if (value != null) {
                          cargarDireccionesCliente(value['id']);
                        }
                      });
                    },
                  ),
            const SizedBox(height: 10),
            TextField(
              controller: clientNameController,
              decoration: const InputDecoration(labelText: 'Nombre del Cliente'),
            ),

            const SizedBox(height: 20),

            // ===== Dropdown Direcciones =====
            if (clienteSeleccionado != null)
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: direccionSeleccionada,
                      hint: const Text("Selecciona dirección"),
                      items: direcciones
                          .map((dir) => DropdownMenuItem(
                                value: dir,
                                child: Text(dir['direccion']),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          direccionSeleccionada = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () {
                      if (clienteSeleccionado != null) {
                        agregarNuevaDireccion(clienteSeleccionado!['id']);
                      }
                    },
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // ===== Productos =====
            Text('Productos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            isLoadingProducts
                ? const CircularProgressIndicator()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productosDisponibles.length,
                    itemBuilder: (context, index) {
                      final p = productosDisponibles[index];
                      int cantidad = productosSeleccionados[p['idproducto']] ?? 0;
                      return Card(
                        child: ListTile(
                          title: Text('${p['nombre']} - ${p['preciounitario']} Bs'),
                          subtitle: Text('Stock: ${p['cantidad']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () =>
                                      seleccionarProducto(p['idproducto'], cantidad - 1)),
                              Text('$cantidad'),
                              IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () =>
                                      seleccionarProducto(p['idproducto'], cantidad + 1)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 20),

            // ===== Botón Registrar Pedido =====
         ElevatedButton(
  child: const Text('Registrar Pedido'),
  onPressed: () async {
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
      return;
    }

    if (productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un producto')),
      );
      return;
    }

    // Construimos el pedido con los IDs correctos
    final pedido = {
      "usuario_id": clienteSeleccionado!['id'],
      "direccion_id": direccionSeleccionada?['id'],
      "direccion": direccionSeleccionada?['direccion'] ?? '',
      "latitud": direccionSeleccionada?['latitud'],
      "longitud": direccionSeleccionada?['longitud'],
      "info_extra": additionalInfoController.text,
      "productos": productosSeleccionados.entries
          .map((e) => {
                "producto_id": e.key, 
                "cantidad": e.value
              })
          .toList(),
    };

    final pedidoId = await OrderService.crearPedido(pedido);

    if (pedidoId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido registrado exitosamente')),
      );
      setState(() {
        clienteSeleccionado = null;
        direccionSeleccionada = null;
        clientNameController.clear();
        additionalInfoController.clear();
        productosSeleccionados.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar pedido')),
      );
    }
  },
),

          ],
        ),
      ),
    );
  }
}

class AssignOrderScreen extends StatefulWidget {
  @override
  _AssignOrderScreenState createState() => _AssignOrderScreenState();
}

class _AssignOrderScreenState extends State<AssignOrderScreen> {
  List<Map<String, dynamic>> conductores = [];
  List<Map<String, dynamic>> pedidosPendientes = [];
  bool isLoadingConductores = true;
  bool isLoadingPedidos = true;

  @override
  void initState() {
    super.initState();
    fetchConductores();
    fetchPedidosPendientes();
  }

  Future<void> fetchConductores() async {
    try {
      final data = await UserService.getUsers();
      setState(() {
        conductores = List<Map<String, dynamic>>.from(
            data?.where((u) => u['tipo_usuario'] == 'conductor') ?? []);
        isLoadingConductores = false;
      });
    } catch (e) {
      print('Error cargando conductores: $e');
      setState(() => isLoadingConductores = false);
    }
  }

  Future<void> fetchPedidosPendientes() async {
    try {
      final data = await OrderService.getPendingConductor(); // Debe traer solo pendientes
      setState(() {
        pedidosPendientes = data ?? [];
        isLoadingPedidos = false;
      });
    } catch (e) {
      print('Error cargando pedidos pendientes: $e');
      setState(() => isLoadingPedidos = false);
    }
  }

  void openAssignModal(Map<String, dynamic> conductor) {
    Map<String, dynamic>? pedidoSeleccionado;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Asignar pedido a ${conductor['nombre']}'),
        content: isLoadingPedidos
            ? Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<Map<String, dynamic>>(
                hint: Text('Selecciona un pedido'),
                value: pedidoSeleccionado,
                items: pedidosPendientes.map((pedido) {
                  return DropdownMenuItem(
                    value: pedido,
                    child: Text(
                        'Pedido #${pedido['id']} - ${pedido['usuario_nombre']} - ${pedido['direccion']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  pedidoSeleccionado = value;
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pedidoSeleccionado == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selecciona un pedido')),
                );
                return;
              }
              bool success = await OrderService.assignOrder(
                pedidoSeleccionado!['id'],
                conductor['id'],
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pedido asignado exitosamente')),
                );
                Navigator.pop(context);
                fetchPedidosPendientes(); // refresca pedidos
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al asignar pedido')),
                );
              }
            },
            child: Text('Asignar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingConductores) return Center(child: CircularProgressIndicator());

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: conductores.length,
      itemBuilder: (context, index) {
        final conductor = conductores[index];
        return Card(
          child: ListTile(
            title: Text(conductor['nombre']),
            subtitle: Text(conductor['email'] ?? ''),
            trailing: ElevatedButton(
              onPressed: () => openAssignModal(conductor),
              child: Text('Ver'),
            ),
          ),
        );
      },
    );
  }
}
