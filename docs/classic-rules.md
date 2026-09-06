# Classic rules

Hexris includes an optional Classic ruleset. Modern Hexris remains the default.
Changing rulesets starts a new board and keeps high scores separate.

## Boards

- Square uses a 10 by 10 board and clears complete rows and columns.
- Hex uses a 61-cell radius-four board and clears complete lines along all
  three hex axes.
- The game ends when none of the available pieces has a legal placement.

## Square pieces

Classic square generation chooses a weighted family, then uniformly chooses an
orientation within that family.

| Family | Weight | Orientations | Family chance | Chance per orientation |
|---|---:|---:|---:|---:|
| line 5 | 2 | 2 | 10% | 5% |
| line 4 | 2 | 2 | 10% | 5% |
| line 3 | 3 | 2 | 15% | 7.5% |
| line 2 | 3 | 2 | 15% | 7.5% |
| large corner | 2 | 4 | 10% | 2.5% |
| small corner | 3 | 4 | 15% | 3.75% |
| 2 by 2 square | 3 | 1 | 15% | 15% |
| 3 by 3 square | 1 | 1 | 5% | 5% |
| dot | 1 | 1 | 5% | 5% |

Square pieces are dealt in batches of three; a new batch appears after all
three pieces have been used.

## Hex pieces

The Classic hex catalog contains 22 uniformly selected entries: one dot and 21
distinct four-cell pieces/orientations. Every entry has probability `1/22`
(approximately 4.545%). A consumed slot is replaced immediately.

## Scoring

Placement itself awards no points. A clear awards:

```text
distinct cells removed + lineCount × (10 + 5 × (lineCount - 1))
```

Undo remains available in both rulesets.
