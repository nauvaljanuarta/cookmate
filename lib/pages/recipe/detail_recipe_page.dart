import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/meal_ingredient.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/models/step.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Divider;

class RecipeDetail extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetail({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  final RecipeService _recipeService = RecipeService();
  late final Future<List<Step>> _stepsFuture;
  late final Future<List<MealIngredient>> _ingredientsFuture;

  @override
  void initState() {
    super.initState();
    _stepsFuture = _recipeService.getStepsForRecipe(widget.recipe.id);
    _ingredientsFuture = _recipeService.getIngredientsForRecipe(widget.recipe.id);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(widget.recipe.title),
            trailing: _buildNavBarActions(),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecipeImage(),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorInfo(),
                      const SizedBox(height: 20),

                      // Kartu Info Resep
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoCard(context, CupertinoIcons.timer, '${widget.recipe.prepTimeMinutes + widget.recipe.cookTimeMinutes} min', 'Total Time'),
                          _buildInfoCard(context, CupertinoIcons.chart_bar, widget.recipe.difficulty, 'Difficulty'),
                          _buildInfoCard(context, CupertinoIcons.person_2, '${widget.recipe.servings}', 'Servings'),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      _buildIngredientsSection(),
                      
                      const SizedBox(height: 16),
                      
                      _buildStepsSection(),

                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: const Text('Start Cooking'),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget untuk tombol aksi di Navigation Bar
  Widget _buildNavBarActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            widget.recipe.isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            color: widget.recipe.isFavorite ? CupertinoColors.systemRed : AppTheme.primaryColor,
          ),
          onPressed: () {},
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.share, color: AppTheme.primaryColor),
          onPressed: () {},
        ),
      ],
    );
  }

  /// Widget untuk menampilkan gambar utama dengan sudut membulat
  Widget _buildRecipeImage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: SizedBox(
          width: double.infinity,
          height: 250,
          child: Image.network(
            widget.recipe.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: CupertinoColors.systemGrey5,
              child: const Center(child: Icon(CupertinoIcons.photo, size: 50)),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget untuk menampilkan informasi penulis resep
  Widget _buildAuthorInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(widget.recipe.authorImageUrl),
          backgroundColor: CupertinoColors.systemGrey5,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe.authorName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Recipe Author',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

 Widget _buildSectionCard({required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Reduced vertical padding from 16.0 to 12.0
    decoration: BoxDecoration(
      color: CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.subheadingStyle,
        ),
        // Removed SizedBox(height: 8) entirely for minimal gap
        child,
      ],
    ),
  );
}

Widget _buildIngredientsSection() {
  return _buildSectionCard(
    title: 'Ingredients',
    child: FutureBuilder<List<MealIngredient>>(
      future: _ingredientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No ingredients found.'));
        }

        final ingredients = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(top: 4.0), // Minimal top padding to avoid gap
          child: ListView.separated(
            itemCount: ingredients.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(height: 12), // Reduced from 16 to 12
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              return Row(
                children: [
                  const Icon(CupertinoIcons.circle_filled, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '${ingredient.quantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${ingredient.unit}'.trim(),
                    style: const TextStyle(fontSize: 16, color: CupertinoColors.systemGrey2),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

Widget _buildStepsSection() {
  return _buildSectionCard(
    title: 'Instructions',
    child: FutureBuilder<List<Step>>(
      future: _stepsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No instructions available.'));
        }

        final steps = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(top: 2.0), // Minimal top padding to avoid gap
          child: ListView.builder(
            itemCount: steps.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final step = steps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Reduced from 12 to 8
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20, // Circle size
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.1), // Light background
                        border: Border.all(color: AppTheme.primaryColor, width: 2), // Border
                      ),
                      child: Center(
                        child: Text(
                          '${step.number}',
                          style: const TextStyle(
                            fontSize: 12, // Slightly smaller for circle fit
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

  Widget _buildInfoCard(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            Text(label, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
