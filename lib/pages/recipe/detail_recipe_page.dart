import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/meal_ingredient.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/models/step.dart' as model_step;
import 'package:cookmate2/services/meal_plan_service.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Divider;
import 'package:pocketbase/pocketbase.dart';

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
  final MealPlanService _mealPlanService = MealPlanService();

  late final Future<List<model_step.Step>> _stepsFuture;
  late final Future<List<RecordModel>> _ingredientsFuture;

  bool _isAlreadyPlanned = false;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _stepsFuture = _recipeService.getStepsForRecipe(widget.recipe.id);
    _ingredientsFuture = _recipeService.getIngredientsForRecipe(widget.recipe.id);
    _checkIfPlanned();
  }

  Future<void> _checkIfPlanned() async {
    if (!mounted) return;
    setState(() {
      _isCheckingStatus = true;
    });

    final isPlanned = await _mealPlanService.checkIfMealIsPlanned(widget.recipe.id);

    if (mounted) {
      setState(() {
        _isAlreadyPlanned = isPlanned;
        _isCheckingStatus = false;
      });
    }
  }

  Future<String?> _showDaySelectionDialog() async {
    final days = await _mealPlanService.getDays();
    if (!mounted) return null;

    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Choose a day to cook this recipe'),
        actions: days
            .map((day) => CupertinoActionSheetAction(
                  child: Text(day.name),
                  onPressed: () => Navigator.of(context).pop(day.id),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _handleAddToMealPlan() async {
    final selectedDayId = await _showDaySelectionDialog();
    if (selectedDayId == null) return;

    if (mounted) {
      showCupertinoDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CupertinoActivityIndicator()));
    }

    try {
      await _mealPlanService.addMealPlan(mealId: widget.recipe.id, dayId: selectedDayId);

      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _isAlreadyPlanned = true;
        });

        showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: const Text('Success'),
                  content: Text('${widget.recipe.name} has been added to your meal plan.'),
                  actions: [
                    CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.of(context).pop())
                  ],
                ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
                  title: const Text('Failed'),
                  content: Text('An error occurred: $e'),
                  actions: [
                    CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.of(context).pop())
                  ],
                ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(largeTitle: Text(widget.recipe.name), trailing: _buildNavBarActions()),
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
                      const SizedBox(height: 16),
                      Text(
                        widget.recipe.description,
                        style: AppTheme.bodyStyle.copyWith(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        _buildInfoCard(context, CupertinoIcons.timer, '${widget.recipe.times} min', 'Total Time'),
                        _buildInfoCard(context, CupertinoIcons.chart_bar_alt_fill, widget.recipe.difficulty, 'Difficulty'),
                        _buildInfoCard(context, CupertinoIcons.person_2, '${widget.recipe.servings}', 'Servings'),
                      ]),
                      const SizedBox(height: 20),
                      _buildIngredientsSection(),
                      const SizedBox(height: 20),
                      _buildStepsSection(),
                      const SizedBox(height: 32),
                      SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: _isCheckingStatus || _isAlreadyPlanned ? null : _handleAddToMealPlan,
                            child: _isCheckingStatus
                                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(_isAlreadyPlanned ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.calendar_badge_plus, size: 20),
                                    const SizedBox(width: 8),
                                    Text(_isAlreadyPlanned ? 'Added to Meal Plan' : 'Add to Meal Plan'),
                                  ]),
                          )),
                    ],
                  )),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildNavBarActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [],
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return _buildSectionCard(
      title: 'Ingredients',
      child: FutureBuilder<List<RecordModel>>(
        future: _ingredientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CupertinoActivityIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No ingredients found.'));

          final ingredients = snapshot.data!.map((record) => MealIngredient.fromRecord(record)).toList();

          return Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: ListView.separated(
              itemCount: ingredients.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final ingredient = ingredients[index];
                return Row(children: [
                  const Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(ingredient.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                  Text('${ingredient.quantity.toStringAsFixed(0).replaceAll(RegExp(r'\\.0$'), '')} ${ingredient.unit}'.trim(), style: const TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                ]);
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
      child: FutureBuilder<List<model_step.Step>>(
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
            padding: const EdgeInsets.only(top: 2.0),
            child: ListView.separated(
              itemCount: steps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(height: 10),
              itemBuilder: (context, index) {
                final step = steps[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${step.number}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.description,
                          style: const TextStyle(fontSize: 16, height: 1.4),
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
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
