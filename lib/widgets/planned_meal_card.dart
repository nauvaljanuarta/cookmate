import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/meal_ingredient.dart';
import 'package:cookmate2/models/meal_plan.dart';
import 'package:cookmate2/pages/recipe/detail_recipe_page.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;

class PlannedMealCard extends StatefulWidget {
  final MealPlan mealPlan;
  final VoidCallback onDelete;

  const PlannedMealCard({
    super.key,
    required this.mealPlan,
    required this.onDelete,
  });

  @override
  State<PlannedMealCard> createState() => _PlannedMealCardState();
}

class _PlannedMealCardState extends State<PlannedMealCard> {
  final RecipeService _recipeService = RecipeService();
  late Future<List<MealIngredient>> _ingredientsFuture;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.mealPlan.meal != null) {
      _ingredientsFuture = _recipeService.getIngredientsForRecipe(widget.mealPlan.meal!.id).then((records) => records.map((rec) => MealIngredient.fromRecord(rec)).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.mealPlan.meal;
    if (recipe == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => RecipeDetail(recipe: recipe),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              spreadRadius: 4,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recipe.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70,
                      height: 70,
                      color: CupertinoColors.systemGrey5,
                      child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.name, style: AppTheme.subheadingStyle.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        recipe.categories.join(' • '),
                        style: AppTheme.captionStyle.copyWith(color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.clear_circled_solid, color: CupertinoColors.systemGrey),
                  onPressed: widget.onDelete,
                )
              ],
            ),
            if (_isExpanded) ...[
              const Divider(height: 20),
              _buildIngredientsList(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsList() {
    return FutureBuilder<List<MealIngredient>>(
      future: _ingredientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CupertinoActivityIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No ingredients listed for this recipe.');
        }
        final ingredients = snapshot.data!;
        return Column(
          children: ingredients
              .map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.circle_fill, size: 8, color: CupertinoColors.systemGrey2),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ing.name)),
                        Text(
                          '${ing.quantity.toStringAsFixed(1).replaceAll(RegExp(r'\\.0$'), '')} ${ing.unit}',
                          style: const TextStyle(color: CupertinoColors.systemGrey),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
