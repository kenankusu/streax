import 'package:flutter/material.dart';

class GoalItem extends StatelessWidget {
  final String art;
  final String name;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GoalItem({
    required this.art,
    required this.name,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle,
            color: Colors.white,
          ),
        ),
        title: Text(
          art,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: SizedBox(
          width: 80,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.7), size: 20),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 20),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}