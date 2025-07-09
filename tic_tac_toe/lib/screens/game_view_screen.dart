// lib/screens/game_view_screen.dart
import 'package:flutter/material.dart';

class GameViewScreen extends StatelessWidget {
  final List<String> board;
  final String date;
  final int duration;
  final bool finished;

  const GameViewScreen({
    super.key,
    required this.board,
    required this.date,
    required this.duration,
    required this.finished,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partida guardada')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Fecha: $date'),
          Text('Duración: ${duration}s'),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              itemCount: 9,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (_, index) {
                final symbol = board[index];
                return Center(
                  child: Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 40,
                      color: symbol == 'X' ? Colors.red : Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(finished ? 'Estado: Finalizado' : 'Estado: Incompleto'),
        ],
      ),
    );
  }
}
