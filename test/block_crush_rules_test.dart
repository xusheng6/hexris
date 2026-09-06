import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexris/models/game_state.dart';
import 'package:hexris/models/piece.dart';
import 'package:hexris/utils/storage.dart';

void main() {
  group('Block Crush Blitz square catalog', () {
    test('matches the recovered family weights and orientation counts', () {
      expect(blockCrushSquareFamilies, hasLength(9));
      expect(
        blockCrushSquareFamilies.fold<int>(0, (sum, item) => sum + item.weight),
        20,
      );
      expect(blockCrushSquareFamilies.map((family) => family.variants.length), [
        2,
        2,
        2,
        2,
        4,
        4,
        1,
        1,
        1,
      ]);
      expect(blockCrushSquareFamilies.map((family) => family.weight), [
        2,
        2,
        3,
        3,
        2,
        3,
        3,
        1,
        1,
      ]);
      expect(
        blockCrushSquareFamilies.map((family) => family.originalColorIndex),
        [1, 2, 3, 4, 9, 5, 7, 8, 6],
      );
    });

    test('generator is deterministic with an injected random source', () {
      final first = generateSquareTray(
        rules: GameRules.blockCrushBlitz,
        random: Random(1010),
      );
      final second = generateSquareTray(
        rules: GameRules.blockCrushBlitz,
        random: Random(1010),
      );
      expect(
        first.map((piece) => piece.cells),
        second.map((piece) => piece.cells),
      );
    });
  });

  group('Block Crush Blitz hex catalog', () {
    test('contains one dot and 21 distinct four-cell entries', () {
      expect(blockCrushHexPieceCatalog, hasLength(22));
      expect(blockCrushHexPieceCatalog.first.cells, hasLength(1));
      expect(
        blockCrushHexPieceCatalog
            .skip(1)
            .every((piece) => piece.cells.length == 4),
        isTrue,
      );
      final canonical = blockCrushHexPieceCatalog.map((piece) {
        final cells = piece.cells.map((c) => '${c.q},${c.r}').toList()..sort();
        return cells.join(';');
      }).toSet();
      expect(canonical, hasLength(22));
    });
  });

  group('Block Crush Blitz scoring and level progression', () {
    test('uses distinct cleared cells plus the simultaneous-line bonus', () {
      expect(blockCrushClearScore(10, 1), 20);
      expect(blockCrushClearScore(19, 2), 49);
      expect(blockCrushClearScore(27, 3), 87);
      expect(blockCrushClearScore(34, 4), 134);
    });

    test('matches recovered cumulative level thresholds', () {
      expect(blockCrushLevelThreshold(0), 0);
      expect(blockCrushLevelThreshold(1), 80);
      expect(blockCrushLevelThreshold(2), 180);
      expect(blockCrushLevelThreshold(9), 1720);
      expect(blockCrushLevelThreshold(10), 2100);
    });
  });
}
