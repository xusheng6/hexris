# Hex AI agents and benchmarks

`tools/hex_ai.py` is a dependency-free simulator, trainer, benchmark runner,
and replay exporter for the recovered Block Crush Blitz 1.7 hex rules. It uses
the exact 61-cell board, 22-piece uniform catalog, three-slot immediate refill,
line clearing, scoring, and game-over condition used by the app.

The environment RNG and policy RNG are independent. Every policy receives the
same environment seeds during a benchmark, so additional sampling performed by
expectimax cannot change its piece stream. Python's seeded PRNG is used for
reproducibility; it is not intended to reproduce the historical iOS PRNG bit
for bit.

## Agents

- **Random** selects uniformly from all legal `(tray slot, anchor)` actions.
- **Greedy** maximizes a hand-authored board-value function after one move.
- **Learned** uses the same value-function features, with weights trained by a
  cross-entropy evolutionary search over complete seeded games.
- **Expectimax** evaluates the four strongest first-ply candidates, samples
  three equally likely replacement pieces, and evaluates the best response for
  each sampled outcome. It combines immediate and expected next-ply value.
- **Stochastic rollout** follows the three strongest root moves through two
  independently sampled four-move futures, using the learned value policy for
  decisions inside each rollout. This is a longer-horizon Monte Carlo search.

Value features include immediate clear reward, occupied-cell count, squared
line fill, nearly complete lines, boundary exposure, sealed empty cells, and
remaining-piece mobility. The exported learned weights and training history are
stored in `assets/ai/benchmark.json`.

## Recorded benchmark

The checked-in benchmark used 20 common seeds and capped every game at 1,000
moves. The cap bounds runtime; none of the summary statistics should be read as
an estimate of mathematically optimal play.

| Agent | Mean score | Median score | Maximum | Mean moves |
|---|---:|---:|---:|---:|
| random | 49.75 | 18.5 | 206 | 14.00 |
| greedy | 1,055.30 | 899.5 | 2,993 | 116.05 |
| learned | 1,061.95 | 661.0 | 3,882 | 115.30 |
| expectimax | **3,721.55** | **2,537.0** | **10,346** | **369.80** |

Expectimax won decisively on both mean and median. The trained value model only
slightly improved mean score over the hand-authored greedy policy and had a
lower median, so the evidence does not establish that training alone produced
a generally stronger player. Search produced the material improvement.

A subsequent paired 20-seed comparison tested stochastic rollout against
expectimax. Rollout had a higher median (2,777 vs 2,537), a higher lower
quartile (1,282.5 vs 908.5), and won 11 of 20 paired seeds. Expectimax retained
the higher mean (3,721.55 vs 3,256.90) and ran in 41.8 seconds versus rollout's
98.2 seconds. Rollout is therefore more robust in a typical run, while
expectimax remains better for expected score and computational efficiency.

## Neural experiment

`tools/train_hex_nn.py` trains a 130 → 96 → 1 ReLU afterstate network by
imitating expectimax choices. Inputs contain all 61 board cells, the two tray
pieces not consumed by the candidate action, immediate reward, board density,
and tray-slot identity. Training expands positions through all 12 rotations and
reflections of the hexagon.

The recorded run used 1,427 teacher positions, expanded to 17,124 training
groups, with 159 unaugmented held-out positions. Top-one imitation accuracy was
66.04%. Evaluation used 20 new seeds not used for teacher generation.

| Agent | Mean | Median | Lower quartile | Maximum |
|---|---:|---:|---:|---:|
| neural one-ply | 678.70 | 497.0 | 250.5 | 2,565 |
| neural + expectimax | 2,532.00 | 1,909.0 | 997.0 | **10,481** |
| handcrafted expectimax | **5,073.90** | **4,325.5** | **1,807.0** | 10,357 |

The neural model did not beat handcrafted expectimax overall. Its hybrid did
produce the highest single paired score, but its much lower mean and median
show that it generalizes inconsistently. More teacher positions, direct value
targets instead of choice imitation, and iterative self-play/search
distillation are the clearest next improvements.

## Reproducing or extending the run

From the repository root:

```bash
python3 tools/hex_ai.py \
  --train --generations 6 --population 14 \
  --games 20 --max-moves 1000 --output assets/ai
```

The neural trainer requires NumPy. Train and evaluate it with:

```bash
python3 tools/train_hex_nn.py \
  --teacher-games 12 --positions 140 --epochs 8 \
  --benchmark-games 20 --max-moves 1000
```

The first command writes `benchmark.json` plus the best replay found for greedy,
learned, expectimax, and rollout agents. Increase the game count and training
population for a more stable comparison; rollout is the slowest policy.

## Replays

Open Settings → **AI best-game replays** in the app. The viewer offers play,
pause, single-step, restart, scrubbing, and agent selection. Checked-in best
games have these final scores:

| Agent | Score | Moves |
|---|---:|---:|
| greedy | 2,191 | 229 |
| learned | 2,437 | 256 |
| expectimax | 5,975 | 584 |
| stochastic rollout | 4,887 | 472 |
| neural + expectimax | 10,481 | 1,000 (benchmark cap) |

A replay records the seed, actual piece stream, chosen tray slot, piece catalog
index, anchor, replacement, clears, and cumulative score for every move. The
viewer reconstructs the board through the production Dart rules rather than
storing board screenshots.
