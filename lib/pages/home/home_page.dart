import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/models/user.dart' as model_user;
import 'package:cookmate2/pages/profile/profile_page.dart';
import 'package:cookmate2/pages/recipe/recipe_detail.dart';
import 'package:cookmate2/pages/search/search_page.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:cookmate2/services/user_service.dart';
import 'package:cookmate2/widgets/category_card.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:cookmate2/widgets/stacked_daily_recipe.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final RecipeService _recipeService = RecipeService();
  final UserService _userService = UserService();

  late Future<List<Recipe>> _allRecipesFuture;
  late Future<List<Recipe>> _dailyRecipesFuture;
  model_user.User? currentUser;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _allRecipesFuture = _recipeService.getAllRecipes();
    _dailyRecipesFuture = _recipeService.getAllRecipes(limit: 3);

    final user = _userService.getCurrentUser();
    if (user != null) {
      currentUser = user;
      if (user.profileImage != null && user.profileImage!.isNotEmpty) {
        profileImageUrl = PocketBaseClient.instance.files
            .getUrl(
              PocketBaseClient.instance.authStore.model!,
              user.profileImage!,
            )
            .toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
            border: const Border(top: BorderSide(color: Colors.transparent)),
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home, size: 22.0), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.search, size: 22.0),
                  label: 'Explore'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.plus_circle_fill, size: 22.0),
                  label: 'Add Meal'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.collections, size: 22.0),
                  label: 'Meals Plan'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person, size: 22.0),
                  label: 'Profile'),
            ],
          ),
          tabBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildHomeScreen(context);
              case 1:
                return const SearchPage();
              case 2:
                return const Center(child: Text('Add Meal Tab'));
              case 3:
                return const Center(child: Text('Meals Plan'));
              case 4:
                return const ProfilePage();
              default:
                return _buildHomeScreen(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildHomeScreen(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), 
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Masak Apa yaa hari ini?', style: AppTheme.headingStyle),
              ),
              FutureBuilder<List<Recipe>>(
                future: _dailyRecipesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 320, child: Center(child: CupertinoActivityIndicator()));
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return StackedRecipeCards(recipes: snapshot.data!);
                  }
                  return const SizedBox(height: 320, child: Center(child: Text("No daily recipes.")));
                },
              ),
              const SizedBox(height: 36),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Categories', style: AppTheme.subheadingStyle),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryCard(title: 'Breakfast', imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8', onTap: () {}),
                    const SizedBox(width: 16),
                    CategoryCard(title: 'Lunch', imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe', onTap: () {}),
                    const SizedBox(width: 16),
                    CategoryCard(title: 'Dinner', imageUrl: 'https://images.unsplash.com/photo-1511690656952-34342bb7c2f2', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Featured Recipes', style: AppTheme.subheadingStyle),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('See All', style: TextStyle(fontFamily: 'Montserrat', color: AppTheme.primaryColor)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Recipe>>(
                future: _allRecipesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No featured recipes found.'));
                  }
                  final recipes = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.57,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () {
                          Navigator.of(context).push(CupertinoPageRoute(builder: (context) => RecipeDetail(recipe: recipe)));
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        _buildCustomAppBar(context),
      ],
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Positioned(
      top: -5,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(color: CupertinoColors.lightBackgroundGray, blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cookmate', style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                GestureDetector(
                  onTap: () => ProfilePage(),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                    backgroundColor: CupertinoColors.systemGrey5,
                    child: profileImageUrl == null ? const Icon(CupertinoIcons.person_fill, size: 20) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
