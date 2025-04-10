import 'package:flutter/cupertino.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/data/dummy_data.dart';
import 'package:cookmate2/pages/recipe/recipe_detail.dart';
import 'package:cookmate2/widgets/category_card.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:cookmate2/widgets/stacked_daily_recipe.dart';
import 'package:cookmate2/pages/splash_screen.dart';
import 'package:cookmate2/pages/search/search_page.dart';
import 'package:cookmate2/pages/profile/profile_page.dart';

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
    final currentUser = DummyData.users[0]; // Get the current user
    
    // Extract unique categories
    final categories = <String>{};
    for (final recipe in recipes) {
      categories.addAll(recipe.categories);
    }

    return CupertinoPageScaffold(
      // Removed the navigation bar
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
                icon: Icon(CupertinoIcons.home, size: 22.0),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.search, size: 22.0),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.bookmark, size: 22.0),
                label: 'Saved',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person, size: 22.0),
                label: 'Profile',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            if (index == 0) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add some space at the top for the header actions
                        const SizedBox(height: 60),
                        
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Masak Apa yaa hari ini?',
                            style: AppTheme.headingStyle,
                          ),
                        ),
                        
                        // Stacked Recipe Cards
                        StackedRecipeCards(recipes: recipes),
                        
                        const SizedBox(height: 24),
                        
                        // Categories section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Categories',
                            style: AppTheme.subheadingStyle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
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
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: CupertinoButton.filled(
                            child: const Text('splash'), 
                            onPressed: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(builder: (_) => const SplashScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // Custom header with app title and profile picture
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // App title/logo
                          const Text(
                            'Cookmate',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          // Action buttons
                          Row(
                            children: [
                              // Favorites button
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.heart),
                                onPressed: () {
                                  
                                },
                              ),
                              
                              // foto profile
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) => const ProfilePage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.systemGrey.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image: AssetImage(currentUser.profileImageUrl ?? 
                                        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (index == 1) {  
              return const SearchPage();
            } else if (index == 2) {
              return Center(
                child: Text(
                  'Saved Tab',
                  style: AppTheme.bodyStyle,
                ),
              );
            } else {
              return  ProfilePage();
            }
          },
        ),
      ),
    );
  }
}