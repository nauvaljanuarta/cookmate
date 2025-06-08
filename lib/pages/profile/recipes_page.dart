import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/pages/recipe/recipe_detail.dart';
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
    _loadUserRecipes();
  }

  void _loadUserRecipes() {
    final userId = PocketBaseClient.instance.authStore.model?.id;
    if (userId != null) {
      setState(() {
        _userRecipesFuture = _recipeService.getUserRecipes(userId);
      });
    } else {
      // Jika tidak ada user yang login, tampilkan daftar kosong.
      setState(() {
        _userRecipesFuture = Future.value([]);
      });
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
          // Tampilkan indikator loading saat data sedang diambil.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          // Tampilkan pesan error jika terjadi masalah.
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Jika tidak ada data atau data kosong, tampilkan pesan.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Anda belum memiliki resep.\nAyo buat resep pertamamu!',
                textAlign: TextAlign.center,
              ),
            );
          }

          // Jika data berhasil diambil, tampilkan daftar resep.
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
