import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class OnlineService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> registerOnlineUser(UserModel user) async {
    try {
      final onlineId = user.onlineId;
      if (onlineId == null || onlineId.trim().isEmpty) {
        throw Exception('❌ onlineId es null o vacío');
      }

      final docRef = _db.collection('online_users').doc(onlineId);
      print('📤 Registrando usuario online con ID: $onlineId');

      await docRef.set({
        'username': user.username,
        'email': user.email,
        'available': true,
      }, SetOptions(merge: true));

      print('✅ Usuario registrado en línea correctamente');
    } catch (e) {
      print('🔥 Error en registerOnlineUser: $e');
      rethrow;
    }
  }

  static Stream<List<UserModel>> getAvailableUsers(String currentOnlineId) {
    return _db
        .collection('online_users')
        .where('available', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.id != currentOnlineId)
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<String> createOnlineGame({
    required String playerXId,
    required String playerOId,
  }) async {
    final doc = await _db.collection('online_games').add({
      'playerX': playerXId,
      'playerO': playerOId,
      'board': List.filled(9, ''),
      'turn': 'X',
      'winner': null,
      'status': 'playing',
    });

    return doc.id;
  }

  static Future<void> markUserUnavailable(String onlineId) async {
    final doc = _db.collection('online_users').doc(onlineId);
    await doc.update({'available': false});
  }

  static Future<void> removeOnlineUser(String onlineId) async {
    await _db.collection('online_users').doc(onlineId).delete();
  }
}
