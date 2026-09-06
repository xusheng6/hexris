import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/hex_grid_logic.dart';
import '../models/ai_replay.dart';
import '../models/coordinates.dart';
import '../models/piece.dart';
import '../painters/hex_grid_painter.dart';
import '../utils/colors.dart';

class AiReplayScreen extends StatefulWidget {
  const AiReplayScreen({super.key});

  @override
  State<AiReplayScreen> createState() => _AiReplayScreenState();
}

class _ReplayChoice {
  final String label;
  final String asset;

  const _ReplayChoice(this.label, this.asset);
}

class _AiReplayScreenState extends State<AiReplayScreen> {
  static const _choices = [
    _ReplayChoice(
      'Expectimax (best)',
      'assets/ai/replays/best_expectimax.json',
    ),
    _ReplayChoice('Trained value model', 'assets/ai/replays/best_learned.json'),
    _ReplayChoice('Greedy heuristic', 'assets/ai/replays/best_greedy.json'),
  ];

  int _choice = 0;
  AiReplay? _replay;
  Map<HexCoord, Color> _grid = {};
  int _position = 0;
  int _score = 0;
  bool _playing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _timer?.cancel();
    final raw = await rootBundle.loadString(_choices[_choice].asset);
    final replay = AiReplay.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (!mounted) return;
    setState(() {
      _replay = replay;
      _grid = {};
      _position = 0;
      _score = 0;
      _playing = false;
    });
  }

  void _apply(AiReplayStep step) {
    final piece = blockCrushHexPieceCatalog[step.piece];
    final anchor = HexCoord(step.anchorQ, step.anchorR);
    final color = GameColors.blockCrushColor(
      blockCrushHexColorIndex(step.piece),
    );
    HexGridLogic.place(_grid, piece.cells, anchor, color);
    final completed = HexGridLogic.findCompletedLines(_grid);
    HexGridLogic.clearCells(_grid, completed);
    _score = step.scoreAfter;
  }

  void _seek(int target) {
    final replay = _replay;
    if (replay == null) return;
    _grid = {};
    _score = 0;
    for (var i = 0; i < target; i++) {
      _apply(replay.steps[i]);
    }
    _position = target;
  }

  void _step() {
    final replay = _replay;
    if (replay == null || _position >= replay.steps.length) {
      _stop();
      return;
    }
    setState(() {
      _apply(replay.steps[_position]);
      _position++;
    });
  }

  void _togglePlayback() {
    if (_playing) {
      _stop();
      return;
    }
    if (_replay == null) return;
    if (_position == _replay!.steps.length) {
      setState(() => _seek(0));
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 140), (_) => _step());
  }

  void _stop() {
    _timer?.cancel();
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final replay = _replay;
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        backgroundColor: GameColors.background,
        title: const Text('AI Best Games'),
      ),
      body: SafeArea(
        child: replay == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<int>(
                      value: _choice,
                      isExpanded: true,
                      dropdownColor: GameColors.emptyCell,
                      items: [
                        for (var i = 0; i < _choices.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(_choices[i].label),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _choice = value);
                        _load();
                      },
                    ),
                  ),
                  Text(
                    'Score $_score / ${replay.score}  •  Move $_position / ${replay.steps.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.min(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final hexSize = size / (math.sqrt(3) * 9 + 1);
                        return Center(
                          child: CustomPaint(
                            size: Size.square(size),
                            painter: HexGridPainter(
                              boardCells: HexGridLogic.boardCells,
                              grid: _grid,
                              ghostCells: const {},
                              ghostValid: false,
                              hexSize: hexSize,
                              center: Offset(size / 2, size / 2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Slider(
                    value: _position.toDouble(),
                    max: replay.steps.length.toDouble(),
                    onChanged: (value) {
                      _stop();
                      setState(() => _seek(value.round()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Restart',
                          onPressed: () {
                            _stop();
                            setState(() => _seek(0));
                          },
                          icon: const Icon(Icons.replay),
                        ),
                        const SizedBox(width: 24),
                        FilledButton.icon(
                          onPressed: _togglePlayback,
                          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                          label: Text(_playing ? 'Pause' : 'Play'),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          tooltip: 'Next move',
                          onPressed: _position < replay.steps.length
                              ? _step
                              : null,
                          icon: const Icon(Icons.skip_next),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
