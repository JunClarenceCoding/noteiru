import 'package:flutter/material.dart';
import 'dart:io';
import 'package:noteiru/models/anime_model.dart';
import 'package:noteiru/models/episode_model.dart';
import 'package:noteiru/core/services/database_helper.dart';

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

  static const _bgColor = Color(0xFF15140F);
  static const _cardColor = Color(0xFF1B1A14);
  static const _borderColor = Color(0xFF2E2820);
  static const _accentColor = Color(0xFFB84E22);
  static const _accentOnColor = Color(0xFF2E1005);
  static const _textPrimary = Color(0xFFECD4C0);
  static const _textSecondary = Color(0xFFC0BCB6);
  static const _textMuted = Color(0xFF706C66);
  static const _statusColor = Color(0xFF5DCAA5);
  static const _favoriteColor = Color(0xFFEF9F27);

  @override
  void initState() {
    super.initState();
    _loadData();
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

  int get _watchedCount => _episodes.where((e) => e.isWatched).length;

  Future<void> _toggleEpisode(Episode episode) async {
    if (!episode.isWatched) {
      // Marking watched: cascade — mark this one and everything before it too
      await DatabaseHelper.instance.markEpisodesWatchedUpTo(
        widget.animeId,
        episode.episodeNumber,
      );
    } else {
      // Unmarking: just this single episode goes back to unwatched
      final updated = Episode(
        id: episode.id,
        animeId: episode.animeId,
        episodeNumber: episode.episodeNumber,
        isWatched: false,
        note: episode.note,
      );
      await DatabaseHelper.instance.updateEpisode(updated);
    }
    _loadData();
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
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: _textPrimary, size: 20),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // navigate to edit form, passing existing anime, later
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
                                  Icon(Icons.star, size: 14, color: anime.isFavorite ? _favoriteColor : _textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    anime.status == AnimeStatus.currentlyWatching ? 'Watching' : 'Finished',
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _statusColor),
                                  ),
                                  if (anime.season != null)
                                    Text(' · Season ${anime.season}', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _statusColor)),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Episodes', style: TextStyle(fontFamily: 'PTSerif', fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary)),
                          Row(
                            children: [
                              Text('$_watchedCount / ${_episodes.length} watched', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textMuted)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _openMarkUpToDialog,
                                child: Icon(Icons.playlist_add_check, size: 18, color: _accentColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._episodes.map((episode) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: const Color(0xFF211F18))),
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
                      }),
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