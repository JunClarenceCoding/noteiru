import 'package:flutter/material.dart';
import 'package:noteiru/models/anime_model.dart';
import 'package:noteiru/core/services/database_helper.dart';
import 'anime_detail_screen.dart';
import 'widgets/anime_card.dart';

enum AnimeCategory { favorites, currentlyWatching, series, movies, finishedWatching }

class AnimeViewAllScreen extends StatefulWidget {
  final AnimeCategory category;
  final List<String> genreFilters;

  const AnimeViewAllScreen({super.key, required this.category, this.genreFilters = const [],});

  @override
  State<AnimeViewAllScreen> createState() => _AnimeViewAllScreenState();
}

class _AnimeViewAllScreenState extends State<AnimeViewAllScreen> {
  List<Anime> _animeList = [];
  bool _isLoading = true;

  static const _bgColor = Color(0xFF15140F);
  static const _textPrimary = Color(0xFFECD4C0);
  static const _textMuted = Color(0xFF706C66);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final allAnime = await DatabaseHelper.instance.getAllAnime();

    List<Anime> filtered;
    switch (widget.category) {
      case AnimeCategory.favorites:
        filtered = allAnime.where((a) => a.isFavorite).toList();
        break;
      case AnimeCategory.currentlyWatching:
        filtered = allAnime.where((a) => a.status == AnimeStatus.currentlyWatching).toList();
        break;
      case AnimeCategory.series:
        filtered = allAnime.where((a) => a.type == AnimeType.series).toList();
        break;
      case AnimeCategory.movies:
        filtered = allAnime.where((a) => a.type == AnimeType.movie).toList();
        break;
      case AnimeCategory.finishedWatching:
        filtered = allAnime.where((a) => a.status == AnimeStatus.finishedWatching).toList();
        break;
    }

    // Apply genre filter on top of the category filter, if any genres are selected
    if (widget.genreFilters.isNotEmpty) {
      filtered = filtered.where((anime) {
        return anime.genres.any((g) => widget.genreFilters.contains(g));
      }).toList();
    }

    setState(() {
      _animeList = filtered;
      _isLoading = false;
    });
  }

  String get _title {
    switch (widget.category) {
      case AnimeCategory.favorites:
        return 'Favorites';
      case AnimeCategory.currentlyWatching:
        return 'Currently watching';
      case AnimeCategory.series:
        return 'Series';
      case AnimeCategory.movies:
        return 'Movies';
      case AnimeCategory.finishedWatching:
        return 'Finished watching';
    }
  }

  Future<void> _toggleFavorite(Anime anime) async {
    final updated = Anime(
      id: anime.id,
      titleEnglish: anime.titleEnglish,
      titleRomaji: anime.titleRomaji,
      imagePath: anime.imagePath,
      type: anime.type,
      status: anime.status,
      genres: anime.genres,
      isFavorite: !anime.isFavorite,
      season: anime.season,
      totalEpisodes: anime.totalEpisodes,
      notificationDay: anime.notificationDay,
      description: anime.description,
    );
    await DatabaseHelper.instance.updateAnime(updated);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: _textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _title,
                    style: const TextStyle(fontFamily: 'PTSerif', fontSize: 16, color: _textPrimary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.genreFilters.isEmpty
                      ? '${_animeList.length} anime'
                      : '${_animeList.length} anime · ${widget.genreFilters.join(", ")}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textMuted),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _animeList.isEmpty
                      ? Center(
                          child: Text(
                            'Nothing here yet',
                            style: TextStyle(fontFamily: 'PTSerif', fontSize: 14, color: _textMuted),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 120, // caps each cell close to your card's natural 104px width
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: _animeList.length,
                          itemBuilder: (context, index) {
                            final anime = _animeList[index];
                            return AnimeCard(
                              anime: anime,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AnimeDetailScreen(animeId: anime.id!),
                                  ),
                                );
                                if (result == true) _loadData();
                              },
                              onFavoriteToggle: () => _toggleFavorite(anime),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}