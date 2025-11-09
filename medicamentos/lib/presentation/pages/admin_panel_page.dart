import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gestionmedicamentos/core/services/admin_api_service.dart';
import 'package:gestionmedicamentos/core/sanitize.dart';
import 'package:gestionmedicamentos/core/logger.dart';
import 'package:gestionmedicamentos/application/providers/user_provider.dart';
import 'package:gestionmedicamentos/domain/entities/user.dart';

class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
  bool loading = false;
  List<UserEntity> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Carga los usuarios desde SQLite (repositorio local)
  Future<void> _loadUsers() async {
    try {
      final notifier = ref.read(userNotifierProvider);
      final list = await notifier.repository.getAllUsers();
      if (mounted) setState(() => users = list);
    } catch (e, st) {
      appLogger.e('Error cargando usuarios', error: e, stackTrace: st);
    }
  }

  /// 🔐 Restablecer contraseña
  Future<void> _handleResetPassword(String email) async {
    setState(() => loading = true);
    try {
      final result = await AdminApiService.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${result['message']} Nueva: ${result['newPassword']}',
          ),
        ),
      );
    } catch (e, st) {
      appLogger.e('Error reseteando contraseña', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// 🗑️ Eliminar usuario tanto remoto (Supabase) como local (SQLite)
  Future<void> _handleDeleteUser(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar usuario'),
            content: Text('¿Seguro que deseas eliminar "$email"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => loading = true);
    try {
      // 1️⃣ Eliminar de Supabase Auth
      final result = await AdminApiService.deleteUser(email);

      // 2️⃣ Eliminar también del almacenamiento local (SQLite)
      final name = email.split('@').first;
      final notifier = ref.read(userNotifierProvider);
      final localUsers = await notifier.repository.getAllUsers();
      final target = localUsers.firstWhere(
        (u) => u.name == name,
        orElse: () => UserEntity(name: '', password: '', role: 'doctor'),
      );

      if (target.name.isNotEmpty) {
        // Eliminamos usando un método seguro del repositorio
        await notifier.repository.deleteUserLocal(name);
      }

      // 3️⃣ Recargar lista
      await _loadUsers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🗑️ ${result['message']} (también eliminado localmente)',
          ),
        ),
      );
    } catch (e, st) {
      appLogger.e('Error eliminando usuario', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// MFA
  Future<void> _handleEnableMfa(String email) async {
    setState(() => loading = true);
    try {
      final result = await AdminApiService.enableMfa(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('🔐 ${result['message']}')));
    } catch (e, st) {
      appLogger.e('Error activando MFA', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// 🔐 Genera una contraseña fuerte aleatoria
  String _generateSecurePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()-_=+<>?';
    final random = Random.secure();
    return List.generate(18, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Crear usuario desde diálogo
    void _showCreateUserDialog() {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: _generateSecurePassword());
    final specialtyCtrl = TextEditingController();
    final areaCtrl = TextEditingController();

    bool showPassword = false;
    String role = 'doctor';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Registrar nuevo usuario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      helperText: 'Debe incluir al menos 2 letras y 2 dígitos (ej: juan23)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passCtrl,
                    obscureText: !showPassword,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña generada',
                      suffixIcon: IconButton(
                        icon: Icon(showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setStateDialog(() => showPassword = !showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(
                          value: 'admin', child: Text('Administrador')),
                      DropdownMenuItem(
                          value: 'encargado',
                          child: Text('Encargado de farmacia')),
                      DropdownMenuItem(
                          value: 'doctor', child: Text('Doctor')),
                    ],
                    onChanged: (v) => setStateDialog(() => role = v!),
                    decoration: const InputDecoration(labelText: 'Rol'),
                  ),
                  const SizedBox(height: 8),
                  if (role == 'doctor')
                    TextField(
                      controller: specialtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Especialidad',
                        hintText: 'Ej: Cardiología',
                      ),
                    ),
                  if (role == 'encargado')
                    TextField(
                      controller: areaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Área de trabajo',
                        hintText: 'Ej: Farmacia Central',
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  final name = sanitize(nameCtrl.text.trim());
                  final password = passCtrl.text.trim();
                  final specialty = specialtyCtrl.text.trim();
                  final area = areaCtrl.text.trim();

                  // 🧩 Validación del nombre (2 letras + 2 dígitos)
                  final validUser = RegExp(r'^(?=.*[A-Za-z]{2,})(?=.*\d{2,}).+$');
                  if (!validUser.hasMatch(name)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              '❌ El nombre debe tener nombre usuario y 2 dígitos.')),
                    );
                    return;
                  }

                  try {
                    // Crear en Supabase Auth y tabla users
                    await AdminApiService.createUser(name, password, role);

                    // Guardar también localmente
                    final notifier = ref.read(userNotifierProvider);
                    await notifier.register(
                      UserEntity(
                        id: null,
                        name: name,
                        password: password,
                        role: role,
                        specialty: role == 'doctor' ? specialty : null,
                        area: role == 'encargado' ? area : null,
                        failedAttempts: 0,
                        lockUntilEpochMs: null,
                      ),
                    );

                    if (mounted) Navigator.pop(context);
                    await _loadUsers();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Usuario "$name" creado.\nContraseña: $password',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    );
                  } catch (e, st) {
                    appLogger.e('Error creando usuario', error: e, stackTrace: st);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: $e')),
                    );
                  }
                },
                child: const Text('Registrar'),
              ),
            ],
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(currentUserProvider.notifier).state = null;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? const Center(child: Text('No hay usuarios registrados'))
                : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final email = '${u.name}@local.app';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('${u.name} (${u.role})'),
                        subtitle: Text(u.specialty ?? u.area ?? ''),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'reset') _handleResetPassword(email);
                            if (action == 'mfa') _handleEnableMfa(email);
                            if (action == 'delete') _handleDeleteUser(email);
                          },
                          itemBuilder:
                              (_) => const [
                                PopupMenuItem(
                                  value: 'reset',
                                  child: Text('Restablecer contraseña'),
                                ),
                                PopupMenuItem(
                                  value: 'mfa',
                                  child: Text('Activar MFA'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar usuario'),
                                ),
                              ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

// // lib/presentation/pages/admin_panel_page.dart
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:gestionmedicamentos/core/services/admin_api_service.dart';
// import 'package:gestionmedicamentos/core/sanitize.dart';
// import 'package:gestionmedicamentos/core/logger.dart';
// import 'package:gestionmedicamentos/application/providers/user_provider.dart';
// import 'package:gestionmedicamentos/domain/entities/user.dart';

// class AdminPanelPage extends ConsumerStatefulWidget {
//   const AdminPanelPage({super.key});

//   @override
//   ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
// }

// class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
//   bool loading = false;
//   List<UserEntity> users = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadUsers();
//   }

//   Future<void> _loadUsers() async {
//     try {
//       final notifier = ref.read(userNotifierProvider);
//       final list = await notifier.repository.getAllUsers();
//       if (mounted) setState(() => users = list);
//     } catch (e, st) {
//       appLogger.e('Error cargando usuarios', error: e, stackTrace: st);
//     }
//   }

//   Future<void> _handleResetPassword(String email) async {
//     setState(() => loading = true);
//     try {
//       final result = await AdminApiService.resetPassword(email);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('✅ ${result['message']} Nueva: ${result['newPassword']}')),
//       );
//     } catch (e, st) {
//       appLogger.e('Error reseteando contraseña', error: e, stackTrace: st);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   Future<void> _handleDeleteUser(String email) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Eliminar usuario'),
//         content: Text('¿Seguro que deseas eliminar "$email"?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     setState(() => loading = true);
//     try {
//       final result = await AdminApiService.deleteUser(email);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('🗑️ ${result['message']}')),
//       );
//       await _loadUsers();
//     } catch (e, st) {
//       appLogger.e('Error eliminando usuario', error: e, stackTrace: st);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   Future<void> _handleEnableMfa(String email) async {
//     setState(() => loading = true);
//     try {
//       final result = await AdminApiService.enableMfa(email);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('🔐 ${result['message']}')),
//       );
//     } catch (e, st) {
//       appLogger.e('Error activando MFA', error: e, stackTrace: st);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   /// 🔐 Genera una contraseña fuerte aleatoria (16–20 caracteres)
//   String _generateSecurePassword() {
//     const chars =
//         'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()-_=+<>?';
//     final random = Random.secure();
//     return List.generate(18, (_) => chars[random.nextInt(chars.length)]).join();
//   }

//   void _showCreateUserDialog() {
//     final nameCtrl = TextEditingController();
//     final passCtrl = TextEditingController(text: _generateSecurePassword());
//     bool showPassword = false;
//     String role = 'doctor';

//     showDialog(
//       context: context,
//       builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
//         return AlertDialog(
//           title: const Text('Registrar nuevo usuario'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameCtrl,
//                   decoration: const InputDecoration(labelText: 'Nombre de usuario'),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: passCtrl,
//                   obscureText: !showPassword,
//                   readOnly: true,
//                   decoration: InputDecoration(
//                     labelText: 'Contraseña generada',
//                     suffixIcon: IconButton(
//                       icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
//                       onPressed: () => setStateDialog(() => showPassword = !showPassword),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 DropdownButtonFormField<String>(
//                   value: role,
//                   items: const [
//                     DropdownMenuItem(value: 'admin', child: Text('Administrador')),
//                     DropdownMenuItem(value: 'encargado', child: Text('Encargado de farmacia')),
//                     DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
//                   ],
//                   onChanged: (v) => role = v!,
//                   decoration: const InputDecoration(labelText: 'Rol'),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
//             ElevatedButton(
//               onPressed: () async {
//                 final name = sanitize(nameCtrl.text.trim());
//                 final password = passCtrl.text.trim();

//                 if (name.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('El nombre no puede estar vacío')),
//                   );
//                   return;
//                 }

//                 try {
//                   // ✅ Crear usuario mediante el backend seguro
//                   await AdminApiService.createUser(name, password, role);

//                   // ✅ Sincronizar también localmente
//                   final notifier = ref.read(userNotifierProvider);
//                   await notifier.register(
//                     UserEntity(
//                       id: null,
//                       name: name,
//                       password: password,
//                       role: role,
//                       specialty: role == 'doctor' ? 'General' : null,
//                       area: role == 'encargado' ? 'Farmacia Central' : null,
//                       failedAttempts: 0,
//                       lockUntilEpochMs: null,
//                     ),
//                   );

//                   if (mounted) Navigator.pop(context);
//                   await _loadUsers();

//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         '✅ Usuario "$name" creado.\nContraseña: $password',
//                         style: const TextStyle(fontFamily: 'monospace'),
//                       ),
//                     ),
//                   );
//                 } catch (e, st) {
//                   appLogger.e('Error creando usuario', error: e, stackTrace: st);
//                   if (!mounted) return;
//                   ScaffoldMessenger.of(context)
//                       .showSnackBar(SnackBar(content: Text('❌ Error: $e')));
//                 }
//               },
//               child: const Text('Registrar'),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Panel de Administración'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               ref.read(currentUserProvider.notifier).state = null;
//               Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
//             },
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showCreateUserDialog,
//         child: const Icon(Icons.add),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: loading
//             ? const Center(child: CircularProgressIndicator())
//             : users.isEmpty
//                 ? const Center(child: Text('No hay usuarios registrados'))
//                 : ListView.builder(
//                     itemCount: users.length,
//                     itemBuilder: (_, i) {
//                       final u = users[i];
//                       final email = '${u.name}@local.app';
//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 6),
//                         child: ListTile(
//                           title: Text('${u.name} (${u.role})'),
//                           subtitle: Text(u.specialty ?? u.area ?? ''),
//                           trailing: PopupMenuButton<String>(
//                             onSelected: (action) {
//                               if (action == 'reset') _handleResetPassword(email);
//                               if (action == 'mfa') _handleEnableMfa(email);
//                               if (action == 'delete') _handleDeleteUser(email);
//                             },
//                             itemBuilder: (_) => const [
//                               PopupMenuItem(value: 'reset', child: Text('Restablecer contraseña')),
//                               PopupMenuItem(value: 'mfa', child: Text('Activar MFA')),
//                               PopupMenuItem(value: 'delete', child: Text('Eliminar usuario')),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//       ),
//     );
//   }
// }
