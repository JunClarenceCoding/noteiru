import 'package:flutter/material.dart';
import 'package:noteiru/features/anime/anime_form_screen.dart';
import '../../core/services/database_helper.dart';
import '../../models/anime_model.dart';
import 'widgets/anime_carousel.dart';
import 'anime_view_all_screen.dart';
import 'package:noteiru/features/search/search_screen.dart';

class AnimeHomeScreen extends StatefulWidget {
  const AnimeHomeScreen({super.key});

  @override
  State<AnimeHomeScreen> createState() => _AnimeHomeScreenState();
}

class _AnimeHomeScreenState extends State<AnimeHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Anime> _allAnime = [];
  bool _isLoading = true;
  List<String> _selectedGenreFilters = []; 
  List<String> _tempGenreFilters = [];

  static const List<String> _genreOptions = [
    'Action', 'Adventure', 'Boys Love', 'Cars', 'Comedy', 'Dementia',
    'Demons', 'Drama', 'Ecchi', 'Erotica', 'Fantasy', 'Game',
    'Girls Love', 'Gourmet', 'Harem', 'Historical', 'Horror', 'Isekai',
    'Josei', 'Kids', 'Magic', 'Mahou Shoujo', 'Martial Arts', 'Mecha',
    'Military', 'Music', 'Mystery', 'Parody', 'Police', 'Psychological',
    'Romance', 'Samurai', 'School', 'Sci-Fi', 'Seinen', 'Shoujo',
    'Shoujo Ai', 'Shounen', 'Shounen Ai', 'Slice of Life', 'Space', 'Sports',
    'Super Power', 'Supernatural', 'Suspense', 'Thriller', 'Vampire',
  ];

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

  List<Anime> get _filteredAnime {
    if (_selectedGenreFilters.isEmpty) return _allAnime;
    return _allAnime.where((anime) {
      return anime.genres.any((g) => _selectedGenreFilters.contains(g));
    }).toList();
  }

  List<Anime> get _favorites => _filteredAnime.where((a) => a.isFavorite).toList();

  List<Anime> get _currentlyWatching => _filteredAnime
      .where((a) => a.status == AnimeStatus.currentlyWatching)
      .toList();

  List<Anime> get _series => _filteredAnime
      .where((a) => a.type == AnimeType.series)
      .toList();

  List<Anime> get _movies => _filteredAnime
      .where((a) => a.type == AnimeType.movie)
      .toList();

  List<Anime> get _finishedWatching => _filteredAnime
      .where((a) => a.status == AnimeStatus.finishedWatching)
      .toList();

  // Future<void> _openGenreFilter() async {
  //   final result = await showModalBottomSheet<List<String>>(
  //     context: context,
  //     backgroundColor: const Color(0xFF1B1A14),
  //     isScrollControlled: true,
  //     builder: (context) {
  //       final tempSelected = List<String>.from(_selectedGenreFilters);
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return SafeArea(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Padding(
  //                   padding: const EdgeInsets.all(16),
  //                   child: Text(
  //                     'Filter by genre',
  //                     style: TextStyle(
  //                       fontFamily: 'PTSerif',
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 16,
  //                       color: const Color(0xFFECD4C0),
  //                     ),
  //                   ),
  //                 ),
  //                 Flexible(
  //                   child: ListView(
  //                     shrinkWrap: true,
  //                     children: _genreOptions.map((genre) {
  //                       final isChecked = tempSelected.contains(genre);
  //                       return CheckboxListTile(
  //                         title: Text(genre, style: const TextStyle(color: Color(0xFFC0BCB6))),
  //                         value: isChecked,
  //                         activeColor: const Color(0xFFB84E22),
  //                         onChanged: (checked) {
  //                           setModalState(() {
  //                             if (checked == true) {
  //                               tempSelected.add(genre);
  //                             } else {
  //                               tempSelected.remove(genre);
  //                             }
  //                           });
  //                         },
  //                       );
  //                     }).toList(),
  //                   ),
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.all(16),
  //                   child: Row(
  //                     children: [
  //                       if (tempSelected.isNotEmpty)
  //                         TextButton(
  //                           onPressed: () => Navigator.pop(context, <String>[]),
  //                           child: const Text('Clear', style: TextStyle(color: Color(0xFF888780))),
  //                         ),
  //                       const Spacer(),
  //                       ElevatedButton(
  //                         style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB84E22)),
  //                         onPressed: () => Navigator.pop(context, tempSelected),
  //                         child: const Text('Apply', style: TextStyle(color: Color(0xFF2E1005))),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );

  //   if (result != null) {
  //     setState(() => _selectedGenreFilters = result);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF15140F),
      endDrawer: _buildGenreDrawer(),
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

  Widget _buildGenreDrawer() {
  return Drawer(
    backgroundColor: const Color(0xFF1B1A14),
    child: StatefulBuilder(
      builder: (context, setDrawerState) {
        final genreSearchController = TextEditingController();
        List<String> visibleGenres = List.from(_genreOptions);

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by genre',
                      style: TextStyle(fontFamily: 'PTSerif', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFECD4C0)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Color(0xFFC0BCB6), size: 20),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15140F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E2820)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16, color: Color(0xFF706C66)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: genreSearchController,
                          style: const TextStyle(color: Color(0xFFECD4C0), fontFamily: 'Inter', fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search genres',
                            hintStyle: TextStyle(color: Color(0xFF706C66), fontFamily: 'Inter', fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (query) {
                            setDrawerState(() {
                              visibleGenres = _genreOptions
                                  .where((g) => g.toLowerCase().contains(query.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_tempGenreFilters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_tempGenreFilters.length} selected',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF706C66)),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleGenres.map((genre) {
                      final isSelected = _tempGenreFilters.contains(genre);
                      return GestureDetector(
                        onTap: () {
                          setDrawerState(() {
                            if (isSelected) {
                              _tempGenreFilters.remove(genre);
                            } else {
                              _tempGenreFilters.add(genre);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFB84E22) : const Color(0xFF15140F),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFB84E22) : const Color(0xFF2E2820),
                            ),
                          ),
                          child: Text(
                            genre,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: isSelected ? const Color(0xFF2E1005) : const Color(0xFFC0BCB6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_tempGenreFilters.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setDrawerState(() => _tempGenreFilters = []);
                        },
                        child: const Text('Clear', style: TextStyle(color: Color(0xFF888780))),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB84E22)),
                      onPressed: () {
                        setState(() => _selectedGenreFilters = List.from(_tempGenreFilters));
                        Navigator.pop(context);
                      },
                      child: const Text('Apply', style: TextStyle(color: Color(0xFF2E1005))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              ),
              Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune, color: Color(0xFFC0BCB6), size: 25),
                  onPressed: () {
                    _tempGenreFilters = List.from(_selectedGenreFilters); // sync drawer with current filter
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                ),
                if (_selectedGenreFilters.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFB84E22), shape: BoxShape.circle),
                    ),
                  ),
              ],
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

    if (_filteredAnime.isEmpty) {
    return ListView(
      children: [
        _buildHeader(),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_off_outlined, size: 32, color: const Color(0xFF3E3C34)),
                const SizedBox(height: 10),
                Text(
                  'No anime match this filter',
                  style: TextStyle(fontFamily: 'PTSerif', fontSize: 14, color: const Color(0xFFC0BCB6)),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedGenreFilters = []),
                  child: Text(
                    'Clear filter',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: const Color(0xFFB84E22)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  return ListView(
    children: [
      _buildHeader(),
      const SizedBox(height: 8),
      AnimeCarousel(
        title: 'Favorites',
        icon: Icons.star,
        iconColor: const Color(0xFFEF9F27),
        animeList: _favorites,
        onViewAll: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeViewAllScreen(
              category: AnimeCategory.favorites,
              genreFilters: _selectedGenreFilters,
            ),
          ),
        ).then((_) => _loadAnimeData()),
        onAnimeChanged: _loadAnimeData,
      ),
      AnimeCarousel(
        title: 'Currently watching',
        icon: Icons.play_arrow,
        iconColor: const Color(0xFF5DCAA5),
        animeList: _currentlyWatching,
        onViewAll: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeViewAllScreen(
              category: AnimeCategory.currentlyWatching,
              genreFilters: _selectedGenreFilters,
            ),
          ),
        ).then((_) => _loadAnimeData()),
        onAnimeChanged: _loadAnimeData,
      ),
      AnimeCarousel(
        title: 'Series',
        icon: Icons.live_tv,
        iconColor: const Color(0xFF7FA3DD),
        animeList: _series,
        onViewAll: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeViewAllScreen(
              category: AnimeCategory.series,
              genreFilters: _selectedGenreFilters,
            ),
          ),
        ).then((_) => _loadAnimeData()),
        onAnimeChanged: _loadAnimeData,
      ),
      AnimeCarousel(
        title: 'Movies',
        icon: Icons.movie,
        iconColor: const Color(0xFFD4537E),
        animeList: _movies,
        onViewAll: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeViewAllScreen(
              category: AnimeCategory.movies,
              genreFilters: _selectedGenreFilters,
            ),
          ),
        ).then((_) => _loadAnimeData()),
        onAnimeChanged: _loadAnimeData,
      ),
      AnimeCarousel(
        title: 'Finished watching',
        icon: Icons.check_circle,
        iconColor: const Color(0xFF7F77DD),
        animeList: _finishedWatching,
        onViewAll: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimeViewAllScreen(
              category: AnimeCategory.finishedWatching,
              genreFilters: _selectedGenreFilters,
            ),
          ),
        ).then((_) => _loadAnimeData()),
        onAnimeChanged: _loadAnimeData,
      ),
    ],
  );
}
}