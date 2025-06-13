import 'package:cookmate2/models/recipe.dart';
import 'package:flutter/cupertino.dart';

class EditableRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EditableRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  // Fungsi untuk menampilkan menu aksi (Edit/Delete)
  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(recipe.name),
        message: const Text('Choose One Below Delete Or Update?'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onEdit(); // Memanggil fungsi onEdit dari parent
            },
            child: const Text('Recipe edit'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              onDelete(); // Memanggil fungsi onDelete dari parent
            },
            child: const Text('Recipe Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar Resep
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                recipe.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: CupertinoColors.systemGrey5,
                  child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Judul dan Detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // PERBAIKAN: Mengambil item pertama dari List<String>
                    recipe.categories.isNotEmpty ? recipe.categories.first : 'Uncategorized',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),
            // Tombol Opsi (ellipsis)
            CupertinoButton(
              padding: const EdgeInsets.all(4),
              onPressed: () => _showActionSheet(context),
              child: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.systemGrey),
            )
          ],
        ),
      ),
    );
  }
}