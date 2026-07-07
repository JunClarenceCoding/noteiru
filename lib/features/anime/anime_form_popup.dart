import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:noteiru/models/anime_model.dart';
import 'package:noteiru/core/services/database_helper.dart';

class AnimeFormScreen extends StatefulWidget {
  const AnimeFormScreen({super.key});

  @override
  State<AnimeFormScreen> createState() => _AnimeFormScreenState();
}

class _AnimeFormScreenState extends State<AnimeFormScreen> {
  final _titleEnglishController = TextEditingController();
  final _titleRomajiController = TextEditingController();
  final _seasonController = TextEditingController(text: '1');
  final _totalEpisodesController = TextEditingController();
  final _descriptionController = TextEditingController();

  AnimeType _type = AnimeType.series;
  AnimeStatus _status = AnimeStatus.currentlyWatching;
  String? _notificationDay;
  bool _isFavorite = false;
  String? _imagePath;
  List<String> _selectedGenres = [];
  String? _titleError;

  static const List<String> _genreOptions = [
    'Action', 'Adventure', 'Comedy', 'Drama', 'Fantasy',
    'Horror', 'Mystery', 'Romance', 'Sci-Fi', 'Slice of Life',
    'Sports', 'Supernatural', 'Thriller',
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static const _bgColor = Color(0xFF15140F);
  static const _cardColor = Color(0xFF1B1A14);
  static const _borderColor = Color(0xFF2E2820);
  static const _accentColor = Color(0xFFB84E22);
  static const _accentOnColor = Color(0xFF2E1005);
  static const _textPrimary = Color(0xFFECD4C0);
  static const _textSecondary = Color(0xFF888780);
  static const _textMuted = Color(0xFF5F5E5A);
  static const _statusColor = Color(0xFF5DCAA5);
  static const _favoriteColor = Color(0xFFEF9F27);

  @override
  void dispose() {
    _titleEnglishController.dispose();
    _titleRomajiController.dispose();
    _seasonController.dispose();
    _totalEpisodesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final savedPath = p.join(appDir.path, fileName);
    await File(picked.path).copy(savedPath);

    setState(() => _imagePath = savedPath);
  }

  Future<void> _openGenrePicker() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: _cardColor,
      builder: (context) {
        final tempSelected = List<String>.from(_selectedGenres);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select genres',
                      style: TextStyle(
                        fontFamily: 'PTSerif',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: _genreOptions.map((genre) {
                        final isChecked = tempSelected.contains(genre);
                        return CheckboxListTile(
                          title:  Text(genre, style: TextStyle(color: _textPrimary),),
                          value: isChecked,
                          activeColor: _accentColor,
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                tempSelected.add(genre);
                              } else {
                                tempSelected.remove(genre);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                        onPressed: () => Navigator.pop(context, tempSelected),
                        child: Text('Done', style: TextStyle(color: _accentOnColor)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedGenres = result);
    }
  }

  Future<void> _openNotificationDayPicker() async {
  final result = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: _cardColor,
    isScrollControlled: true, // added — lets the sheet size to content properly
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Notification day',
                style: TextStyle(
                  fontFamily: 'PTSerif',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _textPrimary,
                ),
              ),
            ),
            Flexible( // added — allows this section to scroll instead of overflowing
              child: ListView(
                shrinkWrap: true,
                children: [
                  ..._weekdays.map((day) => ListTile(
                        title: Text(day, style: TextStyle(color: _textPrimary)),
                        trailing: _notificationDay == day
                            ? Icon(Icons.check, color: _accentColor)
                            : null,
                        onTap: () => Navigator.pop(context, day),
                      )),
                  ListTile(
                    title: Text('Clear', style: TextStyle(color: _textMuted)),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  if (result != null) {
    setState(() => _notificationDay = result.isEmpty ? null : result);
  }
}

  Future<void> _openDescriptionEditor() async {
    final controller = TextEditingController(text: _descriptionController.text);
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
              TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add your own notes about this anime...',
                  hintStyle: TextStyle(color: _textMuted),
                  border: InputBorder.none,
                ),
              ),
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
      setState(() => _descriptionController.text = result);
    }
  }

  bool _validateAndSave() {
    final englishEmpty = _titleEnglishController.text.trim().isEmpty;
    final romajiEmpty = _titleRomajiController.text.trim().isEmpty;

    if (englishEmpty && romajiEmpty) {
      setState(() => _titleError = 'Please Enter at least one title');
      return false;
    }
    setState(() => _titleError = null);
    return true;
  }

  Future<void> _saveAnime() async {
    if (!_validateAndSave()) return;

    final anime = Anime(
      titleEnglish: _titleEnglishController.text.trim().isEmpty
          ? null
          : _titleEnglishController.text.trim(),
      titleRomaji: _titleRomajiController.text.trim().isEmpty
          ? null
          : _titleRomajiController.text.trim(),
      imagePath: _imagePath,
      type: _type,
      status: _status,
      genres: _selectedGenres,
      isFavorite: _isFavorite,
      season: _type == AnimeType.series
          ? (int.tryParse(_seasonController.text.trim()) ?? 1)
          : null,
      totalEpisodes: _type == AnimeType.series && _totalEpisodesController.text.trim().isNotEmpty
          ? int.tryParse(_totalEpisodesController.text.trim())
          : null,
      notificationDay: _notificationDay,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final newId = await DatabaseHelper.instance.insertAnime(anime);

    if (anime.totalEpisodes != null && anime.totalEpisodes! > 0) {
      await DatabaseHelper.instance.generateEpisodesForAnime(newId, anime.totalEpisodes!);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Widget _sectionCard({required String label, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _accentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _radioOption<T>({
    required String label,
    required T value,
    required T groupValue,
    required Color activeColor,
    required ValueChanged<T> onTap,
  }) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? activeColor : _textMuted, width: 1.5),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: selected ? _textPrimary : _textSecondary,
            ),
          ),
        ],
      ),
    );
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: _textPrimary, size: 20),
                  ),
                  Text('New entry', style: TextStyle(fontFamily: 'PTSerif', fontSize: 15, color: _textPrimary)),
                  GestureDetector(
                    onTap: _saveAnime,
                    child: Text('Save', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _accentColor)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 88,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _borderColor),
                            ),
                            child: _imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                  )
                                : Icon(Icons.add_a_photo_outlined, color: _textMuted, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: _titleEnglishController,
                                style: TextStyle(color: _textPrimary, fontFamily: 'Inter', fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Title (English)',
                                  hintStyle: TextStyle(color: _textMuted, fontFamily: 'Inter', fontSize: 13),
                                  isDense: true,
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _titleRomajiController,
                                style: TextStyle(color: _textPrimary, fontFamily: 'Inter', fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Title (Romaji)',
                                  hintStyle: TextStyle(color: _textMuted, fontFamily: 'Inter', fontSize: 13),
                                  isDense: true,
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentColor)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_titleError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_titleError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    const SizedBox(height: 20),

                    _sectionCard(
                      label: 'TYPE',
                      icon: Icons.category_outlined,
                      child: Row(
                        children: [
                          _radioOption(
                            label: 'Series',
                            value: AnimeType.series,
                            groupValue: _type,
                            activeColor: _accentColor,
                            onTap: (value) => setState(() => _type = value),
                          ),
                          const SizedBox(width: 16),
                          _radioOption(
                            label: 'Movie',
                            value: AnimeType.movie,
                            groupValue: _type,
                            activeColor: _accentColor,
                            onTap: (value) => setState(() => _type = value),
                          ),
                        ],
                      ),
                    ),

                    _sectionCard(
                      label: 'STATUS',
                      icon: Icons.trending_up,
                      child: Row(
                        children: [
                          _radioOption(
                            label: 'Watching',
                            value: AnimeStatus.currentlyWatching,
                            groupValue: _status,
                            activeColor: _statusColor,
                            onTap: (value) => setState(() => _status = value),
                          ),
                          const SizedBox(width: 16),
                          _radioOption(
                            label: 'Finished',
                            value: AnimeStatus.finishedWatching,
                            groupValue: _status,
                            activeColor: _statusColor,
                            onTap: (value) => setState(() => _status = value),
                          ),
                        ],
                      ),
                    ),

                    if (_type == AnimeType.series)
                      _sectionCard(
                        label: 'PROGRESS',
                        icon: Icons.play_circle_outline,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Season', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _textMuted)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _seasonController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _textPrimary, fontFamily: 'Inter', fontSize: 13),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: _bgColor,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Episodes out', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _textMuted)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _totalEpisodesController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _textPrimary, fontFamily: 'Inter', fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 12',
                                      hintStyle: TextStyle(color: _textMuted, fontSize: 12),
                                      filled: true,
                                      fillColor: _bgColor,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    _sectionCard(
                      label: 'GENRES',
                      icon: Icons.sell_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: _openGenrePicker,
                                child: Icon(Icons.add, size: 18, color: _accentColor),
                              ),
                            ],
                          ),
                          if (_selectedGenres.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _selectedGenres.map((genre) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E1005),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    genre,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Color(0xFFF0997B),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            GestureDetector(
                              onTap: _openGenrePicker,
                              child: Text('Tap + to add genres', style: TextStyle(color: _textMuted, fontFamily: 'Inter', fontSize: 12)),
                            ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: _openNotificationDayPicker,
                      child: _sectionCard(
                        label: 'NOTIFY ME ON',
                        icon: Icons.notifications_outlined,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _notificationDay ?? 'Not set',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: _notificationDay != null ? _textPrimary : _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: _openDescriptionEditor,
                      child: _sectionCard(
                        label: 'DESCRIPTION',
                        icon: Icons.notes_outlined,
                        child: Text(
                          _descriptionController.text.isEmpty
                              ? 'Add your own notes about this anime...'
                              : _descriptionController.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: _descriptionController.text.isEmpty ? _textMuted : _textPrimary,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: _favoriteColor),
                              const SizedBox(width: 6),
                              Text('Add to favorites', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _textPrimary)),
                            ],
                          ),
                          Switch(
                            value: _isFavorite,
                            activeColor: _accentColor,
                            onChanged: (value) => setState(() => _isFavorite = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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