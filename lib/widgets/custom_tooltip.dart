import 'dart:async';
import 'package:flutter/material.dart';

class CustomTooltip extends StatefulWidget {
  final String message;
  final Duration duration;

  const CustomTooltip({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  final GlobalKey _iconKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _timer;

  void _showTooltip() {
    _removeTooltip();

    final renderBox = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx + size.width / 2 - 100,
          top: offset.dy - 50,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    _timer = Timer(widget.duration, _removeTooltip);
  }

  void _removeTooltip() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _iconKey,
      onTap: _showTooltip,
      behavior: HitTestBehavior.translucent,
      child: const Icon(Icons.info_outline, size: 18),
    );
  }
}
