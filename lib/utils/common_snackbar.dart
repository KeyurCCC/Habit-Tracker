import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, info }

OverlayEntry? _currentEntry;

void commonSnackBar(
  BuildContext context, {
  required String message,
  required SnackbarType type,
  Duration duration = const Duration(seconds: 3),
}) {
  final Color backgroundColor;
  final IconData icon;

  switch (type) {
    case SnackbarType.success:
      backgroundColor = Colors.green;
      icon = Icons.check_circle_outline;
      break;
    case SnackbarType.error:
      backgroundColor = Colors.red;
      icon = Icons.error_outline;
      break;
    case SnackbarType.info:
      backgroundColor = Colors.blue;
      icon = Icons.info_outline;
      break;
  }
  _currentEntry?.remove(); // Remove any existing overlay entry
  _currentEntry = null;

  // Web/desktop: top-right custom toast
  final overlay = Overlay.of(context);

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 40,
      right: 20,
      child: _WebToast(message: message, backgroundColor: backgroundColor, icon: icon),
    ),
  );

  _currentEntry = overlayEntry;
  overlay.insert(overlayEntry);

  Future.delayed(duration, () {
    overlayEntry.remove();
    if (_currentEntry == overlayEntry) {
      _currentEntry = null;
    }
  });
}

class _WebToast extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;

  const _WebToast({super.key, required this.message, required this.backgroundColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(8),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
