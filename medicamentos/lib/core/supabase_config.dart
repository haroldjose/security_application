import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración global de Supabase
class SupabaseConfig {
  static const String url = 'https://vqwdilpektnhxhjpluyk.supabase.co';


  /// Usa la SERVICE ROLE KEY (la larga, que empieza con "eyJhbGciOiJI...")
  static const String serviceRoleKey = '';

  /// Clave anónima (modo seguro para usuarios normales)
  static const String anonKey = '';

  /// Inicializa Supabase con clave anónima (modo normal)
  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: kDebugMode,
    );
    debugPrint('✅ Supabase inicializado correctamente');
  }

  /// Cliente para operaciones normales (usuarios)
  static SupabaseClient get client => Supabase.instance.client;

  /// Cliente con permisos de administrador (solo en modo desarrollo)
  static SupabaseClient get adminClient =>
      SupabaseClient(url, serviceRoleKey);
}







// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// /// Configuración global de Supabase
// class SupabaseConfig {
//   static const String url = 'https://vqwdilpektnhxhjpluyk.supabase.co';
//   static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd2RpbHBla3RuaHhoanBsdXlrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3NTgyMjgsImV4cCI6MjA3NzMzNDIyOH0.298GdqJGmwuy6LPHxfUHpgwtvHBW-mdh3OaQrwnQMZ8';

//   /// Inicializa Supabase y habilita Auth en AppRepositoryImpl.
//   static Future<void> init() async {
//     await Supabase.initialize(
//       url: url,
//       anonKey: anonKey,
//       debug: kDebugMode,
//     );
//     debugPrint('✅ Supabase inicializado correctamente');
//   }

//   static SupabaseClient get client => Supabase.instance.client;
// }
