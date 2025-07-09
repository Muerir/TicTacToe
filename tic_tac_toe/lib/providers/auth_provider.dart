// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/local_db_service.dart';

final authProvider = StateNotifierProvider<AuthController, UserModel?>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<UserModel?> {
  AuthController() : super(null);

  Future<String?> register(String username, String email, String password) async {
    final existing = await LocalDBService.getUserByEmail(email);
    if (existing != null) return 'Correo ya registrado';

    final newUser = UserModel(id: 0, username: username, email: email, password: password);
    await LocalDBService.insertUser(newUser);
    final user = await LocalDBService.getUserByEmail(email);
    state = user;
    return null;
  }

  Future<String?> login(String email, String password) async {
    final user = await LocalDBService.validateUser(email, password);
    if (user != null) {
      state = user;
      return null;
    }
    return 'Credenciales inválidas';
  }

  void logout() {
    state = null;
  }
}
