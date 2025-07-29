library o_bezier;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:o_bezier/utils/type/index.dart';

export 'package:o_bezier/utils/type/index.dart';

// by brian opicho

/// Defines where the Bézier curve will be clipped relative to the widget.
///
/// Flutter’s coordinate system:
/// - The origin **(0,0)** is always the **top‑left corner** of the widget.
/// - `dx` increases → to the **right**.
/// - `dy` increases ↓ to the **bottom**.
///
/// When using [ClipPosition]:
/// - **left** → curve runs vertically along the **left edge**, starting at `(0,0)`.
/// - **bottom** → curve runs horizontally along the **bottom edge**, with `(0,0)` still top‑left, but the curve path is drawn near `dy = size.height`.
/// - **right** → curve runs vertically along the **right edge**, starting from `(size.width, 0)`.
/// - **top** → curve runs horizontally along the **top edge**, starting at `(0,0)` and moving right.
///
/// Example:
/// ```dart
/// ClipPath(
///   clipper: ProsteBezierCurve(
///     list: [
///       BezierCurveSection(
///         start: Offset(0, 30),
///         top: Offset(50, 10),
///         end: Offset(100, 30),
///       ),
///     ],
///     position: ClipPosition.bottom,
///   ),
///   child: Container(color: Colors.blue, height: 200),
/// )
/// ```
enum ClipPosition {
  /// Curve will be drawn along the **left edge** of the widget.
  ///
  /// `(0,0)` is the **top‑left** corner.
  /// Curve progresses **downward** along the left border.
  left,

  /// Curve will be drawn along the **bottom edge** of the widget.
  ///
  /// `(0,0)` is still **top‑left**, but the curve will be positioned near
  /// `dy = size.height` (bottom boundary).
  bottom,

  /// Curve will be drawn along the **right edge** of the widget.
  ///
  /// `(0,0)` is still top‑left, but the path starts drawing
  /// from `(size.width, 0)` downward along the right boundary.
  right,

  /// Curve will be drawn along the **top edge** of the widget.
  ///
  /// `(0,0)` is the top‑left corner.
  /// Curve progresses **horizontally** toward the right along the top boundary.
  top,
}

/// A [CustomClipper] that creates a path with **quadratic Bézier curves**.
///
/// This is typically used to create smooth, curved edges for containers.
///
/// Example:
/// ```dart
/// ClipPath(
///   clipper: ProsteBezierCurve(
///     list: [
///       BezierCurveSection(
///         start: Offset(0, 50),
///         top: Offset(100, 0),
///         end: Offset(200, 50),
///       ),
///     ],
///     position: ClipPosition.top,
///   ),
///   child: Container(
///     height: 200,
///     color: Colors.purple,
///   ),
/// )
/// ```
class ProsteBezierCurve extends CustomClipper<Path> {
  /// Whether the clip should redraw if [CustomClipper.shouldReclip] is called.
  bool reclip;

  /// A list of curve definitions that describe the Bézier sections to draw.
  List<BezierCurveSection> list;

  /// Defines which side of the widget will have the curved edge.
  ClipPosition position;

  ProsteBezierCurve({
    required this.list,
    this.reclip = true,
    this.position = ClipPosition.left,
  }) : assert(list.isNotEmpty);

  /// Calculates the quadratic Bézier control points based on a [BezierCurveSection].
  ///
  /// This uses the standard quadratic Bézier formula to compute the
  /// control points needed for drawing the curve.
  static BezierCurveDots calcCurveDots(BezierCurveSection param) {
    double x = (param.top.dx -
            (param.start.dx * pow((1 - param.proportion), 2) +
                pow(param.proportion, 2) * param.end.dx)) /
        (2 * param.proportion * (1 - param.proportion));
    double y = (param.top.dy -
            (param.start.dy * pow((1 - param.proportion), 2) +
                pow(param.proportion, 2) * param.end.dy)) /
        (2 * param.proportion * (1 - param.proportion));

    return BezierCurveDots(x, y, param.end.dx, param.end.dy);
  }

  /// Iterates through the list of sections and adds them to the [Path].
  void _eachPath(List<BezierCurveSection> list, Path path) {
    for (var element in list) {
      BezierCurveDots item = calcCurveDots(element);
      path.quadraticBezierTo(item.x1, item.y1, item.x2, item.y2);
    }
  }

  /// Builds the clipping path depending on the [position].
  @override
  Path getClip(Size size) {
    Path path = Path();
    double firstStartX = list[0].start.dx;
    double firstStartY = list[0].start.dy;

    if (position == ClipPosition.left) {
      path.lineTo(max(0, firstStartX), 0);
      _eachPath(list, path);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(max(0, firstStartX), 0);
    } else {
      path.lineTo(0, 0);
      path.lineTo(
        0,
        position == ClipPosition.bottom
            ? min(size.height, firstStartY)
            : size.height,
      );
    }

    if (position == ClipPosition.bottom) {
      _eachPath(list, path);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.lineTo(
        position == ClipPosition.right
            ? min(size.width, firstStartX)
            : size.width,
        size.height,
      );
    }

    if (position == ClipPosition.right) {
      _eachPath(list, path);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.lineTo(
          size.width, position == ClipPosition.top ? max(0, firstStartY) : 0);
    }

    if (position == ClipPosition.top) {
      _eachPath(list, path);
      path.lineTo(0, 0);
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => reclip;
}

/// A [CustomClipper] that creates a path with **cubic (third-order) Bézier curves**.
///
/// This allows for smoother, more complex curves compared to quadratic curves.
///
/// Example:
/// ```dart
/// ClipPath(
///   clipper: ProsteThirdOrderBezierCurve(
///     list: [
///       ThirdOrderBezierCurveSection(
///         p1: Offset(0, 50),
///         p2: Offset(50, 0),
///         p3: Offset(150, 100),
///         p4: Offset(200, 50),
///         smooth: 0.5,
///       ),
///     ],
///     position: ClipPosition.bottom,
///   ),
///   child: Container(
///     height: 200,
///     color: Colors.orange,
///   ),
/// )
/// ```
class ProsteThirdOrderBezierCurve extends CustomClipper<Path> {
  /// Whether the clip should redraw if [CustomClipper.shouldReclip] is called.
  bool reclip;

  /// A list of third-order curve definitions that describe the cubic Bézier sections to draw.
  List<ThirdOrderBezierCurveSection> list;

  /// Defines which side of the widget will have the curved edge.
  ClipPosition position;

  ProsteThirdOrderBezierCurve({
    required this.list,
    this.position = ClipPosition.left,
    this.reclip = true,
  }) : assert(list.isNotEmpty);

  /// Calculates the cubic Bézier control points based on a [ThirdOrderBezierCurveSection].
  static ThirdOrderBezierCurveDots calcCurveDots(
      ThirdOrderBezierCurveSection param) {
    double x0 = param.p1.dx,
        y0 = param.p1.dy,
        x1 = param.p2.dx,
        y1 = param.p2.dy,
        x2 = param.p3.dx,
        y2 = param.p3.dy,
        x3 = param.p4.dx,
        y3 = param.p4.dy;

    double xc1 = (x0 + x1) / 2.0;
    double yc1 = (y0 + y1) / 2.0;
    double xc2 = (x1 + x2) / 2.0;
    double yc2 = (y1 + y2) / 2.0;
    double xc3 = (x2 + x3) / 2.0;
    double yc3 = (y2 + y3) / 2.0;

    double len1 = sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
    double len2 = sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    double len3 = sqrt((x3 - x2) * (x3 - x2) + (y3 - y2) * (y3 - y2));

    double k1 = len1 / (len1 + len2);
    double k2 = len2 / (len2 + len3);

    double xm1 = xc1 + (xc2 - xc1) * k1;
    double ym1 = yc1 + (yc2 - yc1) * k1;
    double xm2 = xc2 + (xc3 - xc2) * k2;
    double ym2 = yc2 + (yc3 - yc2) * k2;

    double resultX1 = xm1 + (xc2 - xm1) * param.smooth + x1 - xm1;
    double resultY1 = ym1 + (yc2 - ym1) * param.smooth + y1 - ym1;
    double resultX2 = xm2 + (xc2 - xm2) * param.smooth + x2 - xm2;
    double resultY2 = ym2 + (yc2 - ym2) * param.smooth + y2 - ym2;

    return ThirdOrderBezierCurveDots(
        resultX1, resultY1, resultX2, resultY2, param.p4.dx, param.p4.dy);
  }

  /// Iterates through the list of sections and adds them to the [Path].
  void _eachPath(List<ThirdOrderBezierCurveSection> list, Path path) {
    for (var element in list) {
      ThirdOrderBezierCurveDots item = calcCurveDots(element);
      path.cubicTo(item.x1, item.y1, item.x2, item.y2, item.x3, item.y3);
    }
  }

  /// Builds the clipping path depending on the [position].
  @override
  Path getClip(Size size) {
    Path path = Path();

    double firstStartX = list[0].p1.dx;
    double firstStartY = list[0].p1.dy;

    if (position == ClipPosition.left) {
      path.lineTo(max(0, firstStartX), 0);
      _eachPath(list, path);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(max(0, firstStartX), 0);
    } else {
      path.lineTo(0, 0);
      path.lineTo(
        0,
        position == ClipPosition.bottom
            ? min(size.height, firstStartY)
            : size.height,
      );
    }

    if (position == ClipPosition.bottom) {
      _eachPath(list, path);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.lineTo(
        position == ClipPosition.right
            ? min(size.width, firstStartX)
            : size.width,
        size.height,
      );
    }

    if (position == ClipPosition.right) {
      _eachPath(list, path);
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    } else {
      path.lineTo(
          size.width, position == ClipPosition.top ? max(0, firstStartY) : 0);
    }

    if (position == ClipPosition.top) {
      _eachPath(list, path);
      path.lineTo(0, 0);
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => reclip;
}
