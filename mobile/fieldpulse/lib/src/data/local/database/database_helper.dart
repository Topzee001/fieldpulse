import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fieldpulse.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE conflicts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              job_id INTEGER,
              local_data TEXT,
              server_data TEXT,
              conflicting_fields TEXT,
              created_at TEXT,
              resolved INTEGER DEFAULT 0,
              resolution TEXT,
              resolved_at TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY,
        job_id TEXT UNIQUE,
        customer_name TEXT,
        customer_phone TEXT,
        customer_email TEXT,
        customer_address TEXT,
        latitude REAL,
        longitude REAL,
        description TEXT,
        notes TEXT,
        scheduled_start TEXT,
        scheduled_end TEXT,
        status TEXT,
        checklist_schema TEXT,
        version INTEGER,
        actual_start TEXT,
        actual_completion TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER,
        action TEXT,
        payload TEXT,
        created_at TEXT,
        retry_count INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE conflicts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER,
        local_data TEXT,
        server_data TEXT,
        conflicting_fields TEXT,
        created_at TEXT,
        resolved INTEGER DEFAULT 0,
        resolution TEXT,
        resolved_at TEXT
      )
    ''');
  }
}
