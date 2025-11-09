// lib/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionmedicamentos/core/supabase_config.dart';
import 'package:gestionmedicamentos/core/logger.dart';
import 'package:gestionmedicamentos/core/sanitize.dart';
import 'package:gestionmedicamentos/application/providers/user_provider.dart';

// Dashboards
import 'package:gestionmedicamentos/presentation/pages/admin_panel_page.dart';
import 'package:gestionmedicamentos/presentation/pages/admin_dashboard.dart';
import 'package:gestionmedicamentos/presentation/pages/doctor_dashboard.dart';
import 'package:gestionmedicamentos/presentation/pages/register_page.dart';
import 'package:gestionmedicamentos/presentation/pages/mfa_verify_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({Key? key}) : super(key: key);

  /// Obtiene el rol del usuario desde la tabla pública `users`
  Future<String> _fetchRoleFromSupabase(String name) async {
    try {
      final res =
          await SupabaseConfig.client
              .from('users')
              .select('role')
              .eq('name', name)
              .maybeSingle();

      return (res?['role'] as String?) ?? 'doctor';
    } catch (e, st) {
      appLogger.w(
        '⚠️ No se pudo obtener el rol desde Supabase',
        error: e,
        stackTrace: st,
      );
      return 'doctor';
    }
  }

  /// Redirige según rol
  Future<void> _goToDashboard(
    BuildContext context,
    String role,
    String name,
    WidgetRef ref,
  ) async {
    final cached = ref.read(currentUserProvider);
    final fetchedUser =
        cached ??
        await ref.read(userNotifierProvider).repository.getUser(name, '');

    if (fetchedUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la información del usuario'),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    if (fetchedUser.role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelPage()),
      );
    } else if (fetchedUser.role == 'encargado') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EncargadoDashboard(user: fetchedUser),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DoctorDashboard(user: fetchedUser)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final supabase = SupabaseConfig.client;

    Future<void> login() async {
      final name = sanitize(nameController.text);
      final password = passwordController.text.trim();

      if (name.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todos los campos')),
        );
        return;
      }

      try {
        final pseudoEmail = '$name@local.app';

        // 🔐 Intento de login remoto con Supabase Auth
        final response = await supabase.auth.signInWithPassword(
          email: pseudoEmail,
          password: password,
        );

        if (!context.mounted) return;

        // Si el usuario tiene MFA → redirige a verificación
        if (response.user != null &&
            response.user!.factors?.isNotEmpty == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MfaVerifyPage(name: name)),
          );
          return;
        }

        // ✅ Login exitoso remoto
        if (response.user != null) {
          final role = await _fetchRoleFromSupabase(name);
          await _goToDashboard(context, role, name, ref);
          return;
        }

        throw Exception('Credenciales inválidas');
      } catch (e, st) {
        appLogger.w('⚠️ Supabase login falló', error: e, stackTrace: st);

        // 🔁 Fallback local con SQLite + bcrypt + lockout
        // final success = await ref.read(userNotifierProvider).login(name, password);
        try {
          final success = await ref
              .read(userNotifierProvider)
              .login(name, password);
          if (!context.mounted) return;

          final user = ref.read(currentUserProvider);
          if (success && user != null) {
            await _goToDashboard(context, user.role, user.name, ref);
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario o contraseña incorrectos')),
          );
        } catch (e) {
          // Muestra el mensaje detallado del bloqueo
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('⚠️ $e')));
        }
        if (!context.mounted) return;

        // final user = ref.read(currentUserProvider);
        // if (success && user != null) {
        //   await _goToDashboard(context, user.role, user.name, ref);
        //   return;
        // }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.medical_services_rounded,
                      size: 64,
                      color: Color(0xFF3498DB),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: login,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Ingresar'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Registrarse'),
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















// // // lib/presentation/pages/login_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:gestionmedicamentos/core/supabase_config.dart';
// import 'package:gestionmedicamentos/core/logger.dart';
// import 'package:gestionmedicamentos/core/sanitize.dart';


// import 'package:gestionmedicamentos/presentation/pages/admin_dashboard.dart';   // UI del Encargado (registro/edición medicamentos)
// import 'admin_panel_page.dart';      // UI del Administrador (gestionar usuarios)
// import 'doctor_dashboard.dart';
// import 'register_page.dart';
// import 'mfa_verify_page.dart';

// import '../../application/providers/user_provider.dart';

// class LoginPage extends ConsumerWidget {
//   const LoginPage({Key? key}) : super(key: key);

//   Future<String> _fetchRoleFromSupabase(String name) async {
//     final res = await SupabaseConfig.client
//         .from('users')
//         .select('role')
//         .eq('name', name)
//         .maybeSingle();

//     return (res?['role'] as String?) ?? 'doctor';
//   }

//   Future<void> _goToDashboard(
//     BuildContext context,
//     String role,
//     String name,
//     WidgetRef ref,
//   ) async {
//     // Si ya hay un usuario en memoria, úsalo. Si no, intenta obtenerlo del repo local.
//     final cached = ref.read(currentUserProvider);
//     final fetchedUser =
//         cached ?? await ref.read(userNotifierProvider).repository.getUser(name, '');

//     if (fetchedUser == null) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No se pudo obtener la información del usuario')),
//       );
//       return;
//     }

//     if (!context.mounted) return;

//     if (fetchedUser.role == 'admin') {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const AdminPanelPage()),
//       );
//     } else if (fetchedUser.role == 'encargado') {
//       // El “encargado” usa la pantalla de gestión de medicamentos
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => EncargadoDashboard(user: fetchedUser)),
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => DoctorDashboard(user: fetchedUser)),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final nameController = TextEditingController();
//     final passwordController = TextEditingController();
//     final supabase = SupabaseConfig.client;

//     Future<void> login() async {
//       final name = sanitize(nameController.text);
//       final password = passwordController.text.trim();

//       if (name.isEmpty || password.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Completa todos los campos')),
//         );
//         return;
//       }

//       try {
//         final pseudoEmail = '$name@local.app';

//         final response = await supabase.auth.signInWithPassword(
//           email: pseudoEmail,
//           password: password,
//         );

//         if (!context.mounted) return;

//         // MFA habilitado → ir a verificación
//         if (response.user != null && response.user!.factors?.isNotEmpty == true) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => MfaVerifyPage(name: name)),
//           );
//           return;
//         }

//         // Login exitoso con Supabase
//         if (response.user != null) {
//           final role = await _fetchRoleFromSupabase(name);
//           if (!context.mounted) return;
//           await _goToDashboard(context, role, name, ref);
//           return;
//         }

//         throw Exception('Credenciales inválidas');
//       } catch (e, st) {
//         appLogger.w('⚠️ Supabase login falló', error: e, stackTrace: st);

//         // Fallback: login local (SQLite + bcrypt + lockout)
//         final success = await ref.read(userNotifierProvider).login(name, password);
//         if (!context.mounted) return;

//         final user = ref.read(currentUserProvider);
//         if (success && user != null) {
//           await _goToDashboard(context, user.role, user.name, ref);
//           return;
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Usuario o contraseña incorrectos')),
//         );
//       }
//     }

//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.background,
//       body: Center(
//         child: SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 420),
//             child: Card(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               elevation: 3,
//               margin: const EdgeInsets.all(20),
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const Icon(Icons.medical_services_rounded, size: 64, color: Color(0xFF3498DB)),
//                     const SizedBox(height: 12),
//                     Text(
//                       'Iniciar sesión',
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: nameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Nombre de usuario',
//                         prefixIcon: Icon(Icons.person_outline),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: passwordController,
//                       obscureText: true,
//                       decoration: const InputDecoration(
//                         labelText: 'Contraseña',
//                         prefixIcon: Icon(Icons.lock_outline),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     FilledButton.icon(
//                       onPressed: login,
//                       icon: const Icon(Icons.login_rounded),
//                       label: const Text('Ingresar'),
//                     ),
//                     const SizedBox(height: 12),
//                     OutlinedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const RegisterPage()),
//                         );
//                       },
//                       icon: const Icon(Icons.person_add_alt_1_rounded),
//                       label: const Text('Registrarse'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
