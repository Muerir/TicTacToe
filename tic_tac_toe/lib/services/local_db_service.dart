// lib/services/local_db_service.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';

class LocalDBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tictactoe.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            email TEXT UNIQUE,
            password TEXT,
            onlineId TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE games(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            board TEXT,
            duration INTEGER,
            userId INTEGER,
            finished INTEGER
          )
        ''');
      },
    );
  }

  static Future<UserModel?> insertUser(UserModel user) async {
    final db = await database;
    final onlineId = const Uuid().v4();

    final id = await db.insert('users', {
      'username': user.username,
      'email': user.email,
      'password': user.password,
      'onlineId': onlineId,
    });

    if (id != 0) {
      return UserModel(
        id: id,
        username: user.username,
        email: user.email,
        password: user.password,
        onlineId: onlineId,
      );
    }
    return null;
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return UserModel.fromLocalMap(result.first);
    }
    return null;
  }

  static Future<UserModel?> validateUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return UserModel.fromLocalMap(result.first);
    }
    return null;
  }

  static Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      'users',
      {
        'username': user.username,
        'email': user.email,
        'password': user.password,
        'onlineId': user.onlineId,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  static Future<int> insertGame(GameModel game) async {
    print('Insertando partida para usuario ${game.userId}');
    final db = await database;
    return await db.insert(
      'games',
      game.toMap()..remove('id'), // Remueve el id antes de insertar
    );
  }

  static Future<void> updateGame(GameModel game) async {
    final db = await database;
    await db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  static Future<void> deleteGame(int gameId) async {
    final db = await database;
    await db.delete('games', where: 'id = ?', whereArgs: [gameId]);
  }

  static Future<GameModel?> getIncompleteGame(int userId) async {
    final db = await database;
    final result = await db.query(
      'games',
      where: 'userId = ? AND finished = 0',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) return GameModel.fromMap(result.first);
    return null;
  }

  static Future<List<GameModel>> getGamesForUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'games',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((e) => GameModel.fromMap(e)).toList();
  }
}
