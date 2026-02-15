import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/auth_service.dart';


class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();
  
  UserModel? _currentUserModel;
  UserModel? get user => _currentUserModel;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthController() {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _service.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Agora o método fetchUserData existe fisicamente no AuthService
        _currentUserModel = await _service.fetchUserData(firebaseUser.uid);
      } else {
        _currentUserModel = null;
      }
      
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> logout() async {
    await _service.signOut();
    _currentUserModel = null;
    notifyListeners();
  }
}