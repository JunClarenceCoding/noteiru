class Anime {
  final int? id;
  String? titleEnglish;
  String? titleRomaji;
  String? imagePath;
  AnimeType type;
  AnimeStatus status;
  List<String> genres;
  bool isFavorite;
  int? season;
  int? totalEpisodes; // how many episode released so far
  String? notificationDay; //monday to sunday
  String? description; //optional descrition about the anime

  Anime({
    this.id,
    this.titleEnglish,
    this. titleRomaji,
    this.imagePath,
    required this.type,
    required this.status,
    this.genres = const [],
    this.isFavorite = false,
    this.season,
    this.totalEpisodes,
    this.notificationDay,
    this.description,
  });

  //Convenience getter english title is priority for displaying the title
  String get displayTitle => (titleEnglish?.trim().isNotEmpty ?? false)
      ? titleEnglish!
      : (titleRomaji ?? '');

  Map<String, dynamic> toMap() {
    return{
      'id': id,
      'titleEnglish': titleEnglish,
      'titleRomaji': titleRomaji,
      'imagePath': imagePath,
      'type': type.name,
      'status': status.name,
      'genres': genres.join(','),
      'isFavorite': isFavorite ? 1 : 0,
      'season': season,
      'totalEpisodes': totalEpisodes,
      'notificationDay': notificationDay,
      'description': description,
    };
  }

  factory Anime.fromMap(Map<String, dynamic> map) {
    return Anime(
      id: map['id'],
      titleEnglish: map['titleEnglish'],
      titleRomaji: map['titleRomaji'],
      imagePath: map['imagePath'],
      type: AnimeType.values.byName(map['type']),
      status: AnimeStatus.values.byName(map['status']),
      genres: (map['genres'] as String).isEmpty
          ? []
          : (map['genres'] as String).split(','),
      isFavorite: map['isFavorite'] == 1,
      season: map['season'],
      totalEpisodes: map['totalEpisodes'],
      notificationDay: map['notificationDay'],
      description: map['description'],
    );
  }
}

enum AnimeType {series, movie}
enum AnimeStatus {currentlyWatching, finishedWatching}