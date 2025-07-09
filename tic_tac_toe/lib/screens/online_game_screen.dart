import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OnlineGameScreen extends StatelessWidget {
  const OnlineGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final gameId = args['gameId'] as String;
    final myOnlineId = args['myOnlineId'] as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Juego en Línea')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('online_games')
            .doc(gameId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Juego no encontrado'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final board = List<String>.from(data['board'] ?? List.filled(9, ''));
          final turn = data['turn'] as String? ?? 'X';
          final winner = data['winner'];
          final status = data['status'] as String? ?? 'playing';
          final playerX = data['playerX'].toString();
          final playerO = data['playerO'].toString();

          final isMyTurn =
              (myOnlineId == playerX && turn == 'X') ||
              (myOnlineId == playerO && turn == 'O');

          return Column(
            children: [
              const SizedBox(height: 16),
              Text(
                status == 'finished'
                    ? (winner != null ? 'Ganador: $winner' : 'Empate')
                    : isMyTurn
                    ? '🎮 ¡Tu turno! ($turn)'
                    : '⏳ Esperando al oponente...',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final symbol = board[index];
                    return GestureDetector(
                      onTap: isMyTurn && symbol == '' && status == 'playing'
                          ? () async {
                              board[index] = turn;
                              final newTurn = turn == 'X' ? 'O' : 'X';
                              final newWinner = _checkWinner(board);

                              await FirebaseFirestore.instance
                                  .collection('online_games')
                                  .doc(gameId)
                                  .update({
                                    'board': board,
                                    'turn': newWinner == null ? newTurn : turn,
                                    'winner': newWinner,
                                    'status':
                                        newWinner != null || !board.contains('')
                                        ? 'finished'
                                        : 'playing',
                                  });
                            }
                          : null,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 48,
                              color: symbol == 'X' ? Colors.blue : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (status == 'finished')
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Volver al menú'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Revisa si hay un ganador
  String? _checkWinner(List<String> board) {
    const wins = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var combo in wins) {
      final a = combo[0], b = combo[1], c = combo[2];
      if (board[a] != '' && board[a] == board[b] && board[b] == board[c]) {
        return board[a];
      }
    }
    return null;
  }
}
