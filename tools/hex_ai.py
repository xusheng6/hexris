#!/usr/bin/env python3
"""Train, benchmark, and export agents for Block Crush Blitz hex mode.

Uses only Python's standard library. The simulator mirrors the Dart rules:
61-cell radius-four board, the recovered 22-entry catalog, immediate tray-slot
replacement, three-axis clears, and original scoring.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import statistics
from dataclasses import dataclass
from pathlib import Path

MASKS = (
    "0000010000000000", "0010011000100000", "0000011001100000",
    "0000011000110000", "0100010000100010", "0001001000100100",
    "0000000011110000", "0010011000010000", "0110010001000000",
    "0100011000100000", "0010111000000000", "0000111001000000",
    "0110010000100000", "0010011001000000", "0001011000100000",
    "0100111000000000", "0000111000100000", "0100100001100000",
    "0000011001010000", "0110001000100000", "0010001001100000",
    "0000101001100000",
)

COORDS = tuple(
    (q, r)
    for q in range(-4, 5)
    for r in range(-4, 5)
    if abs(q + r) <= 4
)
INDEX = {coord: i for i, coord in enumerate(COORDS)}
FULL = (1 << len(COORDS)) - 1


def decode(mask: str) -> tuple[tuple[int, int], ...]:
    cells = []
    for y in range(4):
        for x in range(4):
            if mask[y * 4 + x] == "1":
                cells.append((x - y // 2, y))
    oq, origin_r = cells[0]
    return tuple((q - oq, r - origin_r) for q, r in cells)


PIECES = tuple(decode(mask) for mask in MASKS)
LINES = tuple(
    sum((1 << INDEX[c] for c in COORDS if axis(c) == value), 0)
    for axis in (lambda c: c[0], lambda c: c[1], lambda c: -c[0] - c[1])
    for value in range(-4, 5)
)
NEIGHBORS = tuple(
    sum(
        (1 << INDEX[n] for n in (
            (q + 1, r), (q + 1, r - 1), (q, r - 1),
            (q - 1, r), (q - 1, r + 1), (q, r + 1),
        ) if n in INDEX),
        0,
    )
    for q, r in COORDS
)


def placements(piece: tuple[tuple[int, int], ...]) -> tuple[tuple[int, int, int], ...]:
    result = []
    for anchor in COORDS:
        cells = [(anchor[0] + dq, anchor[1] + dr) for dq, dr in piece]
        if all(cell in INDEX for cell in cells):
            result.append((anchor[0], anchor[1], sum(1 << INDEX[c] for c in cells)))
    return tuple(result)


PLACEMENTS = tuple(placements(piece) for piece in PIECES)


@dataclass(frozen=True)
class Result:
    board: int
    reward: int
    cleared_cells: int
    lines: int


def place(board: int, mask: int) -> Result:
    occupied = board | mask
    completed = [line for line in LINES if occupied & line == line]
    clear_mask = 0
    for line in completed:
        clear_mask |= line
    cleared = clear_mask.bit_count()
    count = len(completed)
    reward = cleared + count * (10 + 5 * (count - 1)) if count else 0
    return Result(occupied & ~clear_mask, reward, cleared, count)


def legal_actions(board: int, tray: tuple[int, int, int]):
    for slot, piece in enumerate(tray):
        for q, r, mask in PLACEMENTS[piece]:
            if board & mask == 0:
                yield slot, piece, q, r, mask


def features(board: int, reward: int, tray: tuple[int, int, int]) -> tuple[float, ...]:
    counts = [(board & line).bit_count() for line in LINES]
    empty_islands = 0
    exposed = 0
    for i, neighbor_mask in enumerate(NEIGHBORS):
        if not (board >> i) & 1:
            occupied_neighbors = (board & neighbor_mask).bit_count()
            exposed += occupied_neighbors * occupied_neighbors
            if occupied_neighbors == neighbor_mask.bit_count():
                empty_islands += 1
    mobility = 0
    for piece in set(tray):
        mobility += sum(1 for _, _, mask in PLACEMENTS[piece] if board & mask == 0)
    return (
        1.0,
        float(reward),
        float(board.bit_count()),
        float(sum(c * c for c in counts)),
        float(sum(c >= line.bit_count() - 1 for c, line in zip(counts, LINES))),
        float(exposed),
        float(empty_islands),
        float(mobility),
    )


def dot(weights, values):
    return sum(a * b for a, b in zip(weights, values))


HAND_WEIGHTS = (0.0, 12.0, -3.2, 0.24, 2.0, -0.08, -7.0, 0.025)


class Agent:
    name = "agent"

    def choose(self, board, tray, rng):
        raise NotImplementedError


class RandomAgent(Agent):
    name = "random"

    def choose(self, board, tray, rng):
        actions = list(legal_actions(board, tray))
        return rng.choice(actions) if actions else None


class ValueAgent(Agent):
    def __init__(self, weights, name="learned"):
        self.weights = tuple(weights)
        self.name = name

    def ranked(self, board, tray):
        ranked = []
        for action in legal_actions(board, tray):
            result = place(board, action[4])
            # Mobility is evaluated with the consumed piece still present. It
            # is a stable expectation proxy during action ranking.
            ranked.append((dot(self.weights, features(result.board, result.reward, tray)), action, result))
        ranked.sort(key=lambda item: item[0], reverse=True)
        return ranked

    def choose(self, board, tray, rng):
        ranked = self.ranked(board, tray)
        return ranked[0][1] if ranked else None


class SampledExpectimaxAgent(ValueAgent):
    """Two-ply expectimax over the most promising first-ply actions."""

    def __init__(self, weights=HAND_WEIGHTS, width=4, chance_samples=3):
        super().__init__(weights, "expectimax")
        self.width = width
        self.chance_samples = chance_samples

    def choose(self, board, tray, rng):
        candidates = self.ranked(board, tray)[: self.width]
        if not candidates:
            return None
        best = None
        best_value = -math.inf
        sample_pieces = [rng.randrange(len(PIECES)) for _ in range(self.chance_samples)]
        for immediate, action, result in candidates:
            future = 0.0
            for replacement in sample_pieces:
                next_tray = list(tray)
                next_tray[action[0]] = replacement
                next_ranked = self.ranked(result.board, tuple(next_tray))
                future += next_ranked[0][0] if next_ranked else -5000.0
            value = immediate + 0.45 * future / self.chance_samples
            if value > best_value:
                best_value, best = value, action
        return best


def play(agent: Agent, seed: int, max_moves=3000, record=False):
    rng = random.Random(seed)
    policy_rng = random.Random(seed ^ 0xB10CCB17)
    board = 0
    tray = tuple(rng.randrange(len(PIECES)) for _ in range(3))
    score = 0
    moves = 0
    replay = []
    for turn in range(max_moves):
        before = tray
        action = agent.choose(board, tray, policy_rng)
        if action is None:
            break
        slot, piece, q, r, mask = action
        result = place(board, mask)
        board = result.board
        score += result.reward
        moves += 1
        replacement = rng.randrange(len(PIECES))
        tray_list = list(tray)
        tray_list[slot] = replacement
        tray = tuple(tray_list)
        if record:
            replay.append({
                "turn": turn + 1, "slot": slot, "piece": piece,
                "anchor": [q, r], "trayBefore": list(before),
                "replacement": replacement, "cleared": result.cleared_cells,
                "lines": result.lines, "scoreAfter": score,
            })
    return {"score": score, "moves": moves, "board": board, "steps": replay}


def evaluate(agent, seeds, max_moves=3000):
    games = [play(agent, seed, max_moves=max_moves) for seed in seeds]
    scores = [g["score"] for g in games]
    moves = [g["moves"] for g in games]
    return {
        "agent": agent.name, "games": len(games),
        "meanScore": statistics.fmean(scores), "medianScore": statistics.median(scores),
        "minScore": min(scores), "maxScore": max(scores),
        "meanMoves": statistics.fmean(moves),
    }


def train(seed=1010, generations=8, population=16, episodes=3, max_moves=600):
    rng = random.Random(seed)
    mean = list(HAND_WEIGHTS)
    sigma = [1.0, 5.0, 1.2, 0.2, 1.0, 0.08, 2.0, 0.02]
    history = []
    for generation in range(generations):
        seeds = [100000 + generation * episodes + i for i in range(episodes)]
        candidates = []
        if generation == 0:
            candidates.append(mean[:])
        while len(candidates) < population:
            candidates.append([rng.gauss(m, s) for m, s in zip(mean, sigma)])
        ranked = []
        for weights in candidates:
            metric = evaluate(ValueAgent(weights), seeds, max_moves=max_moves)
            ranked.append((metric["meanScore"] + metric["meanMoves"] * 0.1, weights))
        ranked.sort(reverse=True, key=lambda item: item[0])
        elite = [weights for _, weights in ranked[: max(4, population // 5)]]
        mean = [statistics.fmean(w[i] for w in elite) for i in range(len(mean))]
        sigma = [max(0.01, statistics.pstdev(w[i] for w in elite) * 0.85) for i in range(len(mean))]
        history.append({"generation": generation + 1, "fitness": ranked[0][0]})
        print(f"generation {generation + 1:02d}: best fitness {ranked[0][0]:.1f}", flush=True)
    return mean, history


def export_replay(path: Path, agent, seed, max_moves):
    game = play(agent, seed, max_moves=max_moves, record=True)
    payload = {
        "version": 1, "rules": "blockCrushBlitzHex", "agent": agent.name,
        "seed": seed, "score": game["score"], "moves": game["moves"],
        "steps": game["steps"],
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, separators=(",", ":")))
    return payload


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("ai_results"))
    parser.add_argument("--train", action="store_true")
    parser.add_argument("--games", type=int, default=30)
    parser.add_argument("--max-moves", type=int, default=2000)
    parser.add_argument("--generations", type=int, default=8)
    parser.add_argument("--population", type=int, default=16)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    learned_weights = HAND_WEIGHTS
    history = []
    if args.train:
        learned_weights, history = train(
            generations=args.generations, population=args.population,
            max_moves=min(args.max_moves, 600),
        )
    agents = [
        RandomAgent(), ValueAgent(HAND_WEIGHTS, "greedy"),
        ValueAgent(learned_weights, "learned"), SampledExpectimaxAgent(learned_weights),
    ]
    seeds = list(range(20000, 20000 + args.games))
    benchmarks = []
    for agent in agents:
        metric = evaluate(agent, seeds, max_moves=args.max_moves)
        benchmarks.append(metric)
        print(json.dumps(metric), flush=True)

    replays = []
    replay_seeds = list(range(30000, 30010))
    for agent in agents[1:]:
        best_seed = max(replay_seeds, key=lambda seed: play(agent, seed, args.max_moves)["score"])
        target = args.output / "replays" / f"best_{agent.name}.json"
        replays.append(str(target))
        export_replay(target, agent, best_seed, args.max_moves)
    report = {
        "simulator": "Block Crush Blitz 1.7 hex", "weights": learned_weights,
        "features": ["bias", "clearReward", "occupied", "lineFillSquared",
                     "nearCompleteLines", "exposureSquared", "sealedEmptyCells", "mobility"],
        "training": history, "benchmarkSeeds": seeds, "benchmarks": benchmarks,
        "replays": replays,
    }
    (args.output / "benchmark.json").write_text(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
