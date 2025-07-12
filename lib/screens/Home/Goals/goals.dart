import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:streax/screens/shared/user.dart';
import 'package:streax/services/database.dart';
import 'package:streax/screens/home/goals/goal_dialogues.dart';

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
    final user = Provider.of<StreaxUser?>(context);

    if (user == null) {
      return Container(
        child: Center(child: Text('Fehler: Benutzer nicht gefunden')),
      );
    }

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
                  stream: DatabaseService(uid: user.uid).userGoals,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _localGoals == null) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Fehler beim Laden der Ziele',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    // Update lokale Liste nur wenn nicht gerade umsortiert wird
                    if (!_isReordering && snapshot.hasData) {
                      _localGoals = List.from(snapshot.data!.docs);
                    }

                    final goals = _localGoals ?? [];

                    if (goals.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Noch keine Ziele vorhanden',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey[400]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Füge dein erstes Ziel hinzu!',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: goals.length,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 0,
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: child,
                        );
                      },
                      onReorder: (int oldIndex, int newIndex) async {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }

                        setState(() {
                          _isReordering = true;
                          // Lokale Liste sofort aktualisieren
                          final item = goals.removeAt(oldIndex);
                          goals.insert(newIndex, item);
                        });

                        try {
                          List<String> reorderedGoalIds = goals
                              .map((g) => g.id)
                              .toList();
                          await DatabaseService(
                            uid: user.uid,
                          ).reorderGoals(reorderedGoalIds);
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
                          setState(() {
                            _isReordering = false;
                          });
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
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle,
                                color: Colors.white70,
                              ),
                            ),
                            title: Text(
                              _getGoalDisplayName(data),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _getGoalSubtitle(data),
                              style: TextStyle(color: Colors.white70),
                            ),
                            // Icons rechts für Edit/Delete
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white70),
                                  onPressed: () => _editGoal(goal.id, data),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteGoal(goal.id),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

  // Helper-Methode für zielnamen
  String _getGoalDisplayName(Map<String, dynamic> data) {
    final type = data['type'] ?? '';

    switch (type) {
      case 'Event':
        return 'Event';
      case 'Gewicht':
        return 'Gewichtsziel';
      case 'Training':
        return 'Trainingsziel';
      case 'Schritte':
        return 'Schrittziel';
      default:
        return 'Unbekanntes Ziel';
    }
  }

  String _getGoalSubtitle(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    switch (type) {
      case 'Event':
        final name = data['name'] ?? '';
        final eventDate = data['eventDate'];
        if (eventDate != null) {
          try {
            final date = DateTime.parse(eventDate);
            final daysLeft = date.difference(DateTime.now()).inDays;
            return name.isNotEmpty
                ? '$name (noch $daysLeft Tage)'
                : 'Noch $daysLeft Tage';
          } catch (e) {
            return name.isNotEmpty ? name : 'Event';
          }
        }
        return name.isNotEmpty ? name : 'Event';
      case 'Gewicht':
        return '${data['targetWeight']?.toInt() ?? 0}kg erreichen';
      case 'Training':
        return '${data['targetTrainings']?.toInt() ?? 0}x pro Woche trainieren';
      case 'Schritte':
        return '${_formatNumber(data['targetSteps']?.toInt() ?? 0)} Schritte täglich';
      default:
        return 'Unbekanntes Ziel';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}k';
    }
    return number.toString();
  }

  // Goal-Aktionen
  void _addGoal() {
    GoalDialogs.showAddGoalDialog(context, () {});
  }

  void _editGoal(String goalId, Map<String, dynamic> goalData) {
    GoalDialogs.showEditGoalDialog(context, goalId, goalData, () {});
  }

  void _deleteGoal(String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text('Ziel löschen', style: TextStyle(color: Colors.white)),
        content: Text(
          'Möchtest du dieses Ziel wirklich löschen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final user = Provider.of<StreaxUser?>(context, listen: false);
                if (user != null) {
                  await DatabaseService(uid: user.uid).deleteGoal(goalId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ziel erfolgreich gelöscht!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
