
import 'package:flutter/cupertino.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/data/dummy_data.dart';
import 'package:cookmate2/pages/recipe/recipe_detail.dart';
import 'package:cookmate2/widgets/category_card.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:cookmate2/pages/splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final recipes = DummyData.recipes;
    
    // Extract unique categories
    final categories = <String>{};
    for (final recipe in recipes) {
      categories.addAll(recipe.categories);
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Cookmate',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.search),
              onPressed: () {
                // TODO: Implement search functionality
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.heart),
              onPressed: () {
                // TODO: Navigate to favorites
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.compass),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.bookmark),
                label: 'Saved',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                label: 'Profile',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            if (index == 0) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What would you like to cook today?',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 24),
                      
                      // Categories section
                      Text(
                        'Categories',
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: CategoryCard(
                                title: category,
                                onTap: () {
                                  // TODO: Navigate to category screen
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Featured recipes section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Recipes',
                            style: AppTheme.subheadingStyle,
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Text(
                              'See All',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            onPressed: () {
                              // TODO: Navigate to all recipes
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            onTap: () {
                              try {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                              } catch (e) {
                                print('Navigation error: $e');
                                // Show an error dialog or handle the error
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton.filled(child: const Text('splash'), 
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const SplashScreen()),
                        );
                      },
                    ),
                    ],
                  ),
                ),
              );
            } else if (index == 1) {
              return Center(
                child: Text(
                  'Explore Tab',
                  style: AppTheme.bodyStyle,
                ),
              );
            } else if (index == 2) {
              return Center(
                child: Text(
                  'Saved Tab',
                  style: AppTheme.bodyStyle,
                ),
              );
            } else {
              return Center(
                child: Text(
                  'Profile Tab',
                  style: AppTheme.bodyStyle,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

