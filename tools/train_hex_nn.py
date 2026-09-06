#!/usr/bin/env python3
"""Train and benchmark a compact neural afterstate model for hex play."""

from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from hex_ai import (  # noqa: E402
    COORDS, HAND_WEIGHTS, PIECES, Agent, Result, SampledExpectimaxAgent,
    legal_actions, place, play,
)

INPUT_SIZE = 61 + 66 + 3


def symmetry_permutations():
    index = {coord: i for i, coord in enumerate(COORDS)}
    permutations = []
    for reflected in (False, True):
        for rotations in range(6):
            permutation = []
            for q, r in COORDS:
                if reflected:
                    q, r = q, -q - r
                for _ in range(rotations):
                    q, r = -r, q + r
                permutation.append(index[(q, r)])
            permutations.append(permutation)
    return permutations


SYMMETRIES = symmetry_permutations()


def augment(groups):
    augmented = []
    for group in groups:
        for permutation in SYMMETRIES:
            transformed = group.copy()
            transformed[:, permutation] = group[:, :61]
            augmented.append(transformed)
    return augmented


def encode(board: int, tray: tuple[int, int, int], action, result: Result):
    slot = action[0]
    x = np.zeros(INPUT_SIZE, dtype=np.float32)
    for i in range(61):
        x[i] = float((result.board >> i) & 1)
    for tray_slot, piece in enumerate(tray):
        if tray_slot != slot:
            x[61 + tray_slot * 22 + piece] = 1.0
    x[127] = result.reward / 100.0
    x[128] = result.board.bit_count() / 61.0
    x[129] = slot / 2.0
    return x


class Mlp:
    def __init__(self, hidden=64, seed=1010):
        rng = np.random.default_rng(seed)
        self.w1 = rng.normal(0, np.sqrt(2 / INPUT_SIZE), (INPUT_SIZE, hidden)).astype(np.float32)
        self.b1 = np.zeros(hidden, dtype=np.float32)
        self.w2 = rng.normal(0, np.sqrt(2 / hidden), (hidden,)).astype(np.float32)
        self.b2 = np.float32(0)

    def forward(self, x):
        z = x @ self.w1 + self.b1
        h = np.maximum(z, 0)
        return h @ self.w2 + self.b2, z, h

    def save(self, path: Path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({
            "version": 1, "inputSize": INPUT_SIZE, "hiddenSize": len(self.b1),
            "w1": self.w1.tolist(), "b1": self.b1.tolist(),
            "w2": self.w2.tolist(), "b2": float(self.b2),
        }, separators=(",", ":")))

    @classmethod
    def load(cls, path: Path):
        data = json.loads(path.read_text())
        model = cls(hidden=data["hiddenSize"])
        model.w1 = np.asarray(data["w1"], dtype=np.float32)
        model.b1 = np.asarray(data["b1"], dtype=np.float32)
        model.w2 = np.asarray(data["w2"], dtype=np.float32)
        model.b2 = np.float32(data["b2"])
        return model


class NeuralAgent(Agent):
    name = "neural"

    def __init__(self, model: Mlp):
        self.model = model

    def ranked(self, board, tray):
        actions = list(legal_actions(board, tray))
        if not actions:
            return []
        results = [place(board, a[4]) for a in actions]
        batch = np.stack([encode(board, tray, a, r) for a, r in zip(actions, results)])
        scores = self.model.forward(batch)[0]
        order = np.argsort(scores)[::-1]
        return [(float(scores[i]), actions[i], results[i]) for i in order]

    def choose(self, board, tray, rng):
        ranked = self.ranked(board, tray)
        return ranked[0][1] if ranked else None


class NeuralExpectimaxAgent(NeuralAgent):
    name = "neural_expectimax"

    def __init__(self, model, width=6, chance_samples=5):
        super().__init__(model)
        self.width = width
        self.chance_samples = chance_samples

    def choose(self, board, tray, rng):
        candidates = self.ranked(board, tray)[:self.width]
        if not candidates:
            return None
        replacements = [rng.randrange(22) for _ in range(self.chance_samples)]
        best_value, best = -float("inf"), candidates[0][1]
        for immediate, action, result in candidates:
            future = 0.0
            for replacement in replacements:
                next_tray = list(tray)
                next_tray[action[0]] = replacement
                ranked = self.ranked(result.board, tuple(next_tray))
                future += ranked[0][0] if ranked else -50.0
            value = immediate + 0.55 * future / self.chance_samples
            if value > best_value:
                best_value, best = value, action
        return best


def collect(seed_start=40000, games=10, positions_per_game=140, negatives=11):
    teacher = SampledExpectimaxAgent(HAND_WEIGHTS)
    groups = []
    for game_index in range(games):
        seed = seed_start + game_index
        env_rng = random.Random(seed)
        policy_rng = random.Random(seed ^ 0xB10CCB17)
        sample_rng = random.Random(seed ^ 0xA11CE)
        board = 0
        tray = tuple(env_rng.randrange(22) for _ in range(3))
        for _ in range(positions_per_game):
            actions = list(legal_actions(board, tray))
            if not actions:
                break
            chosen = teacher.choose(board, tray, policy_rng)
            alternatives = [a for a in actions if a != chosen]
            sampled = sample_rng.sample(alternatives, min(negatives, len(alternatives)))
            candidates = [chosen, *sampled]
            groups.append(np.stack([encode(board, tray, a, place(board, a[4])) for a in candidates]))
            result = place(board, chosen[4])
            board = result.board
            next_tray = list(tray)
            next_tray[chosen[0]] = env_rng.randrange(22)
            tray = tuple(next_tray)
        print(f"teacher game {game_index + 1}/{games}: {len(groups)} positions", flush=True)
    return groups


def train(model, groups, epochs=18, learning_rate=0.002, seed=1010):
    rng = random.Random(seed)
    params = [model.w1, model.b1, model.w2]
    moments = [np.zeros_like(p) for p in params]
    velocities = [np.zeros_like(p) for p in params]
    step = 0
    for epoch in range(epochs):
        rng.shuffle(groups)
        total_loss = 0.0
        correct = 0
        for x in groups:
            scores, z, h = model.forward(x)
            shifted = scores - scores.max()
            probs = np.exp(shifted) / np.exp(shifted).sum()
            total_loss -= float(np.log(probs[0] + 1e-9))
            correct += int(np.argmax(scores) == 0)
            ds = probs
            ds[0] -= 1.0
            gw2 = h.T @ ds
            gb2 = ds.sum()
            dh = np.outer(ds, model.w2)
            dz = dh * (z > 0)
            gw1 = x.T @ dz
            gb1 = dz.sum(axis=0)
            grads = [gw1, gb1, gw2]
            step += 1
            for i, (param, grad) in enumerate(zip(params, grads)):
                np.clip(grad, -5, 5, out=grad)
                moments[i] = 0.9 * moments[i] + 0.1 * grad
                velocities[i] = 0.999 * velocities[i] + 0.001 * grad * grad
                mh = moments[i] / (1 - 0.9 ** step)
                vh = velocities[i] / (1 - 0.999 ** step)
                param -= learning_rate * mh / (np.sqrt(vh) + 1e-8)
            model.b2 -= learning_rate * gb2
        print(f"epoch {epoch + 1:02d}: loss {total_loss/len(groups):.4f}, top1 {correct/len(groups):.3f}", flush=True)


def benchmark(agents, seeds, max_moves):
    rows = []
    raw = {}
    for agent in agents:
        games = []
        for i, seed in enumerate(seeds, 1):
            result = play(agent, seed, max_moves)
            games.append(result)
            print(agent.name, i, result["score"], result["moves"], flush=True)
        scores = sorted(g["score"] for g in games)
        row = {
            "agent": agent.name, "games": len(games),
            "meanScore": float(np.mean(scores)), "medianScore": float(np.median(scores)),
            "lowerQuartile": float(np.median(scores[:len(scores)//2])),
            "upperQuartile": float(np.median(scores[len(scores)//2:])),
            "minScore": min(scores), "maxScore": max(scores),
            "meanMoves": float(np.mean([g["moves"] for g in games])),
        }
        rows.append(row)
        raw[agent.name] = [g["score"] for g in games]
    return rows, raw


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("assets/ai/neural_model.json"))
    parser.add_argument("--report", type=Path, default=Path("assets/ai/neural_benchmark.json"))
    parser.add_argument("--teacher-games", type=int, default=10)
    parser.add_argument("--positions", type=int, default=140)
    parser.add_argument("--epochs", type=int, default=18)
    parser.add_argument("--benchmark-games", type=int, default=20)
    parser.add_argument("--max-moves", type=int, default=1000)
    args = parser.parse_args()
    groups = collect(games=args.teacher_games, positions_per_game=args.positions)
    split = int(len(groups) * 0.9)
    train_groups, validation = groups[:split], groups[split:]
    augmented = augment(train_groups)
    print(f"symmetry augmentation: {len(train_groups)} -> {len(augmented)} groups", flush=True)
    model = Mlp(hidden=96)
    train(model, augmented, epochs=args.epochs)
    validation_accuracy = np.mean([np.argmax(model.forward(x)[0]) == 0 for x in validation])
    model.save(args.output)
    seeds = list(range(50000, 50000 + args.benchmark_games))
    agents = [NeuralAgent(model), NeuralExpectimaxAgent(model), SampledExpectimaxAgent(HAND_WEIGHTS)]
    rows, raw = benchmark(agents, seeds, args.max_moves)
    args.report.write_text(json.dumps({
        "teacher": "sampled_expectimax", "trainingPositions": len(train_groups),
        "augmentedTrainingPositions": len(augmented),
        "validationPositions": len(validation), "validationTop1": float(validation_accuracy),
        "benchmarkSeeds": seeds, "benchmarks": rows, "pairedScores": raw,
    }, indent=2))
    print(json.dumps(rows, indent=2), flush=True)


if __name__ == "__main__":
    main()
