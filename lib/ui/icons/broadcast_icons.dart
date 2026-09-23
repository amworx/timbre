import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Engraved line icons for the Broadcast faceplate.
///
/// Each icon is the same 24×24 hand-drawn path set used in the approved
/// prototype, painted with 1.6px round strokes. A tiny SVG-path parser
/// (M/L/H/V/C/S/A/Z, absolute and relative, with implicit repetition)
/// converts the path data once at first use and caches the result.
class BIcons {
  BIcons._();

  static const double size = 24;
  static const double stroke = 1.6;

  static const play = 'M8 5.5v13l10-6.5z';
  static const pause = 'M9 5.5v13M15 5.5v13';
  static const next = 'M6 5.5v13l8-6.5zM18 5.5v13';
  static const prev = 'M18 5.5v13l-8-6.5zM6 5.5v13';
  static const heart =
      'M12 19s-6.5-4.1-6.5-8.7C5.5 7.5 7.4 6 9.3 6c1.1 0 2.1.5 2.7 1.4C12.6 6.5 13.6 6 14.7 6c1.9 0 3.8 1.5 3.8 4.3C18.5 14.9 12 19 12 19z';
  static const queue = 'M4 6h16M4 12h10M4 18h7';
  static const gear =
      'M12 4v2.5M12 17.5V20M4 12h2.5M17.5 12H20M6.3 6.3l1.8 1.8M15.9 15.9l1.8 1.8M17.7 6.3l-1.8 1.8M8.1 15.9l-1.8 1.8';
  static const gearCircle = 'M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z';
  static const search = 'M11 5a6 6 0 1 0 0 12 6 6 0 0 0 0-12zM15.5 15.5L20 20';
  static const moon = 'M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z';
  static const sun =
      'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8zM12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M18.4 5.6L17 7M7 17l-1.4 1.4';
  static const clock = 'M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16zM12 7.5V12l3 2';
  static const wave = 'M4 12h2l2-5 3 10 3-13 3 11 2-3h1';
  static const star =
      'M12 4l2.2 4.9 5.3.5-4 3.6 1.2 5.2-4.7-2.8-4.7 2.8 1.2-5.2-4-3.6 5.3-.5z';
  static const libraryTune = 'M4 6h16M4 12h10M4 18h7M17.5 15.5v5M20 18h-5';

  static final Map<String, Path> _cache = {};

  /// Parses [d] into a single multi-subpath [Path] (cached per icon).
  static Path path(String d) {
    final cached = _cache[d];
    if (cached != null) return cached;
    final result = _SvgPath(d).parse();
    _cache[d] = result;
    return result;
  }
}

class _SvgPath {
  final String d;
  int _i = 0;
  double _cx = 0, _cy = 0;
  double _sx = 0, _sy = 0;
  double? _px, _py; // last control point for S/T reflection
  String? _lastCmd;

  _SvgPath(this.d);

  Path parse() {
    final path = Path();
    while (_i < d.length) {
      _skip();
      if (_i >= d.length) break;
      final ch = d[_i];
      if (_isCmd(ch)) {
        _i++;
        _lastCmd = ch;
      } else {
        // Implicit repetition of the previous command.
        if (_lastCmd == null) break;
        final up = _lastCmd!.toUpperCase();
        if (up == 'M') {
          _lastCmd = _lastCmd == 'M' ? 'L' : 'l';
        }
      }
      final cmd = _lastCmd!;
      final rel = cmd == cmd.toLowerCase();
      switch (cmd.toUpperCase()) {
        case 'M':
          final x = _num(), y = _num();
          _cx = rel ? _cx + x : x;
          _cy = rel ? _cy + y : y;
          _sx = _cx;
          _sy = _cy;
          path.moveTo(_cx, _cy);
          _px = _py = null;
          break;
        case 'L':
          final x = _num(), y = _num();
          _cx = rel ? _cx + x : x;
          _cy = rel ? _cy + y : y;
          path.lineTo(_cx, _cy);
          _px = _py = null;
          break;
        case 'H':
          final x = _num();
          _cx = rel ? _cx + x : x;
          path.lineTo(_cx, _cy);
          _px = _py = null;
          break;
        case 'V':
          final y = _num();
          _cy = rel ? _cy + y : y;
          path.lineTo(_cx, _cy);
          _px = _py = null;
          break;
        case 'C':
          final x1 = _num(), y1 = _num(), x2 = _num(), y2 = _num(), x = _num(), y = _num();
          path.cubicTo(
            rel ? _cx + x1 : x1,
            rel ? _cy + y1 : y1,
            rel ? _cx + x2 : x2,
            rel ? _cy + y2 : y2,
            rel ? _cx + x : x,
            rel ? _cy + y : y,
          );
          _px = rel ? _cx + x2 : x2;
          _py = rel ? _cy + y2 : y2;
          _cx = rel ? _cx + x : x;
          _cy = rel ? _cy + y : y;
          break;
        case 'S':
          final x2 = _num(), y2 = _num(), x = _num(), y = _num();
          final rx = rel ? _cx + x2 : x2;
          final ry = rel ? _cy + y2 : y2;
          final ex = rel ? _cx + x : x;
          final ey = rel ? _cy + y : y;
          path.cubicTo(
            _px != null ? 2 * _cx - _px! : _cx,
            _py != null ? 2 * _cy - _py! : _cy,
            rx,
            ry,
            ex,
            ey,
          );
          _px = rx;
          _py = ry;
          _cx = ex;
          _cy = ey;
          break;
        case 'A':
          final rx = _num(), ry = _num(), rot = _num();
          final laf = _num(), sf = _num(), x = _num(), y = _num();
          _arcTo(path, rx, ry, rot, laf > 0.5, sf > 0.5, rel ? _cx + x : x, rel ? _cy + y : y);
          break;
        case 'Z':
          path.close();
          _cx = _sx;
          _cy = _sy;
          _px = _py = null;
          break;
        default:
          _i++; // defensive skip
      }
    }
    return path;
  }

  bool _isCmd(String c) => 'MmLlHhVvCcSsAaZz'.contains(c);

  void _skip() {
    while (_i < d.length && ' ,\n\r\t'.contains(d[_i])) {
      _i++;
    }
  }

  double _num() {
    _skip();
    final start = _i;
    if (_i < d.length && (d[_i] == '-' || d[_i] == '+')) _i++;
    while (_i < d.length && _isDigit(d[_i])) {
      _i++;
    }
    if (_i < d.length && d[_i] == '.') {
      _i++;
      while (_i < d.length && _isDigit(d[_i])) {
        _i++;
      }
    }
    final s = d.substring(start, _i);
    return double.tryParse(s) ?? 0;
  }

  bool _isDigit(String c) {
    final u = c.codeUnitAt(0);
    return u >= 0x30 && u <= 0x39;
  }

  void _arcTo(Path path, double rx, double ry, double xRotDeg, bool largeArc, bool sweep,
      double x, double y) {
    if (rx == 0 || ry == 0) {
      path.lineTo(x, y);
      _cx = x;
      _cy = y;
      return;
    }
    // Endpoint parameterization → center parameterization (W3C spec).
    final phi = xRotDeg * math.pi / 180;
    final cosP = math.cos(phi), sinP = math.sin(phi);
    final dx2 = (_cx - x) / 2, dy2 = (_cy - y) / 2;
    final x1p = cosP * dx2 + sinP * dy2;
    final y1p = -sinP * dx2 + cosP * dy2;
    rx = rx.abs();
    ry = ry.abs();
    final lambda = x1p * x1p / (rx * rx) + y1p * y1p / (ry * ry);
    if (lambda > 1) {
      final s = math.sqrt(lambda);
      rx *= s;
      ry *= s;
    }
    final sign = (largeArc != sweep) ? 1 : -1;
    final num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p;
    final den = rx * rx * y1p * y1p + ry * ry * x1p * x1p;
    final co = sign * math.sqrt(math.max(0, num / den));
    final cxp = co * rx * y1p / ry;
    final cyp = -co * ry * x1p / rx;
    final ccx = cosP * cxp - sinP * cyp + (_cx + x) / 2;
    final ccy = sinP * cxp + cosP * cyp + (_cy + y) / 2;

    double ang(double ux, double uy, double vx, double vy) {
      final dot = ux * vx + uy * vy;
      final len = math.sqrt(ux * ux + uy * uy) * math.sqrt(vx * vx + vy * vy);
      var a = math.acos((dot / len).clamp(-1.0, 1.0));
      if (ux * vy - uy * vx < 0) a = -a;
      return a;
    }

    final theta1 = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
    var dTheta = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry);
    if (!sweep && dTheta > 0) dTheta -= 2 * math.pi;
    if (sweep && dTheta < 0) dTheta += 2 * math.pi;

    final segments = (dTheta.abs() / (math.pi / 2)).ceil().clamp(1, 4);
    final delta = dTheta / segments;
    final t = 4 / 3 * math.tan(delta / 4);
    var th = theta1;
    var px = _cx, py = _cy;
    for (var s = 0; s < segments; s++) {
      final th2 = th + delta;
      final c1 = math.cos(th), s1 = math.sin(th);
      final c2 = math.cos(th2), s2 = math.sin(th2);
      final e1x = cosP * rx * c2 - sinP * ry * s2 + ccx;
      final e1y = sinP * rx * c2 + cosP * ry * s2 + ccy;
      final d1x = t * (-cosP * rx * s1 - sinP * ry * c1);
      final d1y = t * (-sinP * rx * s1 + cosP * ry * c1);
      final d2x = t * (cosP * rx * s2 + sinP * ry * c2);
      final d2y = t * (-sinP * rx * c2 + cosP * ry * s2);
      path.cubicTo(px + d1x, py + d1y, e1x + d2x, e1y + d2y, e1x, e1y);
      px = e1x;
      py = e1y;
      th = th2;
    }
    _cx = x;
    _cy = y;
    _px = _py = null;
  }
}

/// The icon widget. Renders one or two path strings (e.g. gear + its hub).
class BIcon extends StatelessWidget {
  final String path;
  final String? secondPath;
  final double size;
  final Color? color;
  final bool filled;

  const BIcon(
    this.path, {
    super.key,
    this.secondPath,
    this.size = BIcons.size,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effective = color ?? IconTheme.of(context).color ?? const Color(0xFFFFFFFF);
    final Path combined;
    final first = BIcons.path(path);
    final second = secondPath;
    if (second == null) {
      combined = first;
    } else {
      combined = Path();
      combined.addPath(first, Offset.zero);
      combined.addPath(BIcons.path(second), Offset.zero);
    }
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _IconPainter(
          path: combined,
          color: effective,
          filled: filled,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final Path path;
  final Color color;
  final bool filled;

  _IconPainter({required this.path, required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / BIcons.size;
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = BIcons.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.scale(scale);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color || old.filled != filled;
}
