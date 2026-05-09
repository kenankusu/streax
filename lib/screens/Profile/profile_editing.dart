import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:streax/services/database.dart';
import 'package:streax/services/image_service.dart';
import 'package:streax/shared/utils/snackbar.dart';
import 'package:streax/shared/widgets/navigation_bar.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _bg      = Color(0xFF111214);
const _card    = Color(0xFF1A1D21);
const _border  = Color(0xFF252830);
const _blue    = Color(0xFF2A9FFF);
const _green   = Color(0xFF1CE9B0);
const _secLbl  = Color(0xFF3A7A9A);
const _fldLbl  = Color(0xFF3A5A6A);

class EditProfilePage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.uid, required this.userData});

  static Future<void> show(
    BuildContext context,
    String uid,
    Map<String, dynamic> userData,
  ) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditProfilePage(uid: uid, userData: userData),
    ));
  }

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  late String _gender;
  late String _birthdateDisplay;
  XFile? _newImage;
  bool _saving = false;

  static const _genderOptions = [
    {'value': 'm', 'label': 'Männlich'},
    {'value': 'w', 'label': 'Weiblich'},
    {'value': 'd', 'label': 'Keine Angabe'},
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    _firstNameCtrl = TextEditingController(text: d['firstName'] ?? '');
    _lastNameCtrl  = TextEditingController(text: d['lastName']  ?? '');
    _usernameCtrl  = TextEditingController(text: d['username']  ?? '');
    _weightCtrl    = TextEditingController(text: d['weight']?.toString() ?? '');
    _heightCtrl    = TextEditingController(text: d['height']?.toString() ?? '');
    _gender        = _mapGender(d['gender']);
    _birthdateDisplay = _formatBirthdate(d['birthdate']);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  String _mapGender(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'm': return 'm';
      case 'w': return 'w';
      default:  return 'd';
    }
  }

  String _formatBirthdate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newImage = picked);
  }

  void _showPicker(String type) {
    final ctrl = type == 'weight' ? _weightCtrl : _heightCtrl;
    final isWeight = type == 'weight';
    final current = int.tryParse(ctrl.text) ?? (isWeight ? 70 : 175);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D21),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 4, width: 40,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: Colors.transparent,
                itemExtent: 42,
                scrollController: FixedExtentScrollController(
                  initialItem: isWeight ? (current - 30).clamp(0, 170) : (current - 140).clamp(0, 80),
                ),
                onSelectedItemChanged: (i) => setState(() =>
                  ctrl.text = isWeight ? '${i + 30}' : '${i + 140}'),
                children: List.generate(
                  isWeight ? 171 : 81,
                  (i) => Center(
                    child: Text(
                      isWeight ? '${i + 30} kg' : '${i + 140} cm',
                      style: GoogleFonts.barlow(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fertig', style: GoogleFonts.barlow(color: _blue, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Vorname ist ein Pflichtfeld');
      return;
    }
    if (_usernameCtrl.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Username ist ein Pflichtfeld');
      return;
    }

    final username = _usernameCtrl.text.trim();
    if (username.length < 3) {
      SnackBarUtils.showError(context, 'Username muss mindestens 3 Zeichen haben');
      return;
    }
    if (username.contains(' ') || !RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      SnackBarUtils.showError(context, 'Username darf nur Buchstaben, Zahlen, Punkte und Unterstriche enthalten');
      return;
    }

    // Warning if body data is being removed
    final prevWeight = widget.userData['weight']?.toString() ?? '';
    final prevHeight = widget.userData['height']?.toString() ?? '';
    final hadBodyData = prevWeight.isNotEmpty || prevHeight.isNotEmpty;
    final nowEmpty = _weightCtrl.text.isEmpty && _heightCtrl.text.isEmpty;

    if (hadBodyData && nowEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: _border)),
          title: Text('Körperdaten entfernen?',
            style: GoogleFonts.barlowCondensed(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          content: Text(
            'Sicher, dass du deine Körperdaten entfernen möchtest? Dies könnte Einfluss auf deine Ziele haben.',
            style: GoogleFonts.barlow(color: const Color(0xFFAAB0BB), fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Abbrechen', style: GoogleFonts.barlow(color: const Color(0xFF666666), fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Ja, entfernen', style: GoogleFonts.barlow(color: Colors.redAccent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);

    try {
      final db = DatabaseService(uid: widget.uid);

      final isAvailable = await db.isUsernameAvailable(username, excludeUid: widget.uid);
      if (!isAvailable && mounted) {
        SnackBarUtils.showError(context, 'Dieser Username ist bereits vergeben');
        setState(() => _saving = false);
        return;
      }

      String? imageUrl;
      if (_newImage != null) {
        imageUrl = await ImageService().uploadProfileImage(widget.uid, _newImage!);
      }

      await db.updateUserData(
        _firstNameCtrl.text.trim(),
        _lastNameCtrl.text.trim(),
        username: username,
        weight: double.tryParse(_weightCtrl.text) ?? 0.0,
        height: double.tryParse(_heightCtrl.text) ?? 0.0,
        gender: _gender,
        birthdate: widget.userData['birthdate'],
        profilePicture: imageUrl,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Fehler beim Speichern: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (widget.userData['profileImageUrl'] ?? '').toString();
    final initials = '${(_firstNameCtrl.text.isNotEmpty ? _firstNameCtrl.text[0] : '?')}${(_lastNameCtrl.text.isNotEmpty ? _lastNameCtrl.text[0] : '')}';

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2024),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2A2D33)),
                          ),
                          child: const Icon(Icons.chevron_left, color: Color(0xFF888888), size: 22),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Profil bearbeiten',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.barlowCondensed(
                            color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w900, letterSpacing: .04 * 20,
                          ),
                        ),
                      ),
                      _saving
                          ? const SizedBox(width: 72, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _blue, strokeWidth: 2))))
                          : GestureDetector(
                              onTap: _save,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF1A2D8A), Color(0xFF00B4CC)]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Speichern',
                                  style: GoogleFonts.barlow(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .04 * 12)),
                              ),
                            ),
                    ],
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Avatar ──────────────────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Column(
                              children: [
                                Container(
                                  width: 90, height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [_blue, _green],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF1E2228),
                                        ),
                                        child: ClipOval(
                                          child: _newImage != null
                                              ? Image.file(File(_newImage!.path), fit: BoxFit.cover, width: 86, height: 86)
                                              : avatarUrl.isNotEmpty
                                                  ? Image.network(avatarUrl, fit: BoxFit.cover, width: 86, height: 86)
                                                  : SizedBox(
                                                      width: 86, height: 86,
                                                      child: Center(
                                                        child: Text(initials.toUpperCase(),
                                                          style: GoogleFonts.barlowCondensed(
                                                            color: _blue, fontSize: 28, fontWeight: FontWeight.w900)),
                                                      ),
                                                    ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0, right: 0,
                                        child: Container(
                                          width: 26, height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(colors: [_blue, _green]),
                                            border: Border.all(color: _bg, width: 2),
                                          ),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Foto ändern',
                                  style: GoogleFonts.barlow(color: _fldLbl, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),

                        // ── Identität ───────────────────────────────────────
                        _sectionLabel('Identität'),
                        Row(
                          children: [
                            Expanded(child: _field('Vorname *', _firstNameCtrl)),
                            const SizedBox(width: 8),
                            Expanded(child: _field('Nachname', _lastNameCtrl)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _field('Username *', _usernameCtrl),

                        // ── Körperdaten ─────────────────────────────────────
                        _sectionLabel('Körperdaten'),
                        Row(
                          children: [
                            Expanded(child: _pickerField('Gewicht (kg)', _weightCtrl, 'weight')),
                            const SizedBox(width: 8),
                            Expanded(child: _pickerField('Größe (cm)', _heightCtrl, 'height')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _readOnlyField('Geburtsdatum', _birthdateDisplay)),
                            const SizedBox(width: 8),
                            Expanded(child: _genderDropdown()),
                          ],
                        ),

                        // ── Save button ─────────────────────────────────────
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: _saving ? null : _save,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A2D8A), Color(0xFF00B4CC)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _saving ? 'Wird gespeichert…' : 'Änderungen speichern',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.barlowCondensed(
                                color: Colors.white, fontSize: 17,
                                fontWeight: FontWeight.w900, letterSpacing: .08 * 17,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Nav bar ────────────────────────────────────────────────────────
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: NavigationsLeiste(currentPage: 4),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(text.toUpperCase(),
      style: GoogleFonts.barlow(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 1.0, color: _secLbl,
      )),
  );

  Widget _field(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .08 * 10, color: _fldLbl)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        style: GoogleFonts.barlow(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          filled: true, fillColor: _card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
        ),
      ),
    ],
  );

  Widget _pickerField(String label, TextEditingController ctrl, String type) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .08 * 10, color: _fldLbl)),
      const SizedBox(height: 5),
      GestureDetector(
        onTap: () => _showPicker(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ctrl.text.isNotEmpty ? ctrl.text : '—',
                  style: GoogleFonts.barlow(color: ctrl.text.isNotEmpty ? Colors.white : const Color(0xFF444444), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.unfold_more, color: Color(0xFF3A4050), size: 18),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _readOnlyField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .08 * 10, color: _fldLbl)),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF14161A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2025)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value,
                style: GoogleFonts.barlow(color: const Color(0xFF555555), fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.lock_outline, color: Color(0xFF333333), size: 14),
          ],
        ),
      ),
    ],
  );

  Widget _genderDropdown() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Geschlecht'.toUpperCase(),
        style: GoogleFonts.barlow(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .08 * 10, color: _fldLbl)),
      const SizedBox(height: 5),
      DropdownButtonFormField<String>(
        value: _gender,
        dropdownColor: _card,
        style: GoogleFonts.barlow(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3A4050), size: 18),
        decoration: InputDecoration(
          filled: true, fillColor: _card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
        ),
        items: _genderOptions.map((o) => DropdownMenuItem(
          value: o['value'],
          child: Text(o['label']!),
        )).toList(),
        onChanged: (v) => setState(() => _gender = v!),
      ),
    ],
  );
}

// Keep old name as alias so existing call sites don't break
class EditProfileDialog {
  static Future<void> show(
    BuildContext context,
    String uid,
    Map<String, dynamic> userData,
  ) => EditProfilePage.show(context, uid, userData);
}
