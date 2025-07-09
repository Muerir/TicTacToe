// lib/screens/saved_games_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toe/providers/game_provider.dart';
import 'package:tic_tac_toe/screens/game_screen.dart';
import 'package:tic_tac_toe/screens/game_view_screen.dart';
import '../services/local_db_service.dart';
import '../models/game_model.dart';
import '../providers/auth_provider.dart';

class SavedGamesScreen extends ConsumerStatefulWidget {
  const SavedGamesScreen({super.key});

  @override
  ConsumerState<SavedGamesScreen> createState() => _SavedGamesScreenState();
}

class _SavedGamesScreenState extends ConsumerState<SavedGamesScreen> {
  List<GameModel> games = [];

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    final loaded = await LocalDBService.getGamesForUser(user.id);
    setState(() {
      games = loaded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partidas Guardadas')),
        body: const Center(child: Text('No hay partidas aún')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Partidas Guardadas')),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return ListTile(
            onTap: () {
              if (game.finished) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameViewScreen(
                      board: game.board,
                      date: game.date,
                      duration: game.duration,
                      finished: game.finished,
                    ),
                  ),
                );
              } else {
                ref.read(currentGameProvider.notifier).state = game;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                ).then((result) {
                  if (result == true) {
                    _loadGames(); // Recargar datos al volver
                  }
                });
              }
            },
            leading: Icon(
              game.finished ? Icons.check_circle : Icons.play_circle_fill,
            ),
            title: Text('Partida del ${game.date}'),
            subtitle: Text('Duración: ${game.duration}s'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Eliminar partida?'),
                    content: const Text('Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await LocalDBService.deleteGame(game.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Partida eliminada')),
                  );
                  _loadGames(); // Recargar después de borrar
                }
              },
            ),
          );
        },
      ),
    );
  }
}
