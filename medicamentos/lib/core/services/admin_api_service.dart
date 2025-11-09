// lib/core/services/admin_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gestionmedicamentos/core/logger.dart';

/// 🔧 Servicio que comunica Flutter con el backend Node.js administrativo
class AdminApiService {
  /// ⚙️ URL base del backend (ajusta si usas otro entorno)
  static const String baseUrl = 'http://192.168.100.138:4000'; // ejemplo local
  static const String _authHeader = 'Bearer supersecreta123'; // debe coincidir con tu ADMIN_API_KEY del .env

  // ============================================================
  // 🧱 1. Crear nuevo usuario
  // ============================================================
  static Future<Map<String, dynamic>> createUser(
      String name, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authHeader,
        },
        body: jsonEncode({
          'name': name,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.body}');
      }
    } catch (e, st) {
      appLogger.e('Error creando usuario remoto', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ============================================================
  // 🧱 2. Restablecer contraseña
  // ============================================================
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authHeader,
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.body}');
      }
    } catch (e, st) {
      appLogger.e('Error reseteando contraseña', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ============================================================
  // 🧱 3. Eliminar usuario
  // ============================================================
  static Future<Map<String, dynamic>> deleteUser(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authHeader,
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.body}');
      }
    } catch (e, st) {
      appLogger.e('Error eliminando usuario remoto', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ============================================================
  // 🧱 4. Activar MFA
  // ============================================================
  static Future<Map<String, dynamic>> enableMfa(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enable-mfa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _authHeader,
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.body}');
      }
    } catch (e, st) {
      appLogger.e('Error activando MFA remoto', error: e, stackTrace: st);
      rethrow;
    }
  }
}


















// import 'dart:convert';
// import 'package:http/http.dart' as http;

// /// 🔧 Clase que gestiona las llamadas al backend Node.js
// class AdminApiService {
//   // 👉 URL base de tu backend
//   // Si estás probando localmente con emulador Android, usa tu IP local
//   // Ejemplo: "http://192.168.0.5:4000"
//   // Si está desplegado en Render/Railway, usa la URL https://...
//   static const String baseUrl = 'http://192.168.100.138:4000';

//   /// 🧱 Resetear contraseña
//   static Future<Map<String, dynamic>> resetPassword(String email) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/reset-password'),
//       headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer supersecreta123',},
//       body: jsonEncode({'email': email}),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Error: ${response.body}');
//     }
//   }

//   /// 🧱 Eliminar usuario
//   static Future<Map<String, dynamic>> deleteUser(String email) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/delete-user'),
//       headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer supersecreta123'},
//       body: jsonEncode({'email': email}),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Error: ${response.body}');
//     }
//   }

//   /// 🧱 Activar MFA (simulado)
//   static Future<Map<String, dynamic>> enableMfa(String email) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/enable-mfa'),
//       headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer supersecreta123'},
//       body: jsonEncode({'email': email}),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     } else {
//       throw Exception('Error: ${response.body}');
//     }
//   }
// }
