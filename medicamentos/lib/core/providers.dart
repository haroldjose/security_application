import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestionmedicamentos/data/datasources/db_helper.dart';
import 'package:gestionmedicamentos/data/repositories/app_repository_impl.dart';
import 'package:gestionmedicamentos/domain/repositories/app_repository.dart';

// Proveedor de DBHelper
final dbHelperProvider = Provider<DBHelper>((ref) => DBHelper.instance);

// Proveedor del repositorio
final appRepositoryProvider = Provider<AppRepository>((ref) {
  final dbHelper = ref.watch(dbHelperProvider);
  return AppRepositoryImpl(dbHelper);
});

