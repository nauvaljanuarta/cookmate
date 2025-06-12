// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors;
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/pages/recipe/detail_recipe_page.dart';
import 'dart:ui'; // Import untuk BackdropFilter

class StackedRecipeCards extends StatefulWidget {
  final List<Recipe> recipes;

  const StackedRecipeCards({
    super.key,
    required this.recipes,
  });

  @override
  State<StackedRecipeCards> createState() => _StackedRecipeCardsState();
}

class _StackedRecipeCardsState extends State<StackedRecipeCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.recipes.length;
        _controller.reset();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onSwipe() {
    // Memulai animasi swipe
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipes.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text("No daily recipes available."),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Recipe',
                style: AppTheme.subheadingStyle,
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text(
                  'Swipe to see more',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
                onPressed: _onSwipe,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250, // Menyesuaikan tinggi untuk desain baru yang lebih ringkas
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              // Jika swipe ke kiri (velocity negatif) atau kanan (velocity positif) cukup kencang
              if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 200) {
                 _onSwipe();
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(
                widget.recipes.length.clamp(0, 10), // Tampilkan maks 3 kartu
                (index) {
                  final itemIndex = (_currentIndex + index) % widget.recipes.length;
                  final recipe = widget.recipes[itemIndex];
                  return _buildCard(recipe, index);
                },
              ).reversed.toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// --- PERUBAHAN UTAMA: DESAIN KARTU BARU ---
  Widget _buildCard(Recipe recipe, int stackIndex) {
    // Animasi untuk kartu terdepan (index 0)
    final topCardAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final positionOffset = (stackIndex * 12.0) - (_controller.value * 12.0);
    final scale = 1.0 - (stackIndex * 0.05) + (_controller.value * 0.05);

    Widget card = Transform.scale(
      scale: scale,
      child: Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(recipe.imageUrl),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {}, // Handle error jika gambar gagal dimuat
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _buildCardOverlay(recipe, stackIndex),
      ),
    );

    // Terapkan animasi slide out dan fade out hanya untuk kartu paling atas
    if (stackIndex == 0) {
      return AnimatedBuilder(
        animation: topCardAnimation,
        child: card,
        builder: (context, child) {
          final slideOffset = Offset(-topCardAnimation.value * 1.5, 0);
          final fadeValue = 1.0 - topCardAnimation.value;
          return Opacity(
            opacity: fadeValue.clamp(0.0, 1.0),
            child: FractionalTranslation(
              translation: slideOffset,
              child: child,
            ),
          );
        },
      );
    }

    // Terapkan transformasi posisi untuk kartu di belakang
    return Transform.translate(
      offset: Offset(0, positionOffset),
      child: card,
    );
  }
  
  /// Widget untuk overlay (gradien, judul, avatar) di atas gambar
  Widget _buildCardOverlay(Recipe recipe, int stackIndex) {
    return GestureDetector(
      onTap: stackIndex == 0 ? () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => RecipeDetail(recipe: recipe),
          ),
        );
      } : null, // Hanya kartu terdepan yang bisa di-tap
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.6),
            ],
            stops: const [0.5, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Judul Makanan di Kiri Bawah
            Positioned(
              bottom: 16,
              left: 16,
              right: 80, // Beri ruang untuk avatar
              child: Text(
                recipe.title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Avatar Penulis di Kanan Bawah
            Positioned(
              bottom: 16,
              right: 16,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(recipe.authorImageUrl),
                  backgroundColor: CupertinoColors.systemGrey5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
