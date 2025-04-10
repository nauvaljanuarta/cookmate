import 'package:flutter/cupertino.dart';
import 'package:cookmate2/config/theme.dart';
import 'package:cookmate2/data/dummy_data.dart';
import 'package:cookmate2/models/user.dart';
import 'package:cookmate2/models/recipe.dart';
import 'package:cookmate2/widgets/recipe_card.dart';
import 'package:cookmate2/pages/recipe/recipe_detail.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User currentUser;
  late List<Recipe> userRecipes;
  bool isEditing = false;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // In a real app, you would get the current user from authentication
    currentUser = DummyData.users[0];
    _usernameController.text = currentUser.username;
    _bioController.text = currentUser.bio ?? '';
    
    // Filter recipes that would belong to this user (in a real app)
    userRecipes = DummyData.recipes.take(2).toList();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (isEditing) {
        // Save changes
        // In a real app, you would update the user in your database
        currentUser = currentUser.copyWith(
          username: _usernameController.text,
          bio: _bioController.text,
        );
      }
      isEditing = !isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Profile'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            isEditing ? 'Save' : 'Edit',
            style: TextStyle(
              color: AppTheme.primaryColor,
            ),
          ),
          onPressed: _toggleEdit,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(currentUser.profileImageUrl ?? 
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      isEditing
                          ? CupertinoTextField(
                              controller: _usernameController,
                              textAlign: TextAlign.center,
                              style: AppTheme.subheadingStyle,
                              placeholder: 'Username',
                            )
                          : Text(
                              currentUser.username,
                              style: AppTheme.subheadingStyle,
                            ),
                      const SizedBox(height: 8),
                      isEditing
                          ? CupertinoTextField(
                              controller: _bioController,
                              textAlign: TextAlign.center,
                              style: AppTheme.captionStyle,
                              placeholder: 'Add a bio',
                              maxLines: 3,
                            )
                          : Text(
                              currentUser.bio ?? 'No bio yet',
                              style: AppTheme.captionStyle,
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Recipes', '${userRecipes.length}'),
                      _buildStatItem('Followers', '245'),
                      _buildStatItem('Following', '86'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // My Recipes section
                Text(
                  'My Recipes',
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
                  itemCount: userRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = userRecipes[index];
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
                
                // Settings section
                Text(
                  'Settings',
                  style: AppTheme.subheadingStyle,
                ),
                const SizedBox(height: 12),
                
                _buildSettingsItem(
                  icon: CupertinoIcons.person,
                  title: 'Account',
                  onTap: () {
                    // Navigate to account settings
                  },
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.bell,
                  title: 'Notifications',
                  onTap: () {
                    // Navigate to notifications settings
                  },
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.lock,
                  title: 'Privacy',
                  onTap: () {
                    // Navigate to privacy settings
                  },
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.question_circle,
                  title: 'Help & Support',
                  onTap: () {
                    // Navigate to help & support
                  },
                ),
                _buildSettingsItem(
                  icon: CupertinoIcons.arrow_right_square,
                  title: 'Sign Out',
                  onTap: () {
                    // Sign out logic
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.bodyStyle,
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: CupertinoColors.systemGrey5,
          ),
      ],
    );
  }
}