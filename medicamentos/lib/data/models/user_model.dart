import 'package:gestionmedicamentos/domain/entities/user.dart';

/// Modelo local para SQLite.
/// Soporta roles: 'admin' | 'encargado' | 'doctor'
/// y campos opcionales por rol: `area` (encargado) y `specialty` (doctor).
class User {
  final int? id;
  /// Regla: 'nombre' + 2 dígitos (ej: 'carlos12')
  final String name;

  /// IMPORTANTE: aquí se guarda el **hash** de la contraseña (bcrypt),
  /// NO la contraseña en claro.
  final String passwordHash;

  /// Rol: 'admin' | 'encargado' | 'doctor'
  final String role;

  /// Campo opcional solo para 'doctor'
  final String? specialty;

  /// Campo opcional solo para 'encargado'
  final String? area;

  /// Campos para aplicar lockout / rate limiting
  final int failedAttempts;     // contador de intentos fallidos
  final int? lockUntilEpochMs;  // epoch ms hasta cuando la cuenta permanece bloqueada

  User({
    this.id,
    required this.name,
    required this.passwordHash,
    required this.role,
    this.specialty,
    this.area,
    this.failedAttempts = 0,
    this.lockUntilEpochMs,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      // ✅ FIX: cuando hacemos SELECT sin la columna 'password', evitamos null
      passwordHash: (map['password'] ?? '!') as String,
      role: (map['role'] ?? 'doctor') as String,
      specialty: map['specialty'] as String?,
      area: map['area'] as String?,
      failedAttempts: (map['failed_attempts'] ?? 0) as int,
      lockUntilEpochMs: map['lock_until'] as int?, // puede ser null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'password': passwordHash, // guardamos el hash en la columna 'password'
      'role': role,
      'specialty': specialty,
      'area': area,
      'failed_attempts': failedAttempts,
      'lock_until': lockUntilEpochMs,
    };
  }
  
  /// Conversión a entidad de dominio (no expone hash).
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      password: '', // 🔒 no exponemos hashes hacia arriba
      role: role,
      specialty: specialty,
      area: area,
      failedAttempts: failedAttempts,
      lockUntilEpochMs: lockUntilEpochMs,
    );
  }

  /// Conversión desde entidad (solo para creación/insert).
  /// Aquí se espera que la entidad traiga el **hash** en `password`
  /// o que lo hayamos hasheado previamente.
  static User fromEntity(UserEntity entity) {
    return User(
      id: entity.id,
      name: entity.name,
      passwordHash: entity.password, // asumimos que viene hash (bcrypt)
      role: entity.role,
      specialty: entity.specialty,
      area: entity.area,
      failedAttempts: entity.failedAttempts ?? 0,
      lockUntilEpochMs: entity.lockUntilEpochMs,
    );
  }
}


























// import 'package:gestionmedicamentos/domain/entities/user.dart';

// class User {
//   final int? id;
//   final String name;
//   final String password;
//   final String role;
//   final String? specialty;

//   User({
//     this.id,
//     required this.name,
//     required this.password,
//     required this.role,
//     this.specialty,
//   });

//   factory User.fromMap(Map<String, dynamic> map) {
//     return User(
//       id: map['id'],
//       name: map['name'],
//       password: map['password'],
//       role: map['role'],
//       specialty: map['specialty'],
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'password': password,
//       'role': role,
//       'specialty': specialty,
//     };
//   }
  
//   UserEntity toEntity() {
//     return UserEntity(
//       id: id,
//       name: name,
//       password: password,
//       role: role,
//       specialty: specialty,
//     );
//   }

//   /// Conversión desde entidad
//   static User fromEntity(UserEntity entity) {
//     return User(
//       id: entity.id,
//       name: entity.name,
//       password: entity.password,
//       role: entity.role,
//       specialty: entity.specialty,
//     );
//   }
// }
