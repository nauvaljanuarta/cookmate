import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/pages/recipe/add_recipe_page.dart';
import 'package:cookmate2/pages/recipe/detail_recipe_page.dart';
import 'package:cookmate2/pages/recipe/edit_recipe_page.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:cookmate2/widgets/editable_recipe_card.dart';
import 'package:flutter/cupertino.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final RecipeService _recipeService = RecipeService();
  late Future<List<Recipe>> _userRecipesFuture;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = PocketBaseClient.instance.authStore.model?.id;
    _refreshRecipes();
  }

  void _refreshRecipes() {
    if (_userId != null) {
      setState(() {
        _userRecipesFuture = _recipeService.getUserRecipes(_userId!);
      });
    } else {
      setState(() {
        _userRecipesFuture = Future.value([]);
      });
    }
  }

  // PERBAIKAN: Menggunakan CupertinoAlertDialog untuk feedback
  void _showFeedbackDialog(String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _deleteRecipe(String recipeId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Do you want to delete your recipe?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _recipeService.deleteRecipe(recipeId);
                _showFeedbackDialog('Success', 'Recipe Deleted');
                _refreshRecipes();
              } catch (e) {
                _showFeedbackDialog('Error', 'Failed to delete your recipe: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('My Recipes'),
      ),
      child: FutureBuilder<List<Recipe>>(
        future: _userRecipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "You don't have any recipes.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                        CupertinoPageRoute(builder: (context) => const AddRecipePage()),
                      )
                          .then((value) {
                        if (value == true) {
                          _refreshRecipes();
                        }
                      });
                    },
                    child: const Text(
                      'Create Your First Recipe',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: EditableRecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => RecipeDetail(recipe: recipe),
                      ),
                    );
                  },
                  onEdit: () {
                    Navigator.of(context)
                        .push<bool>(
                      CupertinoPageRoute(
                        builder: (context) => EditRecipePage(recipe: recipe),
                      ),
                    )
                        .then((result) {
                      // Refresh jika halaman edit mengembalikan `true`
                      if (result == true) {
                        _refreshRecipes();
                      }
                    });
                  },
                  onDelete: () {
                    _deleteRecipe(recipe.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
