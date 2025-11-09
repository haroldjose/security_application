import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionmedicamentos/core/providers.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/app_repository.dart';

/// Usuario autenticado actual (no expone contraseña ni hash)
final currentUserProvider = StateProvider<UserEntity?>((ref) => null);

final userNotifierProvider = Provider((ref) {
  final repository = ref.watch(appRepositoryProvider);
  return UserNotifier(repository, ref);
});

class UserNotifier {
  final AppRepository repository;
  final Ref ref;

  UserNotifier(this.repository, this.ref);

  /// Login seguro:
  /// - Verifica lockout/backoff (si el repo lo implementa).
  /// - Compara con bcrypt/argon2 en el repositorio/datasource.
  /// Retorna true si autenticado, lanza excepción con mensaje si bloqueado o error.
  Future<bool> login(String name, String passwordPlain) async {
    final user = await repository.getUser(name, passwordPlain);
    if (user != null) {
      ref.read(currentUserProvider.notifier).state = user;
      return true;
    }
    return false;
  }

  /// Registro:
  /// - La entidad debe llegar con el **hash** en `password` para inserción.
  ///   (El hash lo generaremos en la UI o en el repo antes de insertar.)
  Future<void> register(UserEntity user) async {
    await repository.insertUser(user);
  }
}
