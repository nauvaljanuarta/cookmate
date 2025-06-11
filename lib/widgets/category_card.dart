import 'package:cookmate2/config/theme.dart';
import 'package:flutter/cupertino.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.only(right: 12), // Jarak antar pill
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
