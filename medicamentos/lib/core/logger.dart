// lib/core/logger.dart
class AppLogger {
  void e(String message, {Object? error, StackTrace? stackTrace}) {
    // En producción podrías enviar esto a un sistema de logs
    // ignore: avoid_print
    print('❌ ERROR: $message | error=$error | stack=$stackTrace');
  }

  void w(String message, {Object? error, StackTrace? stackTrace}) {
    // ignore: avoid_print
    print('⚠️ WARN: $message | error=$error | stack=$stackTrace');
  }

  void i(String message) {
    // ignore: avoid_print
    print('ℹ️ INFO: $message');
  }
}

final appLogger = AppLogger();









// import 'package:logger/logger.dart';

// final appLogger = Logger(
//   printer: PrettyPrinter(
//     methodCount: 0,
//     errorMethodCount: 3,
//     lineLength: 90,
//     colors: true,
//     printEmojis: true,
//   ),
// );

// // Uso:
// // appLogger.i('Inicio de sesión exitoso');
// // appLogger.w('Supabase falló: $e');
// // appLogger.e('Error inesperado', e);
