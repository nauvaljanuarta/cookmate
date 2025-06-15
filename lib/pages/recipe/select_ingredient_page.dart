import 'dart:async';

import 'package:cookmate2/services/recipe_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class SelectIngredientPage extends StatefulWidget {
  const SelectIngredientPage({super.key});

  @override
  State<SelectIngredientPage> createState() => _SelectIngredientPageState();
}

class _SelectIngredientPageState extends State<SelectIngredientPage> {
  final _recipeService = RecipeService();
  final _searchController = TextEditingController();
  List<RecordModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await _recipeService.searchIngredients(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  /// Membuat bahan baru dan langsung mengembalikannya.
  Future<void> _createNewIngredient() async {
    final newIngredientName = _searchController.text.trim();
    if (newIngredientName.isEmpty) return;

    try {
      final newRecord = await _recipeService.addIngredient(newIngredientName);
      if (mounted) {
        // Kembali ke halaman sebelumnya dengan membawa data bahan yang baru dibuat
        Navigator.pop(context, newRecord);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create ingredient: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Select Ingredient'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search or create new ingredient...',
                onChanged: _onSearchChanged,
                autofocus: true,
              ),
            ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length + 1, // +1 untuk tombol "Create New"
                itemBuilder: (context, index) {
                  // Tombol untuk membuat bahan baru jika tidak ada hasil
                  if (index == _searchResults.length) {
                    if (!_isSearching && _searchController.text.isNotEmpty && _searchResults.isEmpty) {
                      return CupertinoListTile(
                        title: Text('Create new: "${_searchController.text}"'),
                        leading: const Icon(CupertinoIcons.add_circled_solid),
                        onTap: _createNewIngredient,
                      );
                    }
                    return const SizedBox.shrink(); // Kosong jika ada hasil atau sedang mencari
                  }

                  // Tampilkan hasil pencarian
                  final ingredient = _searchResults[index];
                  return CupertinoListTile(
                    title: Text(ingredient.data['name']),
                    onTap: () {
                      // Kembali ke halaman sebelumnya dengan membawa data bahan yang dipilih
                      Navigator.pop(context, ingredient);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
