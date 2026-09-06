# Block Crush Blitz rules

Hexris includes a selectable implementation of the gameplay mechanics recovered
from the decrypted ARM64 executable of Block Crush Blitz 1.7. It is the default
ruleset; the pre-existing modern Hexris behavior can be restored in Settings.

The replica covers the active piece catalogs, generation probabilities, board
geometry, line clearing, tray refill, shape-to-color grouping, scoring, game
over detection, and level thresholds. Undo remains available as an intentional
quality-of-life exception. Flat colors stand in for the original textured art.

## Boards

- Square: 10 by 10; complete rows and columns clear.
- Hex: 61 cells in a radius-four axial hexagon; complete lines on any of the
  three axes clear.
- Pieces must remain on the board and cannot overlap occupied cells.
- The game ends when no available tray piece has a legal placement.

## Square generation

The game first chooses a family by integer weight, then chooses an orientation
uniformly within that family. Weights total 20. Consecutive duplicates are
allowed.

| Family | Cells | Weight | Orientations | Family probability | Per orientation |
|---|---:|---:|---:|---:|---:|
| line 5 | 5 | 2 | 2 | 10% | 5% |
| line 4 | 4 | 2 | 2 | 10% | 5% |
| line 3 | 3 | 3 | 2 | 15% | 7.5% |
| line 2 | 2 | 3 | 2 | 15% | 7.5% |
| large corner/L | 5 | 2 | 4 | 10% | 2.5% |
| small corner/L | 3 | 3 | 4 | 15% | 3.75% |
| 2 by 2 square | 4 | 3 | 1 | 15% | 15% |
| 3 by 3 square | 9 | 1 | 1 | 5% | 5% |
| dot | 1 | 1 | 1 | 5% | 5% |

Square mode deals three pieces as a batch. It deals the next batch only after
all three have been used.

## Hex generation

The active catalog has exactly 22 entries: one dot and 21 distinct four-cell
pieces/orientations. It selects directly and uniformly from that catalog, so
every concrete entry has probability `1/22`, approximately 4.545%. There are no
active two-cell or three-cell hex pieces. All entries are active from level one,
and consuming a piece replaces its tray slot immediately.

The executable stores the entries as these 4 by 4 row-major masks. Rows use an
even-row offset hex grid and are concatenated in selection order:

```text
0000010000000000
0010011000100000
0000011001100000
0000011000110000
0100010000100010
0001001000100100
0000000011110000
0010011000010000
0110010001000000
0100011000100000
0010111000000000
0000111001000000
0110010000100000
0010011001000000
0001011000100000
0100111000000000
0000111000100000
0100100001100000
0000011001010000
0110001000100000
0010001001100000
0000101001100000
```

Color is coupled to the selected piece rather than independently randomized.
The fixed color groups contain catalog entries 1; 2–4; 5–7; 8–12; 13–17; and
18–22.

## Scoring and progression

Placing a piece awards no points by itself. A clear awards:

```text
distinct cells removed + lineCount * (10 + 5 * (lineCount - 1))
```

The simultaneous-line bonus is therefore 10, 30, 60, 100, and so on for one,
two, three, four, and subsequent lines. A cell at a line intersection is counted
only once in the distinct-cell term.

Displayed level thresholds use:

```text
T(0) = 0
T(1) = 80
T(n) = T(n-1) + floor(n/10)*40 + 70 + 30*(n-1), n >= 2
```

Advancement uses a strict `score > threshold` comparison. Although the
executable computes a level-dependent hex pool size, it is already capped at
all 22 active entries at level one.

## Differences from modern Hexris

| Behavior | Block Crush Blitz | Modern Hexris |
|---|---|---|
| Default | Yes | No |
| Hex catalog | dot plus 21 four-cell entries | broader 1–4-cell catalog |
| Hex probability | each entry is 1/22 | uniform over modern catalog |
| Square selection | weighted families | uniform catalog entries |
| Piece colors | fixed by piece group | independently random |
| Placement score | zero | number of cells placed |
| Clear bonus | original escalating formula | simpler combo formula |
| Square refill | after all three are used | replace each used slot |
| Hex refill | replace each used slot | replace each used slot |
| Undo | available as a convenience | available |

High scores are stored separately for every board-mode/ruleset combination.
Switching rulesets resets the active board and tray.
