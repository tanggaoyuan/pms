import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static Database? _db;

  static Future<String> getDbPath() async {
    var datapath = await getDatabasesPath();
    return join(datapath, 'pms.db');
  }

  static Future<Database> open() async {
    if (_db == null) {
      var datapath = await getDbPath();
      _db = await openDatabase(
        datapath,
        version: 1,
      );
    }
    return Future.value(_db);
  }

  static Future<List<String>> getAllTables() async {
    Database db = await open();
    List<Map<String, dynamic>> maps = await db.query('sqlite_master', columns: ['name'], where: "type = 'table'");
    return maps.map((e) => e['name'] as String).toList();
  }

  static close() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> delete() async {
    var path = await getDbPath();
    return deleteDatabase(path);
  }

  static Future<void> removeTable(String table) async {
    var db = await open();
    db.execute('DROP TABLE IF EXISTS $table');
  }
}
