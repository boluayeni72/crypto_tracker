import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/price_alert.dart';

class PriceAlertDatabaseHelper {
  PriceAlertDatabaseHelper._internal();
  static final PriceAlertDatabaseHelper instance = PriceAlertDatabaseHelper._internal();
  factory PriceAlertDatabaseHelper() => instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'price_alerts.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alerts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        coinId TEXT NOT NULL,
        coinName TEXT NOT NULL,
        coinSymbol TEXT,
        targetPrice REAL NOT NULL,
        currentPrice REAL,
        isAbove INTEGER NOT NULL,
        imageUrl TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE alerts ADD COLUMN coinSymbol TEXT');
      await db.execute('ALTER TABLE alerts ADD COLUMN currentPrice REAL');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE alerts ADD COLUMN imageUrl TEXT');
    }
  }

  Future<void> addAlert(PriceAlert alert) async {
    final db = await database;
    await db.insert('alerts', alert.toMap());
  }

  Future<List<PriceAlert>> getAlerts() async {
    final db = await database;
    final maps = await db.query('alerts');
    return List.generate(maps.length, (i) => PriceAlert.fromMap(maps[i]));
  }

  Future<void> updateAlert(PriceAlert alert) async {
    final db = await database;
    await db.update(
      'alerts',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<void> deleteAlert(int id) async {
    final db = await database;
    await db.delete('alerts', where: 'id = ?', whereArgs: [id]);
  }
}