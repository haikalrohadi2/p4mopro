
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/mahasiswa.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance =
      DatabaseHelper._();

  static const String databaseName = 'kampus.db';
  static const String tableName = 'mahasiswa';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE mahasiswa (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            nim TEXT NOT NULL UNIQUE,
            program_studi TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // CREATE
  Future<int> insertMahasiswa(
      Mahasiswa mahasiswa) async {
    final db = await database;

    return await db.insert(
      tableName,
      mahasiswa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // READ
  Future<List<Mahasiswa>> getAllMahasiswa() async {
    final db = await database;

    final result = await db.query(
      tableName,
      orderBy: 'id DESC',
    );

    return result
        .map((data) => Mahasiswa.fromMap(data))
        .toList();
  }

  // UPDATE
  Future<int> updateMahasiswa(
      Mahasiswa mahasiswa) async {
    if (mahasiswa.id == null) {
      throw ArgumentError('ID wajib diisi.');
    }

    final db = await database;

    return await db.update(
      tableName,
      mahasiswa.toMap(),
      where: 'id = ?',
      whereArgs: [mahasiswa.id],
    );
  }

  // DELETE
  Future<int> deleteMahasiswa(int id) async {
    final db = await database;

    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
