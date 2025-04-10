import 'package:flutter/cupertino.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/data/dummy_data.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:cookmate2/pages/recipe/recipe_detail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _searchResults = [];
  List<String> _recentSearches = [
    'Pasta',
    'Chicken',
    'Vegetarian',
    'Quick Meals',
  ];
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = DummyData.recipes.where((recipe) {
          return recipe.title.toLowerCase().contains(query) ||
              recipe.description.toLowerCase().contains(query) ||
              recipe.categories.any((category) => category.toLowerCase().contains(query)) ||
              recipe.ingredients.any((ingredient) => ingredient.toLowerCase().contains(query));
        }).toList();
      }
    });
  }
  
  void _addToRecentSearches(String query) {
    if (query.isEmpty) return;
    
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });
  }
  
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
    });
  }
  
  void _performSearch(String query) {
    _searchController.text = query;
    _addToRecentSearches(query);
    _onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search recipes, ingredients...',
                onSubmitted: _performSearch,
                onSuffixTap: _clearSearch,
              ),
            ),
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildSearchSuggestions(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchSuggestions() {
    // Extract unique categories
    final categories = <String>{};
    for (final recipe in DummyData.recipes) {
      categories.addAll(recipe.categories);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () => _performSearch(search),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.clock,
                          size: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          search,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          Text(
            'Popular Categories',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.take(5).map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _performSearch(category),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.tag,
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: AppTheme.primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Explore Recipes',
            style: AppTheme.subheadingStyle,
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
            itemCount: DummyData.recipes.length,
            itemBuilder: (context, index) {
              final recipe = DummyData.recipes[index];
              return RecipeCard(
                recipe: recipe,
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => RecipeDetailScreen(recipe: recipe),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.search,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: AppTheme.bodyStyle.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: AppTheme.captionStyle,
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Results for "${_searchController.text}"',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final recipe = _searchResults[index];
            return RecipeCard(
              recipe: recipe,
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}