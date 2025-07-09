// lib/screens/game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/animated_o.dart';
import '../widgets/animated_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../services/local_db_service.dart';
import 'package:intl/intl.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  List<String> board = List.filled(9, ''); // '', 'X' o 'O'
  bool xTurn = true;
  Timer? _timer;
  int seconds = 0;
  bool gameEnded = false;

  void startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => seconds++);
    });
  }

  void onTap(int index) async {
    if (board[index] != '' || gameEnded) return;
    startTimer();
    setState(() {
      board[index] = xTurn ? 'X' : 'O';
      xTurn = !xTurn;
    });

    final game = ref.read(currentGameProvider);
    if (game == null) {
      final user = ref.read(authProvider)!;
      final newGame = GameModel(
        id: 0,
        date: DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
        board: board,
        duration: seconds,
        userId: user.id,
        finished: false,
      );
      final id = await LocalDBService.insertGame(newGame);
      ref.read(currentGameProvider.notifier).state = newGame.copyWith(
        id: id,
      ); // usamos copyWith que puedes agregar
    } else {
      final updatedGame = game.copyWith(board: board, duration: seconds);
      ref.read(currentGameProvider.notifier).state = updatedGame;
      await LocalDBService.updateGame(updatedGame);
    }

    final winner = checkWinner();
    if (winner != null || !board.contains('')) {
      _timer?.cancel();
      gameEnded = true;

      // Marcar como finalizado
      final game = ref.read(currentGameProvider);
      if (game != null) {
        final finishedGame = game.copyWith(
          finished: true,
          duration: seconds,
          board: board,
        );
        ref.read(currentGameProvider.notifier).state = finishedGame;
        await LocalDBService.updateGame(finishedGame);
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(
            winner != null ? '¡Ganó ${winner == 'X' ? '❌' : '⭕'}!' : '¡Empate!',
          ),
          content: const Text('¿Volver al menú?'),
          actions: [
            TextButton(
              onPressed: () async {
                final game = ref.read(currentGameProvider);
                if (game != null && !game.finished) {
                  final updated = game.copyWith(
                    board: board,
                    duration: seconds,
                    finished: true,
                  );
                  await LocalDBService.updateGame(updated);
                }
                Navigator.pop(context); // cierra el diálogo
                Navigator.pop(context, true); // regresa a SavedGamesScreen
              },
              child: const Text('Volver'),
            ),
          ],
        ),
      );
    }
  }

  String? checkWinner() {
    final wins = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8], // Horizontales
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8], // Verticales
      [0, 4, 8],
      [2, 4, 6], // Diagonales
    ];
    for (var combo in wins) {
      final a = combo[0], b = combo[1], c = combo[2];
      if (board[a] != '' && board[a] == board[b] && board[b] == board[c]) {
        return board[a];
      }
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget buildTile(int index) {
    final value = board[index];
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: value == 'X'
                ? AnimatedX(key: ValueKey(index))
                : value == 'O'
                ? AnimatedO(key: ValueKey(index))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final game = ref.read(currentGameProvider);
    if (game != null) {
      board = List.from(game.board); // Restaura la disposición del tablero
      seconds = game.duration; // Restaura el tiempo
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardSize = MediaQuery.of(context).size.width * 0.9;

    return PopScope(
      canPop: false, // evita que Flutter haga el pop automático
      onPopInvoked: (didPop) async {
        if (didPop) return; // si ya se hizo el pop, no hacemos nada

        final game = ref.read(currentGameProvider);
        if (game != null && !game.finished) {
          final updated = game.copyWith(board: board, duration: seconds);
          await LocalDBService.updateGame(updated);
        }

        Navigator.pop(
          context,
          true,
        ); // hacemos pop manual y devolvemos resultado
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Juego Local')),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Turno de: ${xTurn ? '❌' : '⭕'}',
              style: const TextStyle(fontSize: 24),
            ),
            Text('Tiempo: $seconds s', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    itemCount: 9,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                    itemBuilder: (_, i) => buildTile(i),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final game = ref.read(currentGameProvider);
                if (game != null && !game.finished) {
                  final updated = game.copyWith(
                    board: board,
                    duration: seconds,
                  );
                  await LocalDBService.updateGame(updated);
                }
                Navigator.pop(
                  context,
                  true,
                ); // Devuelve algo al HomeScreen o lista
              },
              child: const Text('Volver al menú'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
