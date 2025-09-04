import 'package:flutter/material.dart';
import '../services/user_service.dart';


class AdminUserController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController(); // <-- nuevo
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  String selectedRole = 'vendedor';

  void dispose() {
    nameController.dispose();
    phoneController.dispose(); // <-- nuevo
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
  }

  Future<String?> crearUsuario() async {
    // Validación básica
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty || // <-- nuevo
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        repeatPasswordController.text.isEmpty) {
      return 'Por favor completa todos los campos';
    }

    if (passwordController.text != repeatPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }

    // Crear usuario usando UserService
    final success = await UserService.createUser({
      'nombre': nameController.text.trim(),
      'telefono': phoneController.text.trim(), // <-- nuevo
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
      'activado':true,
      'tipo_usuario': selectedRole,
    });

    if (!success) {
      return 'Error al crear usuario';
    }

    return null; // todo bien
  }
}
