import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/deen_colors.dart';

/// Renders a user's avatar: the chosen [AvatarOption] silhouette, or the
/// existing initial-letter circle when nothing's been picked yet (`null`
/// stays the default for every account created before this feature).
class AvatarGraphic extends StatelessWidget {
  final AvatarOption? avatar;
  final String initial;
  final double radius;

  const AvatarGraphic({super.key, required this.avatar, required this.initial, this.radius = 23});

  @override
  Widget build(BuildContext context) {
    if (avatar == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: DeenColors.primary,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.74,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: DeenColors.primary,
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: CustomPaint(painter: _AvatarPainter(avatar!)),
      ),
    );
  }
}

/// Both options share the same head + shoulders build so they read as a
/// matched pair; only the head treatment differs. Coordinates are fractions
/// of the painter's own size, so this scales cleanly at any [AvatarGraphic]
/// radius.
class _AvatarPainter extends CustomPainter {
  final AvatarOption avatar;

  _AvatarPainter(this.avatar);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Shoulders: a rounded shape anchored past the bottom edge so it reads
    // as a torso cut off by the frame, matching a standard avatar glyph.
    final shoulders = Path()
      ..moveTo(w * 0.5, h * 0.56)
      ..cubicTo(w * 0.18, h * 0.56, w * 0.08, h * 0.78, w * 0.08, h * 1.05)
      ..lineTo(w * 0.92, h * 1.05)
      ..cubicTo(w * 0.92, h * 0.78, w * 0.82, h * 0.56, w * 0.5, h * 0.56)
      ..close();
    canvas.drawPath(shoulders, fill);

    if (avatar == AvatarOption.male) {
      canvas.drawCircle(Offset(w * 0.5, h * 0.36), w * 0.19, fill);
      return;
    }

    // femaleHijab: a wider draped-hood shape instead of a plain circle —
    // covers hair/neck and extends past where a plain head would end, with
    // a smaller face oval inset at the front.
    final hijab = Path()
      ..moveTo(w * 0.5, h * 0.14)
      ..cubicTo(w * 0.27, h * 0.14, w * 0.16, h * 0.34, w * 0.18, h * 0.54)
      ..cubicTo(w * 0.19, h * 0.60, w * 0.23, h * 0.60, w * 0.25, h * 0.54)
      ..cubicTo(w * 0.24, h * 0.32, w * 0.34, h * 0.20, w * 0.5, h * 0.20)
      ..cubicTo(w * 0.66, h * 0.20, w * 0.76, h * 0.32, w * 0.75, h * 0.54)
      ..cubicTo(w * 0.77, h * 0.60, w * 0.81, h * 0.60, w * 0.82, h * 0.54)
      ..cubicTo(w * 0.84, h * 0.34, w * 0.73, h * 0.14, w * 0.5, h * 0.14)
      ..close();
    canvas.drawPath(hijab, fill);

    final face = Paint()
      ..color = DeenColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.38), width: w * 0.28, height: h * 0.30),
      face,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) => oldDelegate.avatar != avatar;
}
