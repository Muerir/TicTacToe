import 'package:uuid/uuid.dart';

class UserModel {
  final int id; // ID local en SQLite
  final String username;
  final String email;
  final String password;
  final String? onlineId; // ID único para Firestore

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.onlineId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'onlineId': onlineId,
    };
  }

  factory UserModel.fromLocalMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      onlineId: map['onlineId'],
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String idFromFirestore) {
    return UserModel(
      id: 0,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: '',
      onlineId: idFromFirestore,
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? onlineId,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      onlineId: onlineId ?? this.onlineId,
    );
  }
}
