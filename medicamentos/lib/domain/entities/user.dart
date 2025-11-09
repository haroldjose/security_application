/// Entidad de dominio (no debe exponer contraseñas en claro).
/// Usaremos `password` como contenedor del **hash** SOLO cuando insertamos.
/// Para lecturas/autenticación, no devolvemos hash hacia UI.
class UserEntity {
  final int? id;
  final String name;
  /// Importante: en creación/insert se puede enviar el **hash** aquí.
  /// En el resto de flujos, mantener vacío.
  final String password;

  /// Rol: 'admin' | 'encargado' | 'doctor'
  final String role;

  /// Solo para 'doctor'
  final String? specialty;

  /// Solo para 'encargado'
  final String? area;

  /// Soporte para lockout / rate limiting
  final int? failedAttempts;     
  final int? lockUntilEpochMs;   

  UserEntity({
    this.id,
    required this.name,
    required this.password,
    required this.role,
    this.specialty,
    this.area,
    this.failedAttempts=0,
    this.lockUntilEpochMs,
  });

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, role: $role, specialty: $specialty, area: $area, failedAttempts: $failedAttempts, lockUntil: $lockUntilEpochMs)';
  }
}
