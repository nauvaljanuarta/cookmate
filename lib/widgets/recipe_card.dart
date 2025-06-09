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
      child: Container(

        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecipeImage(),
            _buildRecipeTextDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 180, 
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
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Text(
            recipe.title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              color: CupertinoColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: isFavorite ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeTextDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.description,
            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: CupertinoColors.systemGrey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(color: CupertinoColors.systemGrey5),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundImage: NetworkImage(recipe.authorImageUrl),
                backgroundColor: CupertinoColors.systemGrey5,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'By ${recipe.authorName}',
                  style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: CupertinoColors.systemGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(CupertinoIcons.arrow_right, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 4),
              const Text(
                'View Details',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
