import 'package:flutter/cupertino.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              CupertinoColors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
