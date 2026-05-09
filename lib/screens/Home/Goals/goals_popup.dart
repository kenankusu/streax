import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streax/services/database.dart';
import 'goal_dialogs.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ZielePopup extends StatefulWidget {
  const ZielePopup({super.key});

  @override
  State<ZielePopup> createState() => _ZielePopupState();
}

class _ZielePopupState extends State<ZielePopup> {
  List<DocumentSnapshot>? _localGoals;
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const Center(child: Text('Fehler: Benutzer nicht gefunden'));
    }
    final userUid = firebaseUser.uid;

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
                child: StreamBuilder<QuerySnapshot>(
                  stream: DatabaseService(uid: userUid).userGoals,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _localGoals == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Fehler beim Laden der Ziele',
                            style: TextStyle(color: Colors.red)),
                      );
                    }
                    if (!_isReordering && snapshot.hasData) {
                      _localGoals = List.from(snapshot.data!.docs);
                    }
                    final goals = _localGoals ?? [];
                    if (goals.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.track_changes, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Noch keine Ziele vorhanden',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Füge dein erstes Ziel hinzu!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }
                    return ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: goals.length,
                      proxyDecorator: (child, index, animation) => Material(
                        elevation: 0,
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      ),
                      onReorder: (int oldIndex, int newIndex) async {
                        if (newIndex > oldIndex) newIndex -= 1;
                        setState(() {
                          _isReordering = true;
                          final item = goals.removeAt(oldIndex);
                          goals.insert(newIndex, item);
                        });
                        try {
                          await DatabaseService(uid: userUid)
                              .reorderGoals(goals.map((g) => g.id).toList());
                        } catch (e) {
                          setState(() {
                            final item = goals.removeAt(newIndex);
                            goals.insert(oldIndex, item);
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fehler beim Verschieben: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          setState(() => _isReordering = false);
                        }
                      },
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final data = goal.data() as Map<String, dynamic>;
                        return Card(
                          key: ValueKey(goal.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle, color: Colors.white70),
                            ),
                            title: Text(
                              _displayName(data),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              _subtitle(data),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white70),
                                  onPressed: () => GoalDialogs.showEditGoalDialog(context, goal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(context, goal.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _addButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addButton() {
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => GoalDialogs.showAddGoalDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Ziel hinzufügen',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'Event':
        return 'Event';
      case 'Gewicht':
        return 'Gewichtsziel';
      case 'Training':
        return 'Trainingsziel';
      default:
        return 'Unbekanntes Ziel';
    }
  }

  String _subtitle(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'Event':
        final name = data['name'] ?? '';
        final eventDate = data['eventDate'];
        if (eventDate != null) {
          try {
            final date = DateTime.parse(eventDate);
            final daysLeft = date.difference(DateTime.now()).inDays;
            return name.isNotEmpty ? '$name (noch $daysLeft Tage)' : 'Noch $daysLeft Tage';
          } catch (_) {
            return name.isNotEmpty ? name : 'Event';
          }
        }
        return name.isNotEmpty ? name : 'Event';
      case 'Gewicht':
        return '${(data['targetWeight'] as num?)?.toInt() ?? 0}kg erreichen';
      case 'Training':
        return '${(data['targetTrainings'] as num?)?.toInt() ?? 0}x pro Woche trainieren';
      default:
        return 'Unbekanntes Ziel';
    }
  }

  void _confirmDelete(BuildContext context, String goalId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: const Text('Ziel löschen', style: TextStyle(color: Colors.white)),
        content: const Text('Möchtest du dieses Ziel wirklich löschen?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final u = FirebaseAuth.instance.currentUser;
                if (u != null) await DatabaseService(uid: u.uid).deleteGoal(goalId);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Löschen: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
