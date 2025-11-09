// lib/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bcrypt/bcrypt.dart';

import 'package:gestionmedicamentos/core/sanitize.dart';
import 'package:gestionmedicamentos/core/logger.dart';

import 'package:gestionmedicamentos/domain/entities/user.dart';
import '../../application/providers/user_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  String role = 'admin'; // 'admin' | 'encargado' | 'doctor'

  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final specialtyController = TextEditingController(); // para 'doctor'
  final areaController = TextEditingController();      // para 'encargado'

  final _usernameRegex = RegExp(r'^[A-Za-zÀ-ÿ\s]+[0-9]{2}$');
  final _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{16,}$');

  String? _validateUsername(String value) {
    if (value.isEmpty) return 'El nombre de usuario es obligatorio';
    if (!_usernameRegex.hasMatch(value)) {
      return 'Formato: nombre + 2 dígitos (ej. "carlos12")';
    }
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'La contraseña es obligatoria';
    if (!_passwordRegex.hasMatch(value)) {
      return 'Mín. 16 caracteres, incluir mayúscula, minúscula, número y especial';
    }
    return null;
  }

  String? _validateRoleFields() {
    if (role == 'doctor' && specialtyController.text.trim().isEmpty) {
      return 'La especialidad es obligatoria para rol Doctor';
    }
    if (role == 'encargado' && areaController.text.trim().isEmpty) {
      return 'El área es obligatoria para rol Encargado';
    }
    return null;
  }

  Future<void> register() async {
    final rawName = nameController.text;
    final name = sanitize(rawName);
    final passwordPlain = passwordController.text.trim();
    final specialty = role == 'doctor' ? specialtyController.text.trim() : null;
    final area = role == 'encargado' ? areaController.text.trim() : null;

    final userError = _validateUsername(name);
    final passError = _validatePassword(passwordPlain);
    final roleError = _validateRoleFields();

    if (userError != null || passError != null || roleError != null) {
      final msg = userError ?? passError ?? roleError!;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    try {
      final passwordHash = BCrypt.hashpw(passwordPlain, BCrypt.gensalt());

      final user = UserEntity(
        name: name,
        password: passwordHash, // se guarda hash en SQLite
        role: role,
        specialty: specialty,
        area: area,
      );

      await ref.read(userNotifierProvider).register(user);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado con éxito')),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      appLogger.e('Error registrando usuario', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 3,
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded, size: 60, color: Color(0xFF3498DB)),
                    const SizedBox(height: 12),
                    Text(
                      'Crear una nueva cuenta',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(
                        labelText: 'Rol de usuario',
                        prefixIcon: Icon(Icons.manage_accounts_outlined),
                      ),
                      onChanged: (value) => setState(() => role = value ?? 'admin'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                        DropdownMenuItem(value: 'encargado', child: Text('Encargado de Farmacia')),
                        DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario (nombre+2 dígitos)',
                        helperText: 'Ejemplo: carlos12',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña (>=16, fuerte)',
                        helperText: 'Debe incluir mayúscula, minúscula, número y especial',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),

                    if (role == 'doctor') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: specialtyController,
                        decoration: const InputDecoration(
                          labelText: 'Especialidad (Doctor)',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                        ),
                      ),
                    ],
                    if (role == 'encargado') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: areaController,
                        decoration: const InputDecoration(
                          labelText: 'Área (Encargado de Farmacia)',
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: register,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Registrarse'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
