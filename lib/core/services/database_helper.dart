import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/anime_model.dart';
import '../../models/episode_model.dart';

class DatabaseHelper {
    DatabaseHelper._privateConstructor();
    static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

    static Database? _database;

    Future<Database> get database async {
        if (_database != null) return _database!;
        _database = await _initDatabase();
        return _database!;
    }

    Future<Database> _initDatabase() async {
        final path = join(await getDatabasesPath(), 'noteiru.db');
        return await openDatabase(
            path,
            version: 1,
            onCreate: _onCreate,
            onConfigure: (db) async {
                await db.execute('PRAGMA foreign_keys = ON');
            },
        );
    }

    Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE animes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titleEnglish TEXT,
            titleRomaji TEXT,
            imagePath TEXT,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            genres TEXT,
            isFavorite INTEGER NOT NULL DEFAULT 0,
            season INTEGER,
            totalEpisodes INTEGER,
            notificationDay TEXT,
            description TEXT
        )
    ''');

    await db.execute('''
      CREATE TABLE episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animeId INTEGER NOT NULL,
        episodeNumber INTEGER NOT NULL,
        isWatched INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        FOREIGN KEY (animeId) REFERENCES animes (id) ON DELETE CASCADE
      )
    ''');
  }

  // --------------------- ANIME CRUD ------------------------------

  Future<int> insertAnime(Anime anime) async {
    final db = await database;
    return await db.insert('animes', anime.toMap());
  }

  Future<int> updateAnime(Anime anime) async {
    final db = await database;
    return await db.update(
        'animes',
        anime.toMap(),
        where: 'id = ?',
        whereArgs: [anime.id],
    );
  }

  Future<int> deleteAnime(int id) async {
    final db = await database;
    return await db.delete('animes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Anime?> getAnimeById(int id) async {
    final db = await database;
    final maps = await db.query('animes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Anime.fromMap(maps.first);
  }

  Future<List<Anime>> getAllAnime() async {
    final db = await database;
    final maps = await db.query('animes', orderBy: 'titleEnglish COLLATE NOCASE ASC');
    return maps.map((map) => Anime.fromMap(map)).toList();
  }

  Future<List<Anime>> getFavorites() async {
    final db = await database;
    final maps = await db.query('animes', where: 'isFavorite = 1');
    return maps.map((map) => Anime.fromMap(map)).toList();
  }

  Future<List<Anime>> getByStatus(AnimeStatus status) async {
    final db = await database;
    final maps = await db.query(
        'animes',
        where: 'status = ?',
        whereArgs: [status.name],
    );
    return maps.map((map) => Anime.fromMap(map)).toList();
  }

  Future<List<Anime>> getByType(AnimeType type) async{
    final db = await database;
    final maps = await db.query(
        'animes',
        where: 'type = ?',
        whereArgs: [type.name],
    );
    return maps.map((map) =>  Anime.fromMap(map)).toList();
  }

  //----------------------- EPISODE CRUD ------------------------------

    Future<int> insertEpisode(Episode episode) async {
        final db = await database;
        return await db.insert('episodes', episode.toMap());
    }

    Future<int> updateEpisode(Episode episode) async {
        final db = await database;
        return await db.update(
            'episodes',
            episode.toMap(),
            where: 'id = ?',
            whereArgs:  [episode.id],
        );
    }

    Future<int> deleteEpisode(int id) async {
        final db = await database;
        return await db.delete('episodes', where: 'id = ?', whereArgs: [id]);
    }

    Future<List<Episode>> getEpisodesForAnime(int animeId) async {
        final db = await database;
        final maps = await db.query(
            'episodes',
            where: 'animeId = ?',
            whereArgs: [animeId],
            orderBy: 'episodeNumber ASC',
        );
        return maps.map((map) => Episode.fromMap(map)).toList();
    }

    // Mark many episodes as watched at once, e.g. "watched through episode 12"
  Future<void> markEpisodesWatchedUpTo(int animeId, int episodeNumber) async {
    final db = await database;
    await db.update(
      'episodes',
      {'isWatched': 1},
      where: 'animeId = ? AND episodeNumber <= ?',
      whereArgs: [animeId, episodeNumber],
    );
  }

  // Add many blank episodes at once, e.g. when totalEpisodes is set/changed
  Future<void> generateEpisodesForAnime(int animeId, int totalEpisodes) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 1; i <= totalEpisodes; i++) {
      batch.insert('episodes', {
        'animeId': animeId,
        'episodeNumber': i,
        'isWatched': 0,
        'note': null,
      });
    }
    await batch.commit(noResult: true);
  }
}