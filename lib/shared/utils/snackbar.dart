import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, Icons.check_circle_outline_rounded,
            const Color(0xFF1CE9B0), const Duration(seconds: 3));

  static void showError(BuildContext context, String message) =>
      _show(context, message, Icons.error_outline_rounded,
            const Color(0xFFFF4455), const Duration(seconds: 4));

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, Icons.warning_amber_rounded,
            const Color(0xFFF0A020), const Duration(seconds: 3));

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, Icons.info_outline_rounded,
            const Color(0xFF2A9FFF), const Duration(seconds: 3));

  static void _show(BuildContext context, String message, IconData icon,
      Color accent, Duration duration) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_build(message, icon, accent, duration));
  }

  static SnackBar _build(
      String message, IconData icon, Color accent, Duration duration) {
    return SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1A1D21),
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.barlow(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
