import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: AppTheme.cardHeight,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRecipeImage(),
                  const SizedBox(height: 30), // Ruang untuk avatar
                  _buildRecipeTextDetails(),
                ],
              ),
              _buildAuthorAvatar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget untuk menampilkan gambar resep
  Widget _buildRecipeImage() {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: Image.network(
        recipe.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: CupertinoColors.systemGrey5,
            child: const Center(
              child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 40),
            ),
          );
        },
      ),
    );
  }

  /// Widget untuk menampilkan avatar penulis di posisi kanan
  Widget _buildAuthorAvatar() {
    return Positioned(
      top: 128,
      right: 16,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(recipe.authorImageUrl),
          backgroundColor: CupertinoColors.systemGrey5,
        ),
      ),
    );
  }

  Widget _buildRecipeTextDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            recipe.title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            recipe.description,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 4),
          const Divider(color: CupertinoColors.systemGrey5),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onFavoriteTap,
                  child: Row(
                    children: [
                      Icon(
                        isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        color: isFavorite ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Favorite',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          color: isFavorite ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(CupertinoIcons.arrow_right, color: AppTheme.primaryColor, size: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}