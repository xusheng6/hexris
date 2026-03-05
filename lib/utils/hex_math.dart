import 'dart:math';
import 'dart:ui';
import '../models/coordinates.dart';

/// Convert axial hex coordinate to pixel center (pointy-top orientation).
Offset hexToPixel(HexCoord hex, double size) {
  final x = size * (sqrt(3) * hex.q + sqrt(3) / 2 * hex.r);
  final y = size * (3.0 / 2 * hex.r);
  return Offset(x, y);
}

/// Convert pixel position to nearest axial hex coordinate (pointy-top).
HexCoord pixelToHex(Offset point, double size) {
  final q = (sqrt(3) / 3 * point.dx - 1.0 / 3 * point.dy) / size;
  final r = (2.0 / 3 * point.dy) / size;
  return _axialRound(q, r);
}

HexCoord _axialRound(double q, double r) {
  final s = -q - r;
  var rq = q.round();
  var rr = r.round();
  var rs = s.round();
  final dq = (rq - q).abs();
  final dr = (rr - r).abs();
  final ds = (rs - s).abs();
  if (dq > dr && dq > ds) {
    rq = -rr - rs;
  } else if (dr > ds) {
    rr = -rq - rs;
  }
  return HexCoord(rq, rr);
}

/// Compute 6 vertices of a pointy-top hexagon centered at (cx, cy).
List<Offset> hexVertices(double cx, double cy, double size) {
  return List.generate(6, (i) {
    final angle = pi / 180 * (60 * i - 30);
    return Offset(cx + size * cos(angle), cy + size * sin(angle));
  });
}
