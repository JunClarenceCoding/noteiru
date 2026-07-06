class Episode {
  final int? id;
  final int animeId; // links back to which anime this episode belongs to
  int episodeNumber;
  bool isWatched;
  String? note;

  Episode({
    this.id,
    required this.animeId,
    required this.episodeNumber,
    this.isWatched = false,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animeId': animeId,
      'episodeNumber': episodeNumber,
      'isWatched': isWatched ? 1 : 0,
      'note': note,
    };
  }

  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'],
      animeId: map['animeId'],
      episodeNumber: map['episodeNumber'],
      isWatched: map['isWatched'] == 1,
      note: map['note'],
    );
  }
}