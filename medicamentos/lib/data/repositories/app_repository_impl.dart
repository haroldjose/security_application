import 'dart:async';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:gestionmedicamentos/data/models/medicamento_model.dart';
import 'package:gestionmedicamentos/domain/entities/medicamento.dart';
import 'package:gestionmedicamentos/domain/entities/user.dart';
import 'package:gestionmedicamentos/domain/repositories/app_repository.dart';

import 'package:gestionmedicamentos/data/datasources/db_helper.dart';
import 'package:gestionmedicamentos/data/models/user_model.dart' as m;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:gestionmedicamentos/core/supabase_config.dart';


/// Implementación concreta del repositorio.
/// - Login y registro: **local SQLite** (bcrypt + lockout).
/// - Sincronización: **Supabase (tabla `users`)** SIN usar Supabase Auth.
class AppRepositoryImpl implements AppRepository {
  final DBHelper _db;

  // =========================
  // Configuración Supabase
  // =========================
  static sb.SupabaseClient? _supabase;

  AppRepositoryImpl(this._db);

  /// Inicializa Supabase para sincronización (tabla `users`).
  /// No usamos Auth aquí.
  static Future<void> initSupabase({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (_supabase == null) {
      await sb.Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      _supabase = sb.Supabase.instance.client;
      debugPrint('[Supabase] Inicializado para sincronización (sin Auth).');
    }
  }

  // ===========================================================
  // ===============   AUTENTICACIÓN DE USUARIOS   =============
  // ===========================================================

  /// Login: **solo local** (SQLite con bcrypt + lockout).
  @override
  Future<UserEntity?> getUser(String name, String passwordPlain) async {
    final logged = await _db.authUser(name, passwordPlain);
    return logged?.toEntity();
  }

    /// Registro:
  /// - Inserta/actualiza en SQLite (hash seguro).
  /// - Crea usuario en Supabase Auth.
  /// - Sincroniza metadatos con tabla `users`.
    @override
  Future<void> insertUser(UserEntity userEntity) async {
    String passwordHash = userEntity.password;

    // 1) Hash local si viene en claro
    if (!_looksLikeBcryptHash(passwordHash)) {
      passwordHash = BCrypt.hashpw(passwordHash, BCrypt.gensalt());
    }

    // 2) Crear usuario en Supabase Auth con **adminClient** (service role)
    try {
      final email = '${userEntity.name}@local.app';
      final admin = SupabaseConfig.adminClient;

      final result = await admin.auth.admin.createUser(
        sb.AdminUserAttributes(
          email: email,
          password: userEntity.password, // en claro para Auth
          emailConfirm: true,            // sin confirmación manual
        ),
      );

      if (result.user == null) {
        debugPrint('[Supabase] No se pudo crear usuario en Auth para $email');
      } else {
        debugPrint('[Supabase] Usuario Auth creado: $email');
      }
    } catch (e) {
      debugPrint('[Supabase] Error creando usuario Auth: $e');
      // seguimos con flujo local para no romper UX
    }

    // 3) Guardar en SQLite
    final localUserModel = m.User.fromEntity(
      UserEntity(
        id: userEntity.id,
        name: userEntity.name,
        password: passwordHash,
        role: userEntity.role,
        specialty: userEntity.specialty,
        area: userEntity.area,
        failedAttempts: userEntity.failedAttempts,
        lockUntilEpochMs: userEntity.lockUntilEpochMs,
      ),
    );
    await _safeInsertLocal(localUserModel);

    // 4) Sincronizar metadatos a tabla public.users usando **adminClient** (bypassa RLS)
    await _upsertUserRemote(localUserModel);
  }



  // ===========================================================
  // ===============   SINCRONIZACIÓN SUPABASE   ===============
  // ===========================================================

  /// Sube/actualiza un usuario en Supabase (tabla `users`).
    Future<void> _upsertUserRemote(m.User user) async {
    try {
      final admin = SupabaseConfig.adminClient; // service role
      final payload = {
        'name': user.name,
        'role': user.role,
        'specialty': user.specialty, // puede ser null
        'area': user.area,           // puede ser null
        'updated_at': DateTime.now().toIso8601String(),
      };

      await admin.from('users').upsert(payload, onConflict: 'name').select();
      debugPrint('[Supabase] upsert users OK para ${user.name}');
    } catch (e) {
      debugPrint('[Supabase] upsert users error: $e');
    }
  }


  /// Descarga usuarios desde Supabase y los sincroniza localmente.
  Future<void> syncUsersFromSupabase() async {
    if (_supabase == null) return;

    try {
      final rows = await _supabase!
          .from('users')
          .select('name, role, specialty, area, updated_at');

      for (final row in rows) {
        final model = m.User(
          id: null,
          name: row['name'] as String,
          // placeholder: no gestionamos hash aquí (Auth está local)
          passwordHash: '!',
          role: row['role'] as String? ?? 'doctor',
          specialty: row['specialty'] as String?,
          area: row['area'] as String?,
          failedAttempts: 0,
          lockUntilEpochMs: null,
        );

        // Upsert local SIN tocar el hash (si existe localmente).
        await _upsertMetaLocalPreservandoHash(model);
      }
    } catch (e) {
      debugPrint('[Supabase] sync users error: $e');
    }
  }

  // ===========================================================
  // ===================   MÉTODOS AUXILIARES   ================
  // ===========================================================

  bool _looksLikeBcryptHash(String s) {
    return s.startsWith(r'$2a$') || s.startsWith(r'$2b$') || s.startsWith(r'$2y$');
  }

  /// Inserta usuario local con manejo de UNIQUE name; actualiza si ya existe.
  Future<void> _safeInsertLocal(m.User user) async {
    final existing = await _db.getUserByName(user.name);
    if (existing == null) {
      await _db.insertUser(user);
    } else {
      final merged = m.User(
        id: existing.id,
        name: user.name,
        passwordHash: user.passwordHash.isNotEmpty ? user.passwordHash : existing.passwordHash,
        role: user.role,
        specialty: user.specialty,
        area: user.area,
        failedAttempts: user.failedAttempts,
        lockUntilEpochMs: user.lockUntilEpochMs,
      );
      final db = await _db.database;
      await db.update(
        'users',
        merged.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  /// Convierte un username a un email pseudo (si más adelante decides activar Auth remota).
  String _usernameToEmail(String username) => '$username@local.app';

  /// Upsert local desde un perfil remoto, preservando hash local si ya existe.
  Future<void> _upsertUserLocal(m.User remoteLike) async {
    final local = await _db.getUserByName(remoteLike.name);
    if (local == null) {
      final db = await _db.database;
      await db.insert('users', remoteLike.toMap());
      return;
    }

    final merged = m.User(
      id: local.id,
      name: local.name,
      passwordHash: local.passwordHash, // preservamos hash local
      role: remoteLike.role,
      specialty: remoteLike.specialty,
      area: remoteLike.area,
      failedAttempts: local.failedAttempts,
      lockUntilEpochMs: local.lockUntilEpochMs,
    );
    final db = await _db.database;
    await db.update(
      'users',
      merged.toMap(),
      where: 'id = ?',
      whereArgs: [local.id],
    );
  }

  /// Upsert local de metadatos sin tocar el hash existente.
  Future<void> _upsertMetaLocalPreservandoHash(m.User meta) async {
    final local = await _db.getUserByName(meta.name);
    final db = await _db.database;
    if (local == null) {
      await db.insert('users', meta.toMap());
    } else {
      final merged = m.User(
        id: local.id,
        name: local.name,
        passwordHash: local.passwordHash, // preserva hash válido
        role: meta.role,
        specialty: meta.specialty,
        area: meta.area,
        failedAttempts: local.failedAttempts,
        lockUntilEpochMs: local.lockUntilEpochMs,
      );
      await db.update(
        'users',
        merged.toMap(),
        where: 'id = ?',
        whereArgs: [local.id],
      );
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final list = await _db.getAllUsers();
    return list.map((u) => u.toEntity()).toList();
  }

  ///////////////////////////////////////////////////////////////
  @override
  Future<List<MedicamentoEntity>> getMedicamentos() async {
    final list = await _db.getMedicamentos();
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateMedicamento(MedicamentoEntity medicamento) async {
    await _db.updateMedicamento(Medicamento.fromEntity(medicamento));
  }

  @override
  Future<void> registrarRetiro(String medicamento, int cantidad, String doctor) async {
    await _db.registrarRetiro(medicamento, cantidad, doctor);
  }

  @override
  Future<List<Map<String, dynamic>>> getRetiros() {
    return _db.getRetiros();
  }

  @override
  Future<void> addMedicamento(MedicamentoEntity medicamento) async {
    await _db.insertMedicamento(Medicamento.fromEntity(medicamento));
  }

  @override
  Future<void> deleteMedicamento(int id) async {
    await _db.deleteMedicamento(id);
  }

    /// 🗑️ Elimina un usuario localmente (por nombre)
  Future<void> deleteUserLocal(String name) async {
    final db = await _db.database;
    await db.delete('users', where: 'name = ?', whereArgs: [name]);
    debugPrint('[SQLite] Usuario "$name" eliminado localmente.');
  }

}
