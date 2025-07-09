// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tic_tac_toe/providers/game_provider.dart';
import 'package:tic_tac_toe/screens/saved_games_screen.dart';
import 'package:uuid/uuid.dart';
import '../services/online_service.dart';
import '../screens/online_users_screen.dart';
import '../providers/auth_provider.dart';
import 'game_screen.dart';
import 'login_screen.dart';
import '../services/local_db_service.dart';
import '../models/user_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    checkSavedGame();
  }

  Future<void> checkSavedGame() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final game = await LocalDBService.getIncompleteGame(user.id);

    if (game != null) {
      ref.read(currentGameProvider.notifier).state = game;
      setState(() => hasSavedGame = true);
    } else {
      setState(() => hasSavedGame = false);
    }
  }

  void logout() {
    ref.read(authProvider.notifier).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    checkSavedGame();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) return const SizedBox.shrink(); // Seguridad

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.username),
              accountEmail: Text(user.email),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasSavedGame)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  ).then((result) {
                    if (result == true) checkSavedGame();
                  });
                },
                child: const Text('Continuar'),
              ),
            ElevatedButton(
              onPressed: () {
                ref.read(currentGameProvider.notifier).state =
                    null; // Reiniciar el juego anterior
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                ).then((result) {
                  if (result == true) {
                    checkSavedGame(); // Vuelve a verificar si regresamos de GameScreen
                  }
                });
              },
              child: const Text('Juego Nuevo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedGamesScreen()),
                );
              },
              child: const Text('Ver partidas guardadas'),
            ),
            ElevatedButton(
              onPressed: () async {
                final connectivityResult = await Connectivity()
                    .checkConnectivity();
                if (connectivityResult == ConnectivityResult.none) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sin conexión a internet')),
                  );
                  return;
                }

                final currentUser = ref.read(authProvider);
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario no cargado')),
                  );
                  return;
                }

                // 1. Si no tiene onlineId, lo generamos y actualizamos el estado global
                if (currentUser.onlineId == null) {
                  final updatedUser = currentUser.copyWith(
                    onlineId: const Uuid().v4(), // Usa uuid: ^4.0.0
                  );

                  await LocalDBService.updateUser(updatedUser);
                  ref.read(authProvider.notifier).state = updatedUser;
                }

                final refreshedUser = ref.read(authProvider)!;

                // 2. Registramos al usuario en línea con su onlineId
                await OnlineService.registerOnlineUser(refreshedUser);

                if (!context.mounted) return;

                // 3. Vamos a la pantalla con seguridad de que el usuario tiene su onlineId
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnlineUsersScreen()),
                );
              },
              child: const Text('Jugar Online'),
            ),
          ],
        ),
      ),
    );
  }
}
