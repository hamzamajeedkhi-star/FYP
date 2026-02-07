import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      debugPrint("✅ DATABASE ALREADY OPEN");
      return _database!;
    }

    debugPrint("🟡 OPENING DATABASE...");
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app.db');
    debugPrint("📁 DB PATH: $path");

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        debugPrint("🆕 CREATING DATABASE TABLES");

        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT
          )
        ''');
   await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT
      )
    ''');
       

      },
    );
  }

  // ===========================
  // Tasks methods
  // ===========================
  Future<int> insertTask(Task task) async {
    final db = await database;
    debugPrint("📝 INSERT TASK: ${task.toMap()}");
    final id = await db.insert('tasks', task.toMap());
    debugPrint("✅ TASK INSERTED WITH ID: $id");
    return id;

  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final items = await db.query('tasks');
    debugPrint("📥 TASKS FROM DB: $items");
    return items.map((i) => Task.fromMap(i)).toList();
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    debugPrint("🗑 DELETE TASK ID: $id");
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ===========================
  // Notes methods
  // ===========================
  
Future<int> insertNote(Map<String, dynamic> note) async {
  if (kIsWeb) {
    debugPrint("❌ SQLite not supported on Web");
    return -1;
  }

  final db = await database;
  return db.insert('notes', note);
}
// ===========================
// Auth methods (Register & Login)
// ===========================

Future<int> registerUser({
  required String name,
  required String email,
  required String password,
}) async {
  final db = await database;

  try {
    debugPrint("🧑 REGISTER USER: $email");

    return await db.insert(
      'users',
      {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  } catch (e) {
    debugPrint("❌ REGISTER ERROR: $e");
    return -1; // email already exists
  }
}
Future<Map<String, dynamic>?> loginUser({
  required String email,
  required String password,
}) async {
  final db = await database;

  debugPrint("🔐 LOGIN USER: $email");

  final result = await db.query(
    'users',
    where: 'email = ? AND password = ?',
    whereArgs: [email, password],
  );

  if (result.isNotEmpty) {
    debugPrint("✅ LOGIN SUCCESS");
    return result.first;
  }

  debugPrint("❌ LOGIN FAILED");
  return null;
}




  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;

    final result = await db.query('notes', orderBy: "id DESC");

    debugPrint("📥 NOTES FROM DB: $result");

    return result;
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    debugPrint("🗑 DELETE NOTE ID: $id");
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  
  }
}
