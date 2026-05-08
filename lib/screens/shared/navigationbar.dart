import 'package:flutter/material.dart';
import 'addActivity.dart';
import '../Journal/calendar.dart';
import '../Profile/profile.dart';
import '../Friends/feed.dart';

class NavigationsLeiste extends StatelessWidget {
  final int currentPage;
  const NavigationsLeiste({super.key, this.currentPage = 0});

  static const _active   = Colors.white;
  static const _inactive = Color(0xFF383C45);
  static const _blue     = Color(0xFF2A9FFF);
  static const _green    = Color(0xFF1CE9B0);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Nav bar
        Container(
          height: 65,
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF252830)),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
                selectedItemColor: _active,
                unselectedItemColor: _inactive,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                type: BottomNavigationBarType.fixed,
                currentIndex: currentPage,
                iconSize: 26,
                elevation: 0,
                onTap: (i) => _navigate(context, i),
                items: const [
                  BottomNavigationBarItem(
                    icon:       Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon:       Icon(Icons.group_outlined),
                    activeIcon: Icon(Icons.group),
                    label: 'Freunde',
                  ),
                  BottomNavigationBarItem(
                    icon: SizedBox(height: 26),
                    label: 'Hinzufügen',
                  ),
                  BottomNavigationBarItem(
                    icon:       Icon(Icons.calendar_month_outlined),
                    activeIcon: Icon(Icons.calendar_month),
                    label: 'Kalender',
                  ),
                  BottomNavigationBarItem(
                    icon:       Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),

          // FAB
          Positioned(
            bottom: 22,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _showAddActivity(context),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_blue, _green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == currentPage) return;
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 1:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Feed()));
      case 2:
        _showAddActivity(context);
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const calendar()));
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Profil()));
    }
  }

  void _showAddActivity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AktivitaetHinzufuegen(onSaved: () {}),
    );
  }
}
