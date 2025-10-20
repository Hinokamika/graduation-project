import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

/// MongoDB service for simple read operations.
///
/// Reads `MONGO_URL` (or `MONGO_URI`) and `MONGO_DB` from `.env` and exposes:
/// - `getAll()`          → fetch every document in the collection
/// - `getByName(name)`   → fetch documents where `name` matches (case-insensitive)
///
/// Notes:
/// - This uses a single shared connection per app process.
/// - For security, avoid bundling production DB credentials in client apps.
/// - mongo_dart is not supported on Flutter Web. Guard usage accordingly.
class MongoService {
  MongoService({required this.collectionName});

  final String collectionName;

  // Shared DB connection across instances
  static mongo.Db? _db;
  static Completer<void>? _openCompleter;
  // Simple in-memory cache with TTL to avoid repeated Atlas queries
  static final Map<String, _CacheEntry<List<Map<String, dynamic>>>> _cache = {};
  static const Duration _defaultTtl = Duration(minutes: 5);

  /// Ensure a connected DB and return the requested collection.
  Future<mongo.DbCollection> _getCollection() async {
    await _ensureOpen();
    return _db!.collection(collectionName);
  }

  Future<void> _ensureOpen() async {
    await _ensureDbOpen();
  }

  /// Static variant so callers without an instance can ensure connectivity.
  static Future<void> _ensureDbOpen() async {
    if (_db != null && _db!.isConnected) return;
    // Only one open operation at a time
    if (_openCompleter != null) {
      await _openCompleter!.future;
      return;
    }
    _openCompleter = Completer<void>();
    try {
      if (_db != null && _db!.isConnected) return;

      final rawUri = (dotenv.env['MONGO_URL'] ?? dotenv.env['MONGO_URI'] ?? '').trim();
      final dbName = (dotenv.env['MONGO_DB'] ?? '').trim();

      if (rawUri.isEmpty) {
        throw StateError('Missing MONGO_URL/MONGO_URI in .env');
      }

      final uri = _injectDbNameIfMissing(rawUri, dbName);
      final db = await mongo.Db.create(uri);
      await db.open();

      if (!db.isConnected) {
        throw StateError('Failed to connect to MongoDB');
      }
      _db = db;

      if (kDebugMode) {
        debugPrint('MongoService: connected to ${_db!.databaseName}');
      }
    } finally {
      _openCompleter!.complete();
      _openCompleter = null;
    }
  }

  /// Insert `dbName` into a Mongo URI if it has no path segment.
  ///
  /// Examples:
  /// - input: `mongodb+srv://host/?retryWrites=true` + `mydb`
  ///   → `mongodb+srv://host/mydb?retryWrites=true`
  /// - input already has db → unchanged
  static String _injectDbNameIfMissing(String uri, String dbName) {
    if (dbName.isEmpty) return uri;
    // Detect an existing path segment after the host (before '?')
    final hasDbInPath = RegExp(r'^mongodb(?:\+srv)?:\/\/[^\/]+\/(?:(?!\?).)+').hasMatch(uri);
    if (hasDbInPath) return uri;

    final qIndex = uri.indexOf('?');
    if (qIndex == -1) {
      return uri.endsWith('/') ? '$uri$dbName' : '$uri/$dbName';
    }
    final base = uri.substring(0, qIndex);
    final query = uri.substring(qIndex);
    return base.endsWith('/') ? '$base$dbName$query' : '$base/$dbName$query';
  }

  /// GET_ALL — fetch all documents in the collection.
  Future<List<Map<String, dynamic>>> getAll({int? limit}) async {
    final col = await _getCollection();
    final mongo.SelectorBuilder selector = mongo.where;
    if (limit != null && limit > 0) {
      selector.limit(limit);
    }
    final docs = await col.find(selector).toList();
    return docs;
  }

  /// GET_BY_NAME — case-insensitive match on the `name` field.
  /// Returns all documents where `name` contains [name] (regex, case-insensitive).
  Future<List<Map<String, dynamic>>> getByName(String name, {int? limit}) async {
    final col = await _getCollection();
    final mongo.SelectorBuilder selector =
        mongo.where.match('name', name, caseInsensitive: true);
    if (limit != null && limit > 0) {
      selector.limit(limit);
    }
    final docs = await col.find(selector).toList();
    return docs;
  }

  /// Close the shared connection (optional, usually not needed).
  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
    }
    _db = null;
  }

  /// List all collection names in the current database.
  /// Set [includeSystem] to true to include `system.*` collections.
  static Future<List<String>> listCollections({bool includeSystem = false}) async {
    await _ensureDbOpen();
    // getCollectionNames returns all collection names
    final List<String?> rawNames = await _db!.getCollectionNames();
    final List<String> names = rawNames.whereType<String>().toList();
    if (includeSystem) return names..sort();
    final filtered = names.where((n) => !n.startsWith('system.')).toList()
      ..sort();
    return filtered;
  }

  /// Read all documents from all collections.
  /// To avoid heavy loads, you can pass [limit] to cap per-collection reads.
  /// Returns a map of `collectionName -> list of documents`.
  static Future<Map<String, List<Map<String, dynamic>>>> readAllCollections({
    int? limit,
    bool includeSystem = false,
  }) async {
    await _ensureDbOpen();
    final out = <String, List<Map<String, dynamic>>>{};
    final names = await listCollections(includeSystem: includeSystem);
    for (final name in names) {
      final col = _db!.collection(name);
      final mongo.SelectorBuilder sel = mongo.where;
      if (limit != null && limit > 0) sel.limit(limit);
      final docs = await col.find(sel).toList();
      out[name] = docs;
    }
    return out;
  }

  /// Convenience: read all documents from `workout_plans` collection.
  /// Use [limit] to cap the number of returned documents.
  static Future<List<Map<String, dynamic>>> readWorkoutPlans({int? limit}) async {
    await _ensureDbOpen();
    final col = _db!.collection('workout_plans');
    final mongo.SelectorBuilder sel = mongo.where;
    if (limit != null && limit > 0) sel.limit(limit);
    return await col.find(sel).toList();
  }

  /// Convenience: read all documents from `meal_plans` collection.
  /// Use [limit] to cap the number of returned documents.
  static Future<List<Map<String, dynamic>>> readMealPlans({int? limit}) async {
    await _ensureDbOpen();
    final col = _db!.collection('meal_plans');
    final mongo.SelectorBuilder sel = mongo.where;
    if (limit != null && limit > 0) sel.limit(limit);
    return await col.find(sel).toList();
  }

  /// Filter `exercises` by optional fields: [name] (case-insensitive contains),
  /// [type], [level], and [force] (exact matches). Use [limit] to cap results.
  static Future<List<Map<String, dynamic>>> filterExercises({
    String? name,
    String? type,
    String? level,
    String? force,
    int? limit,
  }) async {
    final key = 'filterExercises|name=${name ?? ''}|type=${type ?? ''}|level=${level ?? ''}|force=${force ?? ''}|limit=${limit ?? 0}';
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.value;
    await _ensureDbOpen();
    final col = _db!.collection('exercises');
    final mongo.SelectorBuilder sel = mongo.where;
    if (name != null && name.trim().isNotEmpty) {
      sel.match('name', name.trim(), caseInsensitive: true);
    }
    if (type != null && type.trim().isNotEmpty) {
      sel.eq('type', type.trim());
    }
    if (level != null && level.trim().isNotEmpty) {
      sel.eq('level', level.trim());
    }
    if (force != null && force.trim().isNotEmpty) {
      sel.eq('force', force.trim());
    }
    if (limit != null && limit > 0) sel.limit(limit);
    final docs = await col.find(sel).toList();
    _cache[key] = _CacheEntry(docs, DateTime.now().add(_defaultTtl));
    return docs;
  }

  /// Filter exercises by exercise type, matching either `type` or `exercise_type` fields (case-insensitive).
  static Future<List<Map<String, dynamic>>> filterExercisesByExerciseType(
    String exerciseType, {
    int? limit,
  }) async {
    final key = 'filterExercisesByType|type=$exerciseType|limit=${limit ?? 0}';
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) return cached.value;
    await _ensureDbOpen();
    final col = _db!.collection('exercises');
    // OR match on `type` or `exercise_type`, case-insensitive
    mongo.SelectorBuilder sel = mongo.where
        .match('type', exerciseType, caseInsensitive: true)
        .or(mongo.where.match('exercise_type', exerciseType, caseInsensitive: true));
    if (limit != null && limit > 0) sel = sel.limit(limit);
    final docs = await col.find(sel).toList();
    _cache[key] = _CacheEntry(docs, DateTime.now().add(_defaultTtl));
    return docs;
  }

  /// Filter `meals` by optional fields: [name] (case-insensitive contains)
  /// and [courseType] (exact match). Use [limit] to cap results.
  static Future<List<Map<String, dynamic>>> filterMeals({
    String? name,
    String? courseType,
    int? limit,
  }) async {
    await _ensureDbOpen();
    final col = _db!.collection('meals');
    final mongo.SelectorBuilder sel = mongo.where;
    if (name != null && name.trim().isNotEmpty) {
      sel.match('name', name.trim(), caseInsensitive: true);
    }
    if (courseType != null && courseType.trim().isNotEmpty) {
      sel.eq('course_type', courseType.trim());
    }
    if (limit != null && limit > 0) sel.limit(limit);
    return await col.find(sel).toList();
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
