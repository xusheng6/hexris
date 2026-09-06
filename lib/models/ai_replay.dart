class AiReplayStep {
  final int piece;
  final int anchorQ;
  final int anchorR;
  final int scoreAfter;
  final int lines;

  const AiReplayStep({
    required this.piece,
    required this.anchorQ,
    required this.anchorR,
    required this.scoreAfter,
    required this.lines,
  });

  factory AiReplayStep.fromJson(Map<String, dynamic> json) {
    final anchor = json['anchor'] as List<dynamic>;
    return AiReplayStep(
      piece: json['piece'] as int,
      anchorQ: anchor[0] as int,
      anchorR: anchor[1] as int,
      scoreAfter: json['scoreAfter'] as int,
      lines: json['lines'] as int,
    );
  }
}

class AiReplay {
  final String agent;
  final int seed;
  final int score;
  final List<AiReplayStep> steps;

  const AiReplay({
    required this.agent,
    required this.seed,
    required this.score,
    required this.steps,
  });

  factory AiReplay.fromJson(Map<String, dynamic> json) => AiReplay(
    agent: json['agent'] as String,
    seed: json['seed'] as int,
    score: json['score'] as int,
    steps: (json['steps'] as List<dynamic>)
        .map((step) => AiReplayStep.fromJson(step as Map<String, dynamic>))
        .toList(growable: false),
  );
}
