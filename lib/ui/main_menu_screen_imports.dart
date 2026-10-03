/// Logo painter and helpers shared with the main menu.
library;

import 'package:flutter/material.dart';

/// Vector-drawn logo: a winding board path forming the digits "62"
/// plus a pawn on a tile. Hand-authored, few paths, scales cleanly
/// from 48px to 512px. See assets/brand/ for the canonical SVG.
class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 108.0; // scale factor from the 108 viewBox

    // Background square.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(14 * s),
      ),
      Paint()..color = const Color(0xFFB31919),
    );

    final white = Paint()..color = const Color(0xFFFFF8E7);
    final gold = Paint()..color = const Color(0xFFD4A23A);
    final tealShadow = Paint()
      ..color = const Color(0xFF0E5A4F)
      ..style = PaintingStyle.fill;

    // "6"
    final six = Path();
    six.moveTo(40 * s, 32 * s);
    six.arcToPoint(
      Offset(40 * s, 60 * s),
      radius: Radius.circular(14 * s),
      clockwise: false,
      largeArc: true,
    );
    six.arcToPoint(
      Offset(54 * s, 46 * s),
      radius: Radius.circular(14 * s),
      clockwise: false,
      largeArc: false,
    );
    six.lineTo(46 * s, 46 * s);
    six.arcToPoint(
      Offset(40 * s, 52 * s),
      radius: Radius.circular(6 * s),
      clockwise: true,
      largeArc: false,
    );
    six.lineTo(40 * s, 32 * s);
    six.close();
    canvas.drawPath(six, white);

    // "2" — simplified as three rectangles for the digit's body.
    final two = Path();
    // Top arc.
    two.moveTo(56 * s, 60 * s);
    two.arcToPoint(
      Offset(72 * s, 60 * s),
      radius: Radius.circular(8 * s),
      clockwise: true,
      largeArc: false,
    );
    two.lineTo(72 * s, 64 * s);
    two.lineTo(56 * s, 64 * s);
    two.lineTo(56 * s, 70 * s);
    two.lineTo(72 * s, 70 * s);
    two.lineTo(72 * s, 76 * s);
    two.lineTo(56 * s, 76 * s);
    two.lineTo(56 * s, 70 * s);
    two.lineTo(64 * s, 62 * s);
    two.lineTo(64 * s, 60 * s);
    // Close back to 56,60
    two.close();
    canvas.drawPath(two, white);

    // Pawn.
    canvas.drawCircle(
      Offset(22 * s, 86 * s),
      6 * s,
      gold,
    );
    canvas.drawRect(
      Rect.fromLTWH(16 * s, 92 * s, 12 * s, 4 * s),
      gold,
    );
    canvas.drawRect(
      Rect.fromLTWH(14 * s, 96 * s, 16 * s, 4 * s),
      gold,
    );

    // Subtle teal shadow under the "62".
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(56 * s, 58 * s),
        width: 44 * s,
        height: 4 * s,
      ),
      Paint()
        ..color = const Color(0xFF0E5A4F)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
