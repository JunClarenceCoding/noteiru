import 'package:flutter/material.dart';
import '../features/anime/anime_home_screen.dart';
// import '../features/anime/anime_view_all_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static const home = '/';
  // static const viewAll = '/view-all';
  static const search = '/search';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const AnimeHomeScreen(),
    search: (_) => const SearchScreen(),
    settings: (_) => const SettingsScreen(),
    // viewAll is commented out here on purpose — see note below
  };
}