import 'package:flutter/material.dart';
import 'package:noteiru/models/anime_model.dart';
import 'package:noteiru/core/services/database_helper.dart';
import 'package:noteiru/core/services/recent_search_helper.dart';
import 'package:noteiru/features/anime/anime_detail_screen.dart';
import 'package:noteiru/features/anime/widgets/anime_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Anime> _allAnime = [];
  List<Anime> _results = [];
  List<String> _recentSearches = [];
  bool _isLoading = true;

  static const _bgColor = Color(0xFF15140F);
  static const _cardColor = Color(0xFF1B1A14);
  static const _borderColor = Color(0xFF2E2820);
  static const _textPrimary = Color(0xFFECD4C0);
  static const _textMuted = Color(0xFF706C66);
  static const _accentColor = Color(0xFFB84E22);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final anime = await DatabaseHelper.instance.getAllAnime();
    final recent = await RecentSearchHelper.getRecentSearches();
    setState(() {
      _allAnime = anime;
      _recentSearches = recent;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim().toLowerCase();

    if (trimmed.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _results = _allAnime.where((anime) {
        final english = anime.titleEnglish?.toLowerCase() ?? '';
        final romaji = anime.titleRomaji?.toLowerCase() ?? '';
        return english.contains(trimmed) || romaji.contains(trimmed);
      }).toList();
    });
  }

  Future<void> _onResultTapped(Anime anime) async {
    // Only save the search term once the user actually taps a result
    await RecentSearchHelper.addSearch(_searchController.text);
    final refreshedRecent = await RecentSearchHelper.getRecentSearches();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnimeDetailScreen(animeId: anime.id!)),
    );

    setState(() => _recentSearches = refreshedRecent);

    if (result == true) {
      await _loadInitialData();
      _onSearchChanged(_searchController.text);
    }
  }

  void _onRecentSearchTapped(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
  }

  Future<void> _removeRecentSearch(String query) async {
    await RecentSearchHelper.removeSearch(query);
    final refreshed = await RecentSearchHelper.getRecentSearches();
    setState(() => _recentSearches = refreshed);
  }

  Future<void> _clearAllRecentSearches() async {
    await RecentSearchHelper.clearAll();
    setState(() => _recentSearches = []);
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
    await _loadInitialData();
    _onSearchChanged(_searchController.text);
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Text(
          'Search for an anime by title',
          style: TextStyle(fontFamily: 'PTSerif', fontSize: 14, color: _textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent searches',
                style: TextStyle(fontFamily: 'PTSerif', fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary),
              ),
              GestureDetector(
                onTap: _clearAllRecentSearches,
                child: Text('Clear all', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recentSearches.map((query) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history, size: 18, color: _textMuted),
              title: Text(query, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _textPrimary)),
              trailing: GestureDetector(
                onTap: () => _removeRecentSearch(query),
                child: Icon(Icons.close, size: 16, color: _textMuted),
              ),
              onTap: () => _onRecentSearchTapped(query),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: _textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 18, color: _textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: (value) {
                                _onSearchChanged(value);
                                setState(() {}); // refresh hasQuery for showing/hiding recent list
                              },
                              style: const TextStyle(color: _textPrimary, fontFamily: 'Inter', fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search by title',
                                hintStyle: TextStyle(color: _textMuted, fontFamily: 'Inter', fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (hasQuery)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                              child: Icon(Icons.close, size: 16, color: _textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasQuery
                      ? _buildRecentSearches()
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                'No results found',
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
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final anime = _results[index];
                                return AnimeCard(
                                  anime: anime,
                                  onTap: () => _onResultTapped(anime),
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