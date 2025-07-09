// lib/models/game_model.dart
class GameModel {
  final int id;
  final String date;
  final List<String> board; // 9 posiciones: 'X', 'O' o ''
  final int duration;
  final int userId;
  final bool finished;

  GameModel({
    required this.id,
    required this.date,
    required this.board,
    required this.duration,
    required this.userId,
    required this.finished,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'board': board.join(','),
    'duration': duration,
    'userId': userId,
    'finished': finished ? 1 : 0,
  };

  factory GameModel.fromMap(Map<String, dynamic> map) => GameModel(
    id: map['id'],
    date: map['date'],
    board: (map['board'] as String).split(','),
    duration: map['duration'],
    userId: map['userId'],
    finished: map['finished'] == 1,
  );
}

extension GameModelCopy on GameModel {
  GameModel copyWith({
    int? id,
    String? date,
    List<String>? board,
    int? duration,
    int? userId,
    bool? finished,
  }) {
    return GameModel(
      id: id ?? this.id,
      date: date ?? this.date,
      board: board ?? this.board,
      duration: duration ?? this.duration,
      userId: userId ?? this.userId,
      finished: finished ?? this.finished,
    );
  }
}

