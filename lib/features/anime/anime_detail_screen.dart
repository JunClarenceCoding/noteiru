import 'package:flutter/material.dart';
import 'package:noteiru/core/services/notification_helper.dart';
import 'dart:io';
import 'package:noteiru/models/anime_model.dart';
import 'package:noteiru/models/episode_model.dart';
import 'package:noteiru/core/services/database_helper.dart';
import 'package:noteiru/features/anime/anime_form_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final int animeId;

  const AnimeDetailScreen({super.key, required this.animeId});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  Anime? _anime;
  List<Episode> _episodes = [];
  bool _isLoading = true;
  String _selectedRange = 'All';

  static const _bgColor = Color(0xFF15140F);
  static const _cardColor = Color(0xFF1B1A14);
  static const _borderColor = Color(0xFF2E2820);
  static const _accentColor = Color(0xFFB84E22);
  static const _accentOnColor = Color(0xFF2E1005);
  static const _textPrimary = Color(0xFFECD4C0);
  static const _textSecondary = Color(0xFFC0BCB6);
  static const _textMuted = Color(0xFF706C66);
  static const _statusColor = Color(0xFF5DCAA5);
  // static const _favoriteColor = Color(0xFFEF9F27);
  static const int _chunkSize = 50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<String> _buildRangeOptions() {
    final total = _episodes.length;
    if (total <= _chunkSize) return ['All'];

    final options = <String>['All'];
    for (int start = 1; start <= total; start += _chunkSize) {
      final end = (start + _chunkSize - 1).clamp(0, total);
      options.add('$start - $end');
    }
    return options;
  }

  List<Episode> get _visibleEpisodes {
    if (_selectedRange == 'All') return _episodes;

    final parts = _selectedRange.split(' - ');
    final start = int.parse(parts[0]);
    final end = int.parse(parts[1]);

    return _episodes.where((e) => e.episodeNumber >= start && e.episodeNumber <= end).toList();
  }

  Future<void> _loadData() async {
    final anime = await DatabaseHelper.instance.getAnimeById(widget.animeId);
    final episodes = await DatabaseHelper.instance.getEpisodesForAnime(widget.animeId);
    setState(() {
      _anime = anime;
      _episodes = episodes;
      _isLoading = false;
    });
  }

  Future<void> _increaseEpisodeCount() async {
    final anime = _anime!;
    final newTotal = (anime.totalEpisodes ?? _episodes.length) + 1;

    await DatabaseHelper.instance.insertEpisode(
      Episode(animeId: anime.id!, episodeNumber: newTotal),
    );

    final updated = Anime(
      id: anime.id,
      titleEnglish: anime.titleEnglish,
      titleRomaji: anime.titleRomaji,
      imagePath: anime.imagePath,
      type: anime.type,
      status: anime.status,
      genres: anime.genres,
      isFavorite: anime.isFavorite,
      season: anime.season,
      totalEpisodes: newTotal,
      notificationDay: anime.notificationDay,
      description: anime.description,
    );
    await DatabaseHelper.instance.updateAnime(updated);

    _loadData();
  }

  Future<void> _decreaseEpisodeCount() async {
    if (_episodes.isEmpty) return;

    final anime = _anime!;
    final lastEpisode = _episodes.reduce((a, b) => a.episodeNumber > b.episodeNumber ? a : b);

    // Warn if the last episode has a note or is watched, since deleting loses that data
    if (lastEpisode.isWatched || lastEpisode.note != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: _cardColor,
            title: Text('Remove episode ${lastEpisode.episodeNumber}?', style: TextStyle(color: _textPrimary, fontFamily: 'PTSerif')),
            content: Text(
              'This episode has a note or watched progress that will be lost.',
              style: TextStyle(color: _textSecondary, fontFamily: 'Inter', fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: _textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    }

    await DatabaseHelper.instance.deleteEpisode(lastEpisode.id!);

    final newTotal = _episodes.length - 1;
    final updated = Anime(
      id: anime.id,
      titleEnglish: anime.titleEnglish,
      titleRomaji: anime.titleRomaji,
      imagePath: anime.imagePath,
      type: anime.type,
      status: anime.status,
      genres: anime.genres,
      isFavorite: anime.isFavorite,
      season: anime.season,
      totalEpisodes: newTotal > 0 ? newTotal : null,
      notificationDay: anime.notificationDay,
      description: anime.description,
    );
    await DatabaseHelper.instance.updateAnime(updated);

    _loadData();
  }

  int get _watchedCount => _episodes.where((e) => e.isWatched).length;

  Future<void> _toggleEpisode(Episode episode) async {
    if (!episode.isWatched) {
      // Marking watched: cascade forward — mark this one and everything before it too
      await DatabaseHelper.instance.markEpisodesWatchedUpTo(
        widget.animeId,
        episode.episodeNumber,
      );
    } else {
      // Unmarking: cascade backward — unmark this one and everything after it too
      await DatabaseHelper.instance.markEpisodesUnwatchedFrom(
        widget.animeId,
        episode.episodeNumber,
      );
    }
    _loadData();
  }

  Future<void> _toggleStatus() async {
    final anime = _anime!;
    final newStatus = anime.status == AnimeStatus.currentlyWatching
        ? AnimeStatus.finishedWatching
        : AnimeStatus.currentlyWatching;

    final updated = Anime(
      id: anime.id,
      titleEnglish: anime.titleEnglish,
      titleRomaji: anime.titleRomaji,
      imagePath: anime.imagePath,
      type: anime.type,
      status: newStatus,
      genres: anime.genres,
      isFavorite: anime.isFavorite,
      season: anime.season,
      totalEpisodes: anime.totalEpisodes,
      notificationDay: anime.notificationDay,
      description: anime.description,
    );

    await DatabaseHelper.instance.updateAnime(updated);
    _loadData();
  }

  Future<void> _toggleFavorite() async {
    final anime = _anime!;

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

  Widget _buildMovieNoteSection(Episode movieEntry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOTES', style: TextStyle(fontFamily: 'Inter', fontSize: 10, letterSpacing: 0.5, color: _textMuted)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _openNoteEditor(movieEntry),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: movieEntry.note != null ? _borderColor : const Color(0xFF3E3C34),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      movieEntry.note ?? 'e.g. left off at 45 minutes in',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: movieEntry.note != null ? _textPrimary : _textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined, size: 15, color: _accentColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMarkUpToDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          title: Text('Mark watched up to', style: TextStyle(color: _textPrimary, fontFamily: 'PTSerif')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: _textPrimary),
            decoration: InputDecoration(
              hintText: 'Episode number',
              hintStyle: TextStyle(color: _textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _borderColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _textMuted)),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                Navigator.pop(context, value);
              },
              child: Text('Mark', style: TextStyle(color: _accentColor)),
            ),
          ],
        );
      },
    );

    if (result != null && result > 0) {
      await DatabaseHelper.instance.markEpisodesWatchedUpTo(widget.animeId, result);
      _loadData();
    }
  }

  Future<void> _openNoteEditor(Episode episode) async {
    final controller = TextEditingController(text: episode.note ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Note for episode ${episode.episodeNumber}',
                style: TextStyle(fontFamily: 'PTSerif', fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. paused at 14:32, right after the flashback',
                  hintStyle: TextStyle(color: _textMuted, fontSize: 12),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: Text('Done', style: TextStyle(color: _accentOnColor)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final updated = Episode(
        id: episode.id,
        animeId: episode.animeId,
        episodeNumber: episode.episodeNumber,
        isWatched: episode.isWatched,
        note: result.trim().isEmpty ? null : result.trim(),
      );
      await DatabaseHelper.instance.updateEpisode(updated);
      _loadData();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          title: Text('Delete this anime?', style: TextStyle(color: _textPrimary, fontFamily: 'PTSerif')),
          content: Text(
            'This will permanently remove it and all its episode data.',
            style: TextStyle(color: _textSecondary, fontFamily: 'Inter', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: _textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await NotificationHelper.cancelReminder(widget.animeId);
      await DatabaseHelper.instance.deleteAnime(widget.animeId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_anime == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Text('Anime not found', style: TextStyle(color: _textPrimary)),
        ),
      );
    }

    final anime = _anime!;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: const Icon(Icons.arrow_back, color: _textPrimary, size: 20),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AnimeFormScreen(existingAnime: anime)),
                          );
                          if (result == true) _loadData(); // refresh detail screen with updated info
                        },
                        child: const Icon(Icons.edit_outlined, color: _textSecondary, size: 18),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _confirmDelete,
                        child: const Icon(Icons.delete_outline, color: _textSecondary, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderColor),
                          ),
                          child: anime.imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(anime.imagePath!), fit: BoxFit.cover),
                                )
                              : Icon(Icons.image_outlined, color: _textMuted, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anime.displayTitle,
                                style: TextStyle(fontFamily: 'PTSerif', fontStyle: FontStyle.italic, fontSize: 18, color: _textPrimary),
                              ),
                              if (anime.titleRomaji != null && anime.titleRomaji != anime.displayTitle)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(anime.titleRomaji!, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textMuted)),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _toggleFavorite,
                                    child: Icon(
                                      anime.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      size: 15,
                                      color: anime.isFavorite ? const Color(0xFFD4537E) : _textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    anime.season != null ? 'Season ${anime.season}' : (anime.type == AnimeType.movie ? 'Movie' : ''),
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: anime.genres.map((g) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFF2E1005), borderRadius: BorderRadius.circular(20)),
                                    child: Text(g, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFFF0997B))),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

// Status toggle - its own dedicated section
Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: _cardColor,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: anime.status == AnimeStatus.currentlyWatching ? null : _toggleStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: anime.status == AnimeStatus.currentlyWatching
                  ? _statusColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 15,
                  color: anime.status == AnimeStatus.currentlyWatching
                      ? const Color(0xFF0F1D18)
                      : _textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Watching',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: anime.status == AnimeStatus.currentlyWatching ? FontWeight.bold : FontWeight.normal,
                    color: anime.status == AnimeStatus.currentlyWatching
                        ? const Color(0xFF0F1D18)
                        : _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTap: anime.status == AnimeStatus.finishedWatching ? null : _toggleStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: anime.status == AnimeStatus.finishedWatching
                  ? const Color(0xFF7F77DD)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 15,
                  color: anime.status == AnimeStatus.finishedWatching
                      ? const Color(0xFF1A1730)
                      : _textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Finished',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: anime.status == AnimeStatus.finishedWatching ? FontWeight.bold : FontWeight.normal,
                    color: anime.status == AnimeStatus.finishedWatching
                        ? const Color(0xFF1A1730)
                        : _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 16),

                    if (anime.description != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DESCRIPTION', style: TextStyle(fontFamily: 'Inter', fontSize: 10, letterSpacing: 0.5, color: _textMuted)),
                            const SizedBox(height: 6),
                            Text(anime.description!, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _textSecondary, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_episodes.isNotEmpty) ...[
                      if (anime.type == AnimeType.series) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Episodes',
                                style: TextStyle(fontFamily: 'PTSerif', fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_watchedCount of ${_episodes.length} watched',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _textMuted),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _decreaseEpisodeCount,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF231E15),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Icon(Icons.remove, size: 12, color: _textMuted),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${anime.totalEpisodes ?? _episodes.length}',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _increaseEpisodeCount,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _accentColor,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const Icon(Icons.add, size: 12, color: Color(0xFF2E1005)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _openMarkUpToDialog,
                                child: Icon(Icons.playlist_add_check, size: 18, color: _accentColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_buildRangeOptions().length > 1) ...[
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRange,
          isExpanded: true,
          dropdownColor: _cardColor,
          icon: Icon(Icons.expand_more, color: _textMuted, size: 18),
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: _textPrimary),
          items: _buildRangeOptions().map((range) {
            return DropdownMenuItem(value: range, child: Text(range));
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedRange = value);
          },
        ),
      ),
    ),
    const SizedBox(height: 10),
  ],

  // Fixed-height scrollable episode list
  Container(
    height: 340,
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _visibleEpisodes.length,
      itemBuilder: (context, index) {
        final episode = _visibleEpisodes[index];
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF211F18))),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: GestureDetector(
              onTap: () => _toggleEpisode(episode),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: episode.isWatched ? _accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: episode.isWatched ? null : Border.all(color: _textMuted, width: 1.5),
                ),
                child: episode.isWatched
                    ? Icon(Icons.check, size: 14, color: _accentOnColor)
                    : null,
              ),
            ),
            title: Text(
              'Episode ${episode.episodeNumber}',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: episode.isWatched ? _textPrimary : _textMuted),
            ),
            subtitle: episode.note != null
                ? Text(
                    episode.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFFB84E22)),
                  )
                : null,
            trailing: GestureDetector(
              onTap: () => _openNoteEditor(episode),
              child: Icon(
                episode.note != null ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
                size: 16,
                color: episode.note != null ? _accentColor : const Color(0xFF3A3830),
              ),
            ),
          ),
        );
      },
    ),
  ),
] else ...[
  _buildMovieNoteSection(_episodes.first),
],
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}