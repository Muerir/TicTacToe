import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/online_service.dart';
import '../providers/auth_provider.dart';

class OnlineUsersScreen extends ConsumerWidget {
  const OnlineUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);

    if (currentUser == null || currentUser.onlineId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Jugadores en línea')),

      // 🔁 Stream para detectar si me han desafiado
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('online_games')
            .where('playerO', isEqualTo: currentUser.onlineId)
            .where('status', isEqualTo: 'playing')
            .snapshots(),
        builder: (context, gameSnapshot) {
          if (gameSnapshot.hasData && gameSnapshot.data!.docs.isNotEmpty) {
            final gameDoc = gameSnapshot.data!.docs.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(
                context,
                '/online_game',
                arguments: {
                  'gameId': gameDoc.id,
                  'myOnlineId': currentUser.onlineId!,
                },
              );
            });

            // Evita mostrar la lista mientras hace push
            return const Center(child: CircularProgressIndicator());
          }

          // 🔁 Si no hay partida activa, mostrar lista de usuarios disponibles
          return StreamBuilder<List<UserModel>>(
            stream: OnlineService.getAvailableUsers(currentUser.onlineId!),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }

              final users = userSnapshot.data ?? [];

              if (users.isEmpty) {
                return const Center(
                  child: Text('No hay jugadores disponibles'),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () async {
                      final gameId = await OnlineService.createOnlineGame(
                        playerXId: currentUser.onlineId!,
                        playerOId: user.onlineId!,
                      );

                      await OnlineService.markUserUnavailable(
                        currentUser.onlineId!,
                      );
                      await OnlineService.markUserUnavailable(user.onlineId!);

                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          '/online_game',
                          arguments: {
                            'gameId': gameId,
                            'myOnlineId': currentUser.onlineId!,
                          },
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
