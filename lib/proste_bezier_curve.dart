library o_bezier;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:o_bezier/utils/type/index.dart';

export 'package:o_bezier/utils/type/index.dart';

// by brian opicho

/// Defines where the Bézier curve will be clipped relative to the widget.
///
/// Flutter's coordinate system:
/// - The origin **(0,0)** is always the **top‑left corner** of the widget.
/// - `dx` increases → to the **right**.
/// - `dy` increases ↓ to the **bottom**.
///
/// When using [ClipPosition]:
/// - **left** → curve runs vertically along the **left edge**. The curve starts from
///   the first point in your curve definition and the remaining area forms a rectangle.
/// - **bottom** → curve runs horizontally along the **bottom edge**. The curve follows
///   your defined points along the bottom boundary.
/// - **right** → curve runs vertically along the **right edge**. The curve follows
///   your defined points along the right boundary.
/// - **top** → curve runs horizontally along the **top edge**. The curve follows
///   your defined points along the top boundary.
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
  /// The path starts at (0,0), goes to the first curve point, follows the curve
  /// vertically downward, then completes a rectangle back to the starting point.
  left,

  /// Curve will be drawn along the **bottom edge** of the widget.
  ///
  /// The path forms three sides of a rectangle, then follows your curve definition
  /// along the bottom edge to create the clipped shape.
  bottom,

  /// Curve will be drawn along the **right edge** of the widget.
  ///
  /// The path forms three sides of a rectangle, then follows your curve definition
  /// along the right edge to create the clipped shape.
  right,

  /// Curve will be drawn along the **top edge** of the widget.
  ///
  /// The path forms three sides of a rectangle, then follows your curve definition
  /// along the top edge to create the clipped shape.
  top,
}

/// A [CustomClipper] that creates a path with **quadratic Bézier curves**.
///
/// This clipper takes a list of [BezierCurveSection] objects and creates smooth
/// curved edges on the specified side of a widget. Each section defines a
/// quadratic Bézier curve using start, control (top), and end points.
///
/// The curve calculations use a proportion value to determine the curve's shape,
/// with the formula for quadratic Bézier curves applied to compute the actual
/// control points needed for the path.
///
/// Example:
/// ```dart
/// ClipPath(
///   clipper: ProsteBezierCurve(
///     list: [
///       BezierCurveSection(
///         start: Offset(0, 50),
///         top: Offset(100, 0),      // Control point
///         end: Offset(200, 50),
///         proportion: 0.5,          // Default proportion for curve calculation
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
  /// Each section represents one quadratic Bézier curve segment.
  List<BezierCurveSection> list;

  /// Defines which side of the widget will have the curved edge.
  ClipPosition position;

  ProsteBezierCurve({
    required this.list,
    this.reclip = true,
    this.position = ClipPosition.left,
  }) : assert(list.isNotEmpty);

  /// Calculates the actual quadratic Bézier control points from a [BezierCurveSection].
  ///
  /// This method takes the user-defined start, top (control hint), and end points,
  /// along with a proportion value, and computes the actual control points needed
  /// for the quadratic Bézier curve using the standard mathematical formula.
  ///
  /// The [param.top] point is treated as a "hint" for where the curve should bend,
  /// and the [param.proportion] determines how much influence this hint has on the
  /// final curve shape.
  ///
  /// Returns [BezierCurveDots] containing the calculated control point (x1, y1) and
  /// end point (x2, y2) for use with [Path.quadraticBezierTo].
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

  /// Iterates through the list of curve sections and adds them to the [Path].
  ///
  /// For each [BezierCurveSection] in the list, this method:
  /// 1. Calculates the actual control points using [calcCurveDots]
  /// 2. Adds a quadratic Bézier curve to the path using [Path.quadraticBezierTo]
  void _eachPath(List<BezierCurveSection> list, Path path) {
    for (var element in list) {
      BezierCurveDots item = calcCurveDots(element);
      path.quadraticBezierTo(item.x1, item.y1, item.x2, item.y2);
    }
  }

  /// Builds the clipping path based on the specified [position].
  ///
  /// This method creates a closed path that:
  /// 1. Forms three sides of a rectangle around the widget
  /// 2. Replaces one side with the custom Bézier curve(s)
  /// 3. Ensures the path stays within widget boundaries using min/max functions
  ///
  /// The path creation order varies by position to ensure proper curve placement
  /// and correct path closure for clipping.
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
/// This clipper provides smoother, more complex curves compared to quadratic curves
/// by using cubic Bézier curves with four control points per section. The curves
/// are calculated using a smoothing algorithm that creates natural-looking transitions
/// between control points.
///
/// Each [ThirdOrderBezierCurveSection] defines four points (p1, p2, p3, p4) and a
/// smoothing factor that controls how the curve interpolates between these points.
///
/// Example:
/// ```dart
/// ClipPath(
///   clipper: ProsteThirdOrderBezierCurve(
///     list: [
///       ThirdOrderBezierCurveSection(
///         p1: Offset(0, 50),      // Start point
///         p2: Offset(50, 0),      // First control point
///         p3: Offset(150, 100),   // Second control point
///         p4: Offset(200, 50),    // End point
///         smooth: 0.5,            // Smoothing factor (0.0 to 1.0)
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
  /// Each section represents one cubic Bézier curve segment with four control points.
  List<ThirdOrderBezierCurveSection> list;

  /// Defines which side of the widget will have the curved edge.
  ClipPosition position;

  ProsteThirdOrderBezierCurve({
    required this.list,
    this.position = ClipPosition.left,
    this.reclip = true,
  }) : assert(list.isNotEmpty);

  /// Calculates the cubic Bézier control points using a smoothing algorithm.
  ///
  /// This method takes four control points (p1, p2, p3, p4) and a smoothing factor,
  /// then applies a sophisticated algorithm to create smooth cubic Bézier curves.
  /// The algorithm:
  /// 1. Calculates midpoints between consecutive control points
  /// 2. Computes distances between points for weighted interpolation
  /// 3. Creates intermediate control points using proportional weighting
  /// 4. Applies the smoothing factor to adjust curve tension
  ///
  /// Returns [ThirdOrderBezierCurveDots] containing the calculated control points
  /// (x1, y1), (x2, y2) and end point (x3, y3) for use with [Path.cubicTo].
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

  /// Iterates through the list of curve sections and adds them to the [Path].
  ///
  /// For each [ThirdOrderBezierCurveSection] in the list, this method:
  /// 1. Calculates the actual control points using [calcCurveDots]
  /// 2. Adds a cubic Bézier curve to the path using [Path.cubicTo]
  void _eachPath(List<ThirdOrderBezierCurveSection> list, Path path) {
    for (var element in list) {
      ThirdOrderBezierCurveDots item = calcCurveDots(element);
      path.cubicTo(item.x1, item.y1, item.x2, item.y2, item.x3, item.y3);
    }
  }

  /// Builds the clipping path based on the specified [position].
  ///
  /// This method creates a closed path that:
  /// 1. Forms three sides of a rectangle around the widget
  /// 2. Replaces one side with the custom cubic Bézier curve(s)
  /// 3. Ensures the path stays within widget boundaries using min/max functions
  ///
  /// The path creation order varies by position to ensure proper curve placement
  /// and correct path closure for clipping. Uses the same logic as the quadratic
  /// version but applies cubic curves instead.
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