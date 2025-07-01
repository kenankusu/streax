import 'package:flutter/material.dart';
import 'goal_data.dart';      
import 'goal_item.dart';      
import 'goal_dialogues.dart'; 

class ZielePopup extends StatefulWidget {
  const ZielePopup({super.key});

  @override
  State<ZielePopup> createState() => _ZielePopupState();
}

class _ZielePopupState extends State<ZielePopup> {
  List<Map<String, String>> ziele = defaultGoals.map((goal) => goal.toMap()).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Text(
                'Ziele verwalten',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: ziele.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = ziele.removeAt(oldIndex);
                      ziele.insert(newIndex, item);
                    });
                  },
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: child,
                      ),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final ziel = ziele[index];
                    return GoalItem(
                      key: ValueKey('${ziel['name']}_$index'),
                      index: index,
                      art: ziel['art']!,
                      name: ziel['name']!,
                      onEdit: () => _editGoal(index),
                      onDelete: () => _deleteGoal(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildAddGoalButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddGoalButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _addGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Ziel hinzufügen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addGoal() {
    GoalDialogs.showAddGoalDialog(context, (goal) {
      setState(() => ziele.add(goal));
    });
  }

  void _editGoal(int index) {
    GoalDialogs.showEditGoalDialog(context, index, ziele[index], (goal) {
      setState(() => ziele[index] = goal);
    });
  }

  void _deleteGoal(int index) {
    setState(() => ziele.removeAt(index));
  }
}