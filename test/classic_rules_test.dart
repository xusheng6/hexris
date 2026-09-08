import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexris/models/game_state.dart';
import 'package:hexris/models/piece.dart';
import 'package:hexris/utils/storage.dart';

void main() {
  group('Classic square catalog', () {
    test('unlocks the recovered 31-entry catalog progressively', () {
      expect(classicSquarePieceCatalog, hasLength(31));
      expect(classicSquarePoolSize(1), 9);
      expect(classicSquarePoolSize(2), 10);
      expect(classicSquarePoolSize(22), 30);
      expect(classicSquarePoolSize(23), 31);
      expect(classicSquarePoolSize(100), 31);
    });

    test('matches the recovered family weights and orientation counts', () {
      expect(classicSquareFamilies, hasLength(9));
      expect(
        classicSquareFamilies.fold<int>(0, (sum, item) => sum + item.weight),
        20,
      );
      expect(classicSquareFamilies.map((family) => family.variants.length), [
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
      expect(classicSquareFamilies.map((family) => family.weight), [
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
      expect(classicSquareFamilies.map((family) => family.originalColorIndex), [
        1,
        2,
        3,
        4,
        9,
        5,
        7,
        8,
        6,
      ]);
    });

    test('generator is deterministic with an injected random source', () {
      final first = generateSquareTray(
        rules: GameRules.classic,
        random: Random(1010),
      );
      final second = generateSquareTray(
        rules: GameRules.classic,
        random: Random(1010),
      );
      expect(
        first.map((piece) => piece.cells),
        second.map((piece) => piece.cells),
      );
    });
  });

  group('Classic hex catalog', () {
    test('contains one dot and 21 distinct four-cell entries', () {
      expect(classicHexPieceCatalog, hasLength(22));
      expect(classicHexPieceCatalog.first.cells, hasLength(1));
      expect(
        classicHexPieceCatalog
            .skip(1)
            .every((piece) => piece.cells.length == 4),
        isTrue,
      );
      final canonical = classicHexPieceCatalog.map((piece) {
        final cells = piece.cells.map((c) => '${c.q},${c.r}').toList()..sort();
        return cells.join(';');
      }).toSet();
      expect(canonical, hasLength(22));
    });
  });

  group('Classic scoring and level progression', () {
    test('uses distinct cleared cells plus the simultaneous-line bonus', () {
      expect(classicClearScore(10, 1), 20);
      expect(classicClearScore(19, 2), 49);
      expect(classicClearScore(27, 3), 87);
      expect(classicClearScore(34, 4), 134);
    });

    test('matches recovered cumulative level thresholds', () {
      expect(classicLevelThreshold(0), 0);
      expect(classicLevelThreshold(1), 80);
      expect(classicLevelThreshold(2), 180);
      expect(classicLevelThreshold(9), 1720);
      expect(classicLevelThreshold(10), 2100);
      expect(classicLevelForScore(80), 1);
      expect(classicLevelForScore(81), 2);
      expect(classicLevelForScore(180), 2);
      expect(classicLevelForScore(181), 3);
    });
  });
}
