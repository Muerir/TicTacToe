// lib/providers/game_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';

final currentGameProvider = StateProvider<GameModel?>((ref) => null);
