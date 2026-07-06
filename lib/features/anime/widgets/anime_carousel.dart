import 'package:flutter/material.dart';
import 'package:noteiru/models/anime_model.dart';
import 'anime_card.dart';


class AnimeCarousel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Anime> animeList;
  final VoidCallback onViewAll;
  final String Function(Anime)? badgeTextBuilder;
  final Color badgeColor;

  const AnimeCarousel({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.animeList,
    required this.onViewAll,
    this.badgeTextBuilder,
    this.badgeColor = const Color(0xFF5DCAA5),
  });

  @override
  Widget build(BuildContext context) {
    if (animeList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: iconColor,),
                  const SizedBox(width: 5,),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'PTSerif',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFECD4C0),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'View all',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFFB84E22)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10,),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: animeList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10,),
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return AnimeCard(
                anime: anime,
                badgeText: badgeTextBuilder?.call(anime),
                badgeColor: badgeColor,
                onFavoriteToggle: (){
                  // toggle favorite + update database, wired up later
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20,),
      ],
    );
  }
}