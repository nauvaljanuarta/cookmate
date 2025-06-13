import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/pages/recipe/detail_recipe_page.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:flutter/cupertino.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final RecipeService _recipeService = RecipeService();
  late Future<List<Recipe>> _userRecipesFuture;

  @override
  void initState() {
    super.initState();
    final userId = PocketBaseClient.instance.authStore.model?.id;
    if (userId != null) {
      _userRecipesFuture = _recipeService.getUserRecipes(userId);
    } else {
      _userRecipesFuture = Future.value([]);
    }
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
            return const Center(
              child: Text(
                'Anda belum memiliki resep.\nAyo buat resep pertamamu!',
                textAlign: TextAlign.center,
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
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => RecipeDetail(recipe: recipe),
                      ),
                    );
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
