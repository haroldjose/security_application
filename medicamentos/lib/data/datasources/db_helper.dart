import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/medicamento_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gestion_medicamentos.db');
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// Esquema con soporte de roles y seguridad básica
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,       -- hash bcrypt
        role TEXT NOT NULL,           -- 'admin' | 'encargado' | 'doctor'
        specialty TEXT,               -- solo para 'doctor'
        area TEXT,                    -- solo para 'encargado'
        failed_attempts INTEGER NOT NULL DEFAULT 0,
        lock_until INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        laboratorio TEXT NOT NULL,
        origenLaboratorio TEXT,
        tipoMedicamento TEXT,
        precio REAL NOT NULL,
        cantidad INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE retiros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicamento TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        doctor TEXT NOT NULL
      )
    ''');
  }

  /// Migración (v1 -> v2)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN specialty TEXT;');
      await db.execute('ALTER TABLE users ADD COLUMN area TEXT;');
      await db.execute('ALTER TABLE users ADD COLUMN failed_attempts INTEGER NOT NULL DEFAULT 0;');
      await db.execute('ALTER TABLE users ADD COLUMN lock_until INTEGER;');
    }
  }

  // ==========================
  // MÉTODOS DE USUARIOS
  // ==========================

  Future<User?> getUserByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

    /// Autenticación local segura (bcrypt + lockout + mensajes claros)
  Future<User?> authUser(String name, String passwordPlain) async {
    final db = await instance.database;
    final user = await getUserByName(name);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (user == null) return null;

    // 🔒 Verificar bloqueo temporal
    if ((user.lockUntilEpochMs ?? 0) > now) {
      final diffMs = (user.lockUntilEpochMs! - now);
      final remaining = Duration(milliseconds: diffMs);
      final minutes = remaining.inMinutes;
      throw Exception(
        'El usuario está bloqueado. Intenta de nuevo en '
        '${minutes >= 60 ? "${(minutes / 60).floor()} hora(s)" : "$minutes minuto(s)"}.',
      );
    }

    // ✅ Verificar contraseña
    final isOk = BCrypt.checkpw(passwordPlain, user.passwordHash);
    if (!isOk) {
      final newFailed = user.failedAttempts + 1;
      int? newLockUntil;
      Duration? lockDuration;

      if (newFailed >= 15) {
        lockDuration = const Duration(hours: 24);
      } else if (newFailed >= 10) {
        lockDuration = const Duration(hours: 1);
      } else if (newFailed >= 5) {
        lockDuration = const Duration(minutes: 10);
      }

      if (lockDuration != null) {
        newLockUntil = now + lockDuration.inMilliseconds;
      }

      await db.update(
        'users',
        {
          'failed_attempts': newFailed,
          'lock_until': newLockUntil,
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );

      if (lockDuration != null) {
        throw Exception(
          'Demasiados intentos fallidos. '
          'Tu cuenta estará bloqueada durante '
          '${lockDuration.inHours >= 1 ? "${lockDuration.inHours} hora(s)" : "${lockDuration.inMinutes} minutos"}.',
        );
      } else {
        throw Exception('Contraseña incorrecta. Intento $newFailed.');
      }
    }

    // 🔄 Reset contadores en login correcto
    await db.update(
      'users',
      {
        'failed_attempts': 0,
        'lock_until': null,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );

    final refreshed = await getUserByName(name);
    return refreshed;
  }


  /// Inserta usuario nuevo (passwordHash ya debe venir hasheado).
  Future<void> insertUser(User user) async {
    final db = await instance.database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
  }

  /// ✅ FIX: al listar, incluimos columnas necesarias para evitar nulos.
  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      columns: ['id', 'name', 'role', 'specialty', 'area', 'password', 'failed_attempts', 'lock_until'],
    );
    return result.map((e) => User.fromMap(e)).toList();
  }

  // ==========================
  // MÉTODOS DE MEDICAMENTOS
  // ==========================

  Future<List<Medicamento>> getMedicamentos() async {
    final db = await instance.database;
    final result = await db.query('medicamentos');
    return result.map((e) => Medicamento.fromMap(e)).toList();
  }

  Future<void> updateMedicamento(Medicamento m) async {
    final db = await instance.database;
    await db.update(
      'medicamentos',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<void> deleteMedicamento(int id) async {
    final db = await instance.database;
    await db.delete('medicamentos', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================
  // MÉTODOS DE RETIROS
  // ==========================

  Future<void> registrarRetiro(String medicamento, int cantidad, String doctor) async {
    final db = await instance.database;
    await db.insert('retiros', {
      'medicamento': medicamento,
      'cantidad': cantidad,
      'doctor': doctor,
    });
  }

  Future<List<Map<String, dynamic>>> getRetiros() async {
    final db = await instance.database;
    return await db.query('retiros');
  }

  Future<void> insertMedicamento(Medicamento medicamento) async {
    final db = await database;
    await db.insert('medicamentos', medicamento.toMap());
  }
}
