import 'package:flutter/material.dart';
import 'dart:io';
import 'package:noteiru/models/anime_model.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final String? badgeText;
  final Color badgeColor;

  const AnimeCard({
    super.key,
    required this.anime,
    this.onTap,
    this.onFavoriteToggle,
    this.badgeText,
    this.badgeColor = const Color(0xFF5DCAA5),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 104,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF231E15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2E2820), width: 0.5),
                  ),
                  child: anime.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(anime.imagePath!), fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined, color: Color(0xFF5F5E5A), size: 24),
                        ),
                ),
                if (badgeText != null)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xE60F0D09),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(fontSize: 9, color: badgeColor, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Icon(
                      anime.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: anime.isFavorite ? const Color(0xFFD4537E) : const Color(0xFFC0BCB6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              anime.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'PTSerif',
                fontStyle: FontStyle.italic,
                fontSize: 11,
                color: Color(0xFFECD4C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}