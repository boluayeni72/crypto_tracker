import 'package:sqflite/sqflite.dart';
import '../models/favourite_coin.dart';
import 'package:path/path.dart';

class FavouritesDatabaseHelper {
  FavouritesDatabaseHelper._internal();
  static final FavouritesDatabaseHelper instance =
      FavouritesDatabaseHelper._internal();
  factory FavouritesDatabaseHelper() => instance;
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'favourites.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favourites(
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        image TEXT NOT NULL,
        currentPrice REAL NOT NULL
      )
    ''');
  }

  Future<void> addFavourite(FavouriteCoin coin) async {
    final db = await database;
    await db.insert('favourites', coin.toMap());
  }

  Future<void> removeFavourite(String id) async {
    final db = await database;
    await db.delete('favourites', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FavouriteCoin>> getFavourites() async {
    final db = await database;
    final maps = await db.query('favourites');
    return List.generate(maps.length, (i) => FavouriteCoin.fromMap(maps[i]));
  }

  Future<bool> isFavourite(String id) async {
    final db = await database;
    final result = await db.query(
      'favourites',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }
}
