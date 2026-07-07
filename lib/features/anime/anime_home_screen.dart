import 'package:flutter/material.dart';
import 'package:noteiru/features/anime/anime_form_screen.dart';
import '../../core/services/database_helper.dart';
import '../../models/anime_model.dart';
import 'widgets/anime_carousel.dart';

class AnimeHomeScreen extends StatefulWidget {
  const AnimeHomeScreen({super.key});

  @override
  State<AnimeHomeScreen> createState() => _AnimeHomeScreenState();
}

class _AnimeHomeScreenState extends State<AnimeHomeScreen> {
  List<Anime> _allAnime = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimeData();
  }

  Future<void> _loadAnimeData() async {
    final data = await DatabaseHelper.instance.getAllAnime();
    setState(() {
      _allAnime = data;
      _isLoading = false;
    });
  }

  List<Anime> get _favorites => _allAnime.where((a) => a.isFavorite).toList();

  List<Anime> get _currentlyWatching => _allAnime
      .where((a) => a.status == AnimeStatus.currentlyWatching && a.type == AnimeType.series)
      .toList();

  List<Anime> get _finishedWatching => _allAnime
      .where((a) => a.status == AnimeStatus.finishedWatching && a.type == AnimeType.series)
      .toList();

  List<Anime> get _movies => _allAnime.where((a) => a.type == AnimeType.movie).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15140F),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allAnime.isEmpty
                ? _buildEmptyState()
                : _buildAnimeList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB84E22),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnimeFormScreen()),
          );
          if (result == true) {
            _loadAnimeData();
          }
        },
        child: const Icon(Icons.add, color: Color(0xFF2E1005)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Transform.translate(
            offset: const Offset(0, -3), // negative = moves up, adjust value as needed
            child: Image.asset(
              'assets/images/noteiru_logo_transparent.png',
              height: 35,
            ),
          ),
          Row(
            children: [
              IconButton(
                
                icon: const Icon(Icons.search, color: Color(0xFFC0BCB6), size: 25),
                onPressed: () {
                  // navigate to search screen later
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: Color(0xFFC0BCB6), size: 25),
                onPressed: () {
                  // navigate to settings/filter later
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildHeader(),
        const Expanded(
          child: Center(
            child: Text(
              'No anime yet',
              style: TextStyle(
                fontFamily: 'PTSerif',
                fontSize: 16,
                color: Color(0xFFC0BCB6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeList() {
    return ListView(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        AnimeCarousel(
          title: 'Favorites',
          icon: Icons.star,
          iconColor: const Color(0xFFEF9F27),
          animeList: _favorites,
          onViewAll: () {},
        ),
        AnimeCarousel(
          title: 'Currently watching',
          icon: Icons.play_arrow,
          iconColor: const Color(0xFF5DCAA5),
          animeList: _currentlyWatching,
          onViewAll: () {},
        ),
        AnimeCarousel(
          title: 'Finished watching',
          icon: Icons.check_circle,
          iconColor: const Color(0xFF7F77DD),
          animeList: _finishedWatching,
          onViewAll: () {},
        ),
        AnimeCarousel(
          title: 'Movies',
          icon: Icons.movie,
          iconColor: const Color(0xFFD4537E),
          animeList: _movies,
          onViewAll: () {},
        ),
      ],
    );
  }
}