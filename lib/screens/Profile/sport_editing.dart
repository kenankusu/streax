import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streax/services/database.dart';
import 'package:streax/shared/constants/theme_constants.dart';
import 'package:streax/shared/constants/sport_utils.dart';
import '../../shared/utils/snackbar.dart';

// ─── Public API (unchanged — existing callers work as before) ─────────────────

class SportSelectionDialog {
  static List<String> get availableSports => kAllSports;

  static void show(
    BuildContext context,
    String uid,
    Map<String, dynamic> currentData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SportPickerSheet(uid: uid, currentData: currentData),
    );
  }
}

// ─── Bottom Sheet ─────────────────────────────────────────────────────────────

class _SportPickerSheet extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> currentData;
  const _SportPickerSheet({required this.uid, required this.currentData});

  @override
  State<_SportPickerSheet> createState() => _SportPickerSheetState();
}

class _SportPickerSheetState extends State<_SportPickerSheet> {
  late List<String> _selected;
  String _query = '';
  final _searchCtrl = TextEditingController();
  bool _saving = false;

  // All sports sorted A–Z
  static final _allSorted = (List<String>.from(kAllSports)..sort());

  List<String> get _filtered {
    if (_query.isEmpty) return _allSorted;
    final q = _query.toLowerCase();
    return _allSorted.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.currentData['sports'] ?? []);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await DatabaseService(uid: widget.uid).updateUserSports(_selected);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Fehler beim Speichern: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(String sport) {
    setState(() {
      if (_selected.contains(sport)) {
        _selected.remove(sport);
      } else {
        _selected.add(sport);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            _header(),
            _searchBar(),
            if (_selected.isNotEmpty) _selectedStrip(),
            Flexible(child: _list()),
            _actions(),
          ],
        ),
      ),
    );
  }

  // ─── Handle ────────────────────────────────────────────────────────────────

  Widget _handle() => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D33),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Row(
        children: [
          const Text(
            'SPORTARTEN',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0B2233),
              border: Border.all(color: const Color(0xFF1A4A6A)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selected.length} gewählt',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Icon(Icons.search, size: 16, color: Color(0xFF3A4050)),
            ),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Sportart suchen…',
                  hintStyle: TextStyle(color: Color(0xFF3A4050)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(8, 9, 14, 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Selected chips strip ──────────────────────────────────────────────────

  Widget _selectedStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _selected.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final sport = _selected[i];
              return GestureDetector(
                onTap: () => _toggle(sport),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2233),
                    border: Border.all(color: kBlue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sportEmoji(sport), style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        sport,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '✕',
                        style: TextStyle(fontSize: 9, color: kBlue),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Sport list ────────────────────────────────────────────────────────────

  Widget _list() {
    final sports = _filtered;
    final showHeaders = _query.isEmpty;

    // Build flat item list: _Letter (header) or String (sport)
    final items = <Object>[];
    String lastLetter = '';
    for (final sport in sports) {
      final letter = sport[0].toUpperCase();
      if (showHeaders && letter != lastLetter) {
        items.add(_Letter(letter));
        lastLetter = letter;
      }
      items.add(sport);
    }

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Keine Sportart gefunden',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF3A4050), fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is _Letter) return _alphaLabel(item.letter);
        final sport = item as String;
        final isOn = _selected.contains(sport);
        return _sportRow(sport, isOn);
      },
    );
  }

  Widget _alphaLabel(String letter) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Color(0xFF3A4050),
        ),
      ),
    );
  }

  Widget _sportRow(String sport, bool isOn) {
    return GestureDetector(
      onTap: () => _toggle(sport),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1A1D21))),
        ),
        child: Row(
          children: [
            // Emoji box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isOn ? const Color(0xFF0B2233) : const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(sportEmoji(sport), style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                sport,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOn ? Colors.white : const Color(0xFF888888),
                ),
              ),
            ),
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: isOn
                    ? const LinearGradient(
                        colors: [Color(0xFF1A2D8A), Color(0xFF00B4CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isOn ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isOn ? null : Border.all(color: const Color(0xFF252830), width: 1.5),
              ),
              child: isOn
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Abbrechen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2D8A), Color(0xFF00B4CC)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _saving ? '…' : 'SPEICHERN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal helper ──────────────────────────────────────────────────────────

class _Letter {
  final String letter;
  const _Letter(this.letter);
}

// ─── SportIcons widget (used on profile page) ─────────────────────────────────

class SportIcons extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String uid;

  const SportIcons({super.key, required this.userData, required this.uid});

  @override
  Widget build(BuildContext context) {
    final sports = (userData['sports'] as List<dynamic>?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deine Sportarten:',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 16),
              ...sports.map((sport) => SportIcon(sportName: sport)),
              GestureDetector(
                onTap: () => SportSelectionDialog.show(context, uid, userData),
                child: const AddSportIcon(),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Individual sport icon ────────────────────────────────────────────────────

class SportIcon extends StatelessWidget {
  final String sportName;
  const SportIcon({super.key, required this.sportName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onLongPress: () => _showRemoveDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sportEmoji(sportName), style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(
                sportName.length > 8 ? '${sportName.substring(0, 7)}.' : sportName,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sportart entfernen', style: TextStyle(color: Colors.white)),
        content: Text(
          'Möchtest du "$sportName" entfernen?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final doc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
              final sports =
                  ((doc.data()?['sports'] as List<dynamic>?)?.cast<String>() ?? [])
                    ..remove(sportName);
              await DatabaseService(uid: user.uid).updateUserSports(sports);
            },
            child: const Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Add sport button ─────────────────────────────────────────────────────────

class AddSportIcon extends StatelessWidget {
  const AddSportIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2),
            ),
            child: Center(
              child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface, size: 30),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sportarten',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
