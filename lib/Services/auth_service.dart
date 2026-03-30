import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, kDebugMode, TargetPlatform, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/user_model.dart';

/// TIPO: Service
/// CAMADA: Infrastructure
/// FUNÇÃO: Lógica de comunicação com a infraestrutura do Firebase.
/// RESPEITA: SRP (Single Responsibility Principle).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  late final GoogleSignIn? _googleSignIn;

  AuthService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    } else {
      _googleSignIn = null;
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// BUSCA DADOS DO UTILIZADOR (Resolve o erro 'undefined_method')
  Future<UserModel?> fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar dados do utilizador no Firestore: $e');
      return null;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) throw Exception('Login cancelado');

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        await _checkAndSetupUser(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _checkAndSetupUser(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    final Map<String, dynamic> userData = {
      'email': user.email,
      'displayName': user.displayName,
      'lastLogin': FieldValue.serverTimestamp(),
      'photoUrl': user.photoURL,
    };

    if (doc.exists) {
      await userRef.update(userData);
    } else {
      await userRef.set({
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'ativo',
        'permissions': [],
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb && _googleSignIn != null) {
      await _googleSignIn.signOut();
    }
  }
}

/// TIPO: Exception Custom
class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException({required this.code, required this.message});
  @override
  String toString() => message;
}