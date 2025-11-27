import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static final LocalDB _instance = LocalDB._internal();
  factory LocalDB() => _instance;
  LocalDB._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'pga_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // lookup: eixos, temas, unidades
        await db.execute('''
          CREATE TABLE lookup (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            server_id INTEGER,
            data TEXT NOT NULL
          )
        ''');

        // drafts: formularios parcialmente preenchidos
        await db.execute('''
          CREATE TABLE drafts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            form_type TEXT NOT NULL,
            local_id TEXT,
            data TEXT NOT NULL,
            updated_at INTEGER
          )
        ''');

        // sync_queue: ações pendentes para enviar ao servidor
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            body TEXT,
            local_ref TEXT,
            created_at INTEGER
          )
        ''');

        // projects: cache local de projetos (server_id quando disponível)
        await db.execute('''
          CREATE TABLE projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            local_id TEXT,
            server_id INTEGER,
            data TEXT NOT NULL,
            updated_at INTEGER
          )
        ''');

        // id_map: mapeamento local_id -> server_id
        await db.execute('''
          CREATE TABLE id_map (
            local_id TEXT PRIMARY KEY,
            server_id INTEGER
          )
        ''');
      },
    );
  }

  // Lookup CRUD
  Future<int> insertLookup(String type, String data, {int? serverId}) async {
    final database = await db;
    return await database.insert('lookup', {
      'type': type,
      'server_id': serverId,
      'data': data,
    });
  }

  Future<List<Map<String, dynamic>>> getLookup(String type) async {
    final database = await db;
    return await database.query('lookup', where: 'type = ?', whereArgs: [type]);
  }

  Future<int> clearLookup(String type) async {
    final database = await db;
    return await database.delete('lookup', where: 'type = ?', whereArgs: [type]);
  }

  // Drafts CRUD
  Future<int> saveDraft(String formType, String data, {String? localId}) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (localId != null) {
      // update if exists
      final res = await database.update(
        'drafts',
        {'data': data, 'updated_at': now},
        where: 'local_id = ? AND form_type = ?',
        whereArgs: [localId, formType],
      );
      if (res > 0) return res;
    }
    return await database.insert('drafts', {
      'form_type': formType,
      'local_id': localId,
      'data': data,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getDrafts(String formType) async {
    final database = await db;
    return await database.query('drafts', where: 'form_type = ?', whereArgs: [formType]);
  }

  Future<int> deleteDraft(int id) async {
    final database = await db;
    return await database.delete('drafts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDraftByLocalId(String localId) async {
    final database = await db;
    return await database.delete('drafts', where: 'local_id = ?', whereArgs: [localId]);
  }

  // Sync queue
  Future<int> enqueueSync(String action, String endpoint, String method, String? body, {String? localRef}) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await database.insert('sync_queue', {
      'action': action,
      'endpoint': endpoint,
      'method': method,
      'body': body,
      'local_ref': localRef,
      'created_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final database = await db;
    return await database.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<int> removeSyncItem(int id) async {
    final database = await db;
    return await database.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // Projects cache
  Future<int> saveProject(String data, {String? localId, int? serverId}) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Se temos server_id, verificar se já existe e atualizar
    if (serverId != null) {
      final existing = await database.query('projects', where: 'server_id = ?', whereArgs: [serverId]);
      if (existing.isNotEmpty) {
        // Atualizar projeto existente
        return await database.update(
          'projects',
          {
            'data': data,
            'updated_at': now,
          },
          where: 'server_id = ?',
          whereArgs: [serverId],
        );
      }
    }
    
    // Se temos local_id, verificar se já existe e atualizar
    if (localId != null) {
      final existing = await database.query('projects', where: 'local_id = ?', whereArgs: [localId]);
      if (existing.isNotEmpty) {
        // Atualizar projeto existente
        return await database.update(
          'projects',
          {
            'data': data,
            'updated_at': now,
            'server_id': serverId,
          },
          where: 'local_id = ?',
          whereArgs: [localId],
        );
      }
    }
    
    // Inserir novo projeto
    return await database.insert('projects', {
      'local_id': localId,
      'server_id': serverId,
      'data': data,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final database = await db;
    return await database.query('projects', orderBy: 'updated_at DESC');
  }

  Future<int> clearProjects() async {
    final database = await db;
    return await database.delete('projects');
  }

  Future<int> clearProjectsFromServer() async {
    final database = await db;
    // Remove apenas projetos que vieram do servidor (têm server_id)
    return await database.delete('projects', where: 'server_id IS NOT NULL');
  }

  Future<int> removeLocalProject(String localId) async {
    final database = await db;
    // Remove projeto local que ainda não tem server_id
    return await database.delete('projects', where: 'local_id = ? AND server_id IS NULL', whereArgs: [localId]);
  }

  Future<int> updateProjectServerId(String localId, int serverId) async {
    final database = await db;
    // update projects table
    final res = await database.update('projects', {'server_id': serverId}, where: 'local_id = ?', whereArgs: [localId]);
    // upsert id_map
    await database.insert('id_map', {'local_id': localId, 'server_id': serverId}, conflictAlgorithm: ConflictAlgorithm.replace);
    return res;
  }

  Future<int?> getServerId(String localId) async {
    final database = await db;
    final rows = await database.query('id_map', where: 'local_id = ?', whereArgs: [localId]);
    if (rows.isEmpty) return null;
    return rows.first['server_id'] as int?;
  }
}
