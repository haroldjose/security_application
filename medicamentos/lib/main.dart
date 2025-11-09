// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionmedicamentos/core/supabase_config.dart';
import 'package:gestionmedicamentos/data/repositories/app_repository_impl.dart';
import 'package:gestionmedicamentos/core/logger.dart';
import 'theme.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/admin_panel_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.init();
  await AppRepositoryImpl.initSupabase(
    supabaseUrl: SupabaseConfig.url,
    supabaseAnonKey: SupabaseConfig.anonKey,
  );

  // ✅ Manejo global de errores sin romper la zona
  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: MainApp()));
    },
    (error, stackTrace) {
      appLogger.e('❌ Error no capturado', error: error, stackTrace: stackTrace);
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Medicamentos',
      theme: AppTheme.lightTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/admin': (_) => const AdminPanelPage(),
      },
    );
  }
}







// // lib/main.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:gestionmedicamentos/core/supabase_config.dart';
// import 'package:gestionmedicamentos/data/repositories/app_repository_impl.dart';
// import 'package:gestionmedicamentos/core/logger.dart';

// import 'theme.dart';
// import 'presentation/pages/login_page.dart';
// import 'presentation/pages/admin_panel_page.dart'; // para la ruta '/admin'

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await SupabaseConfig.init();
//   await AppRepositoryImpl.initSupabase(
//     supabaseUrl: SupabaseConfig.url,
//     supabaseAnonKey: SupabaseConfig.anonKey,
//   );

//   runZonedGuarded(
//     () => runApp(const ProviderScope(child: MainApp())),
//     (error, stackTrace) => appLogger.e(
//       'Uncaught Error',
//       error: error,
//       stackTrace: stackTrace,
//     ),
//   );
// }

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Gestión de Medicamentos',
//       theme: AppTheme.lightTheme(),
//       initialRoute: '/login',
//       routes: {
//         '/login': (_) => const LoginPage(),
//         '/admin': (_) => const AdminPanelPage(),
//       },
//     );
//   }
// }

