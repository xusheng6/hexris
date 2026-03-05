class SquareCoord {
  final int row;
  final int col;

  const SquareCoord(this.row, this.col);

  SquareCoord operator +(SquareCoord other) =>
      SquareCoord(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      other is SquareCoord && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Sq($row,$col)';
}

class HexCoord {
  final int q;
  final int r;

  const HexCoord(this.q, this.r);

  int get s => -q - r;

  HexCoord operator +(HexCoord other) =>
      HexCoord(q + other.q, r + other.r);

  static const List<HexCoord> directions = [
    HexCoord(1, 0),   // east
    HexCoord(1, -1),  // northeast
    HexCoord(0, -1),  // northwest
    HexCoord(-1, 0),  // west
    HexCoord(-1, 1),  // southwest
    HexCoord(0, 1),   // southeast
  ];

  @override
  bool operator ==(Object other) =>
      other is HexCoord && q == other.q && r == other.r;

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'Hex($q,$r)';
}

Set<HexCoord> generateHexBoard(int radius) {
  final cells = <HexCoord>{};
  final max = radius - 1;
  for (int q = -max; q <= max; q++) {
    for (int r = -max; r <= max; r++) {
      if ((q + r).abs() <= max) {
        cells.add(HexCoord(q, r));
      }
    }
  }
  return cells;
}
