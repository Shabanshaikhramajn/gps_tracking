import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_logger.dart';
import '../models/location_record_model.dart';
import 'location_local_datasource.dart';

const String _logTag = 'SqfliteStorage';

// SQLite-backed storage: one row per record, looked up by id on every
// upsert - a plain table fits better here than a key-value store.
class SqfliteLocationLocalDataSource implements LocationLocalDataSource {
  static const String _tableName = 'location_records';
  static const String _databaseFileName = 'gps_tracker.db';

  Database? _database;

  // Opens the database once and reuses the same connection after that.
  Future<Database> _getDatabase() async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }
    final String databasesPath = await getDatabasesPath();
    final String path = p.join(databasesPath, _databaseFileName);
    AppLogger.info('Opening SQLite database at $path.', name: _logTag);
    final Database opened = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        AppLogger.info('Creating table $_tableName (first launch).', name: _logTag);
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            capturedAt TEXT NOT NULL,
            accuracy REAL,
            status TEXT NOT NULL,
            attempts INTEGER NOT NULL,
            lastError TEXT
          )
        ''');
      },
    );
    _database = opened;
    return opened;
  }

  @override
  Future<List<LocationRecordModel>> loadAll() async {
    final Database db = await _getDatabase();
    final List<Map<String, Object?>> rows = await db.query(
      _tableName,
      orderBy: 'capturedAt ASC',
    );
    final List<LocationRecordModel> records = rows.map(LocationRecordModel.fromMap).toList();
    AppLogger.debug('Loaded ${records.length} record(s) from SQLite.', name: _logTag);
    return records;
  }

  @override
  Future<void> upsertRecord(LocationRecordModel record) async {
    final Database db = await _getDatabase();
    await db.insert(
      _tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.debug('Upserted record ${record.id} (status: ${record.status.name}).', name: _logTag);
  }
}
