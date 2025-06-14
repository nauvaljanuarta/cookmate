import 'package:cookmate2/config/pocketbase_client.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/models/user.dart' as model_user;
import 'package:cookmate2/pages/profile/meal_plan_page.dart';
import 'package:cookmate2/pages/profile/profile_page.dart';
import 'package:cookmate2/pages/recipe/add_recipe_page.dart';
import 'package:cookmate2/pages/recipe/detail_recipe_page.dart';
import 'package:cookmate2/pages/search/search_page.dart';
import 'package:cookmate2/services/meal_plan_service.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:cookmate2/services/user_service.dart';
import 'package:cookmate2/widgets/category_card.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:cookmate2/widgets/stacked_daily_recipe.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final RecipeService _recipeService = RecipeService();
  final UserService _userService = UserService();
  final MealPlanService _mealPlanService = MealPlanService();

  Future<List<Recipe>>? _allRecipesFuture;
  Future<List<Recipe>>? _dailyRecipesFuture;
  Future<List<RecordModel>>? _categoriesFuture;
  Set<String> _plannedRecipeIds = {};

  model_user.User? currentUser;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _mealPlanService.getAllPlannedRecipeIds().then((ids) {
      if (mounted) {
        setState(() {
          _plannedRecipeIds = ids;
        });
      }
    });

    setState(() {
      _allRecipesFuture = _recipeService.getAllRecipes(limit: 10);
      _dailyRecipesFuture = _recipeService.getAllRecipes(limit: 5);
      _categoriesFuture = _recipeService.getMealCategories();
      _loadUserData();
    });
  }

  void _loadUserData() {
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
      } else {
        profileImageUrl = null;
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
              if (index == 0 && _selectedIndex != 0) {
                _loadData();
              } else if (index == 3 && _selectedIndex != 3) {
                _loadData();
              }
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home, size: 20.0), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.search, size: 20.0),
                  label: 'Explore'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.plus_circle_fill, size: 20.0),
                  label: 'Add Recipe'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.collections, size: 20.0),
                  label: 'Meals Plan'),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person, size: 20.0),
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
                return const AddRecipePage();
              case 3:
                return const MealPlanPage();
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
        CustomScrollView(
          physics:
              const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async => _loadData(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 70)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Masak Apa yaa hari ini?', style: AppTheme.headingStyle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Recipe>>(
                future: _dailyRecipesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        height: 320,
                        child: Center(child: CupertinoActivityIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SizedBox(
                        height: 320,
                        child: Center(child: Text("Error: ${snapshot.error}")));
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return StackedRecipeCards(recipes: snapshot.data!);
                  }
                  return const SizedBox(
                      height: 320,
                      child: Center(child: Text("No daily recipes available.")));
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Categories', style: AppTheme.subheadingStyle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: FutureBuilder<List<RecordModel>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No categories found.'));
                    }
                    final categories = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return CategoryCard(
                            title: category.data['name'], onTap: () {});
                      },
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Featured Recipes',
                        style: AppTheme.subheadingStyle),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('See All',
                          style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: AppTheme.primaryColor)),
                      onPressed: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                            builder: (context) => const SearchPage()));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            _buildFeaturedRecipesHorizontalList(),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
        _buildCustomAppBar(context),
      ],
    );
  }

  Widget _buildFeaturedRecipesHorizontalList() {
    return FutureBuilder<List<Recipe>>(
      future: _allRecipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
              child: SizedBox(
                  height: AppTheme.cardHeight + AppTheme.spaceForShadow,
                  child: Center(child: CupertinoActivityIndicator())));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(child: Text("Error: ${snapshot.error}")));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No featured recipes found.'))));
        }

        final recipes = snapshot.data!;

        return SliverToBoxAdapter(
          child: SizedBox(
            height: AppTheme.cardHeight + AppTheme.spaceForShadow,
            child: ListView.builder(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              scrollDirection: Axis.horizontal,
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];

                return Container(
                  width: MediaQuery.of(context).size.width *
                      AppTheme.cardWidthRatio,
                  margin: const EdgeInsets.only(right: 16.0),
                  child: RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      Navigator.of(context)
                          .push(CupertinoPageRoute(
                            builder: (context) => RecipeDetail(recipe: recipe),
                          ))
                          .then((_) => _loadData());
                    },
                    isPlanned: _plannedRecipeIds.contains(recipe.id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color:
              CupertinoTheme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
          border: const Border(
              bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cookmate',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 4),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : null,
                backgroundColor: CupertinoColors.systemGrey5,
                child: profileImageUrl == null
                    ? const Icon(CupertinoIcons.person_fill,
                        size: 20, color: CupertinoColors.secondaryLabel)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}