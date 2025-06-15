import 'dart:async';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/pages/recipe/detail_recipe_page.dart';
import 'package:cookmate2/services/recipe_service.dart';
import 'package:cookmate2/widgets/category_card.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _recipeService = RecipeService();
  Timer? _debounce;

  // State Management
  String _currentQuery = '';
  List<String> _recentSearches = [];
  Future<List<Recipe>>? _searchResultsFuture;

  Future<List<RecordModel>>? _categoriesFuture;
  Future<List<Recipe>>? _exploreRecipesFuture;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadRecentSearches();
    // Pindahkan pemanggilan setState ke dalam fungsi refresh
    // agar bisa dipanggil ulang
    _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _categoriesFuture = _recipeService.getMealCategories();
      _exploreRecipesFuture = _recipeService.getAllRecipes(limit: 10);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final trimmedQuery = query.trim();
      if (trimmedQuery.length > 1) {
        _performSearch(trimmedQuery);
      } else if (trimmedQuery.isEmpty) {
        _clearSearch();
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    _searchController.text = query;
    _addToRecentSearches(query);
    setState(() {
      _currentQuery = query;
      _searchResultsFuture = _recipeService.searchRecipes(query);
    });
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _searchResultsFuture = null;
    });
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches = prefs.getStringList('recent_searches') ?? [];
      });
    }
  }

  Future<void> _addToRecentSearches(String term) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches
            .removeWhere((item) => item.toLowerCase() == term.toLowerCase());
        _recentSearches.insert(0, term);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.sublist(0, 5);
        }
      });
    }
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void _removeRecentSearch(String term) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _recentSearches.remove(term);
      });
    }
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan CustomScrollView untuk mendukung Sliver
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Explore'),
      ),
      child: CustomScrollView(
        slivers: [
          // Widget untuk fungsionalitas Refresh
          CupertinoSliverRefreshControl(
            onRefresh: _handleRefresh,
          ),
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search recipes, ingredients, categories...',
                onChanged: _onSearchChanged,
                onSubmitted: _performSearch,
              ),
            ),
          ),
          // Konten dinamis (Hasil Pencarian atau Saran)
          _currentQuery.isNotEmpty
              ? _buildSearchResultsSliver()
              : _buildSearchSuggestionsSliver(),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSliver() {
    return FutureBuilder<List<Recipe>>(
      future: _searchResultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 18)));
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
              child: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text('No results found for "$_currentQuery"'),
            ),
          );
        }

        final recipes = snapshot.data!;
        // Gunakan SliverGrid sebagai pengganti GridView
        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.64,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = recipes[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    Navigator.of(context).push(CupertinoPageRoute(
                      builder: (context) => RecipeDetail(recipe: recipe),
                    ));
                  },
                );
              },
              childCount: recipes.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSuggestionsSliver() {
    return SliverList(
      delegate: SliverChildListDelegate([
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildSectionTitle('Recent Searches', showClear: true,
                onClear: () {
              setState(() => _recentSearches.clear());
              SharedPreferences.getInstance()
                  .then((p) => p.remove('recent_searches'));
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((term) => _buildChip(
                        term,
                        icon: CupertinoIcons.clock,
                        onTap: () => _performSearch(term),
                        onLongPress: () => _removeRecentSearch(term),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSectionTitle('Popular Categories'),
        ),
        FutureBuilder<List<RecordModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CupertinoActivityIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No categories found.'),
              );

            final categories = snapshot.data!;
            return SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    title: category.data['name'],
                    onTap: () => _performSearch(category.data['name']),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSectionTitle('Explore Recipes'),
        ),
        // Untuk Grid di dalam ListView, kita bungkus dengan FutureBuilder dan GridView
        FutureBuilder<List<Recipe>>(
          future: _exploreRecipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CupertinoActivityIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No recipes to explore.'),
              );

            final recipes = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.64,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => RecipeDetail(recipe: recipe),
                      ));
                    });
              },
            );
          },
        ),
      ]),
    );
  }

  Widget _buildSectionTitle(String title,
      {bool showClear = false, VoidCallback? onClear}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.subheadingStyle),
          if (showClear)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('Clear',
                  style: TextStyle(color: CupertinoColors.systemGrey)),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label,
      {required IconData icon, VoidCallback? onTap, VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: CupertinoColors.secondaryLabel),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

