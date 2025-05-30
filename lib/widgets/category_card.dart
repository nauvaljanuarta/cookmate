import 'package:flutter/cupertino.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  // Get a color based on the category name
  Color _getCategoryColor() {
    switch (title.toLowerCase()) {
      case 'breakfast':
        return CupertinoColors.systemYellow;
      case 'lunch':
        return CupertinoColors.systemGreen;
      case 'dinner':
        return CupertinoColors.systemIndigo;
      case 'dessert':
        return CupertinoColors.systemPink;
      case 'italia':
        return CupertinoColors.systemRed;
      case 'india':
        return CupertinoColors.systemOrange;
      case 'vegetarian':
        return CupertinoColors.activeGreen;
      case 'ayam':
        return CupertinoColors.systemBrown;
      case 'pasta':
        return CupertinoColors.systemOrange;
      case 'kari':
        return CupertinoColors.systemPurple;
      case 'baking':
        return CupertinoColors.systemYellow;
      case 'cookies':
        return CupertinoColors.systemBrown;
      case 'quick meals':
        return CupertinoColors.systemTeal;
      default:
        return CupertinoColors.systemBlue;
    }
  }

  // Get an icon based on the category name
  IconData _getCategoryIcon() {
    switch (title.toLowerCase()) {
      case 'sarapan':
        return CupertinoIcons.sun_max;
      case 'lunch':
        return CupertinoIcons.clock;
      case 'dinner':
        return CupertinoIcons.moon;
      case 'dessert':
        return CupertinoIcons.snow;
      case 'italia':
        return CupertinoIcons.flag;
      case 'india':
        return CupertinoIcons.flag;
      case 'vegetarian':
        return CupertinoIcons.leaf_arrow_circlepath;
      case 'ayam':
        return CupertinoIcons.paw;
      case 'pasta':
        return CupertinoIcons.circle_grid_hex;
      case 'kari':
        return CupertinoIcons.flame;
      case 'membakar':
        return CupertinoIcons.thermometer;
      case 'cookies':
        return CupertinoIcons.circle_grid_3x3;
      case 'cepat saji':
        return CupertinoIcons.timer;
      default:
        return CupertinoIcons.question;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();
    final icon = _getCategoryIcon();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

