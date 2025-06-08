// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/pages/recipe/recipe_detail.dart';

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
  late Animation<Offset> _animation;
  int _currentIndex = 0;
  double _dragStartX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
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

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragStartX = details.localPosition.dx;
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final currentDragX = details.localPosition.dx;
    final dragDifference = currentDragX - _dragStartX;

    // hanya bisa slide ke kanan
    if (dragDifference > 0) {
      final dragPercentage =
          dragDifference / MediaQuery.of(context).size.width;
      _controller.value = dragPercentage.clamp(0.0, 1.0);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
    });

    if (_controller.value > 0.3) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
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
                onPressed: () {
                  _controller.forward();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          // Menyesuaikan tinggi agar pas dengan kartu baru yang lebih besar
          height: 380,
          child: GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(
                widget.recipes.length.clamp(0, 3),
                (index) {
                  final itemIndex =
                      (_currentIndex + index) % widget.recipes.length;
                  final recipe = widget.recipes[itemIndex];

                  if (index == 0) {
                    return SlideTransition(
                      position: _animation,
                      child: _buildCard(recipe, index),
                    );
                  }
                  return _buildCard(recipe, index);
                },
              ).reversed.toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildCard sekarang diperbarui agar sesuai dengan desain RecipeCard
  Widget _buildCard(Recipe recipe, int stackIndex) {
    final double topOffset = -stackIndex * 10.0;
    final double scale = 1.0 - (stackIndex * 0.05);

    return Positioned(
      top: topOffset,
      child: Transform.scale(
        scale: scale,
        child: GestureDetector(
          onTap: stackIndex == 0
              ? () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      // Menggunakan RecipeDetail sesuai nama class yang benar
                      builder: (context) => RecipeDetail(recipe: recipe),
                    ),
                  );
                }
              : null,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            // Menyesuaikan tinggi kartu
            height: 360,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
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
            // Menggunakan Column untuk memisahkan gambar dan teks
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecipeImage(recipe),
                _buildRecipeTextDetails(recipe, stackIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeImage(Recipe recipe) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 200,
          child: Image.network(
            recipe.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: CupertinoColors.systemGrey5,
                child: const Center(
                  child: Icon(
                    CupertinoIcons.photo,
                    color: CupertinoColors.systemGrey,
                    size: 40,
                  ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
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
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(CupertinoIcons.timer, color: CupertinoColors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                    style: const TextStyle(
                        fontFamily: 'Montserrat', color: CupertinoColors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(CupertinoIcons.chart_bar, color: CupertinoColors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    recipe.difficulty,
                    style: const TextStyle(
                        fontFamily: 'Montserrat', color: CupertinoColors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              recipe.isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: recipe.isFavorite ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeTextDetails(Recipe recipe, int stackIndex) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recipe.description,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Hanya tampilkan detail di bawah jika kartu berada di posisi teratas
          if (stackIndex == 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.categories.join(' • '),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.arrow_right,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  'View Recipe',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
