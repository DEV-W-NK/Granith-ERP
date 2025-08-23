import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn? _googleSignIn;

  AuthService() {
    _initializeEmulators();
    _initializeGoogleSignIn();
  }

  /// Configurar emulators em modo debug
  void _initializeEmulators() {
    if (kDebugMode) {
      try {
        // Auth Emulator - porta configurada no firebase.json
        _auth.useAuthEmulator('localhost', 9199);
        print('🔥 Auth Emulator ativo em localhost:9199');
      } catch (e) {
        print('Auth Emulator já configurado ou erro: $e');
      }

      try {
        // Firestore Emulator - se estiver usando
        _firestore.useFirestoreEmulator('localhost', 8080);
        print('🔥 Firestore Emulator ativo em localhost:8080');
      } catch (e) {
        print('Firestore Emulator já configurado ou erro: $e');
      }
    }
  }

  void _initializeGoogleSignIn() {
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    } else {
      _googleSignIn = null; // Para web, usamos signInWithPopup
    }
  }

  // Getter para o usuário atual
  User? get currentUser => _auth.currentUser;

  // Stream para mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verificar se está rodando na web
  bool get isWeb => kIsWeb;

  /// Login com Google
  /// Funciona tanto para web (popup) quanto para mobile
  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        // Login via popup para web
        final provider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // Login via GoogleSignIn para mobile
        final googleUser = await _googleSignIn?.signIn();
        
        if (googleUser == null) {
          throw const AuthException(
            code: 'ERROR_ABORTED_BY_USER',
            message: 'Login cancelado pelo usuário',
          );
        }
        
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user!;
      print('🔐 Usuário autenticado: ${user.email} (UID: ${user.uid})');
      await _checkAndSetupUser(user);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Erro de autenticação: ${e.code} - ${e.message}');
      throw AuthException(code: e.code, message: _parseAuthError(e));
    } catch (e) {
      print('❌ Erro inesperado na autenticação: $e');
      if (e is AuthException) rethrow;
      throw AuthException(
        code: 'unknown_error',
        message: 'Erro inesperado: ${e.toString()}',
      );
    }
  }

  /// Verificar e configurar usuário no Firestore
  /// Aceita qualquer email do Google
  Future<void> _checkAndSetupUser(User user) async {
    try {
      // Configurar ou atualizar usuário no Firestore
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();
      
      final userData = {
        'email': user.email,
        'displayName': user.displayName,
        'lastLogin': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL,
      };

      if (doc.exists) {
        // Usuário já existe - apenas atualizar dados
        await userRef.set(userData, SetOptions(merge: true));
        print('📝 Dados do usuário atualizados no Firestore');
      } else {
        // Novo usuário - criar com dados completos
        await userRef.set({
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'ativo',
        });
        print('👤 Novo usuário criado no Firestore');
      }
    } catch (e) {
      print('❌ Erro ao configurar usuário no Firestore: $e');
      // Não propagar o erro, pois a autenticação foi bem-sucedida
    }
  }

  /// Fazer logout completo
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      print('👋 Logout realizado com sucesso');
    } catch (e) {
      print('❌ Erro no logout: $e');
      throw AuthException(
        code: 'signout_error',
        message: 'Erro ao fazer logout: ${e.toString()}',
      );
    }
  }

  /// Obter dados do usuário do Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Erro ao buscar dados do usuário: $e');
      throw AuthException(
        code: 'firestore_error',
        message: 'Erro ao buscar dados do usuário: ${e.toString()}',
      );
    }
  }

  /// Stream dos dados do usuário do Firestore
  Stream<Map<String, dynamic>?> get userDataStream {
    final user = currentUser;
    if (user == null) return Stream.value(null);
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Atualizar dados do usuário no Firestore
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw const AuthException(
          code: 'no_user',
          message: 'Nenhum usuário logado',
        );
      }
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
      
      print('📝 Dados do usuário atualizados');
    } catch (e) {
      print('❌ Erro ao atualizar dados: $e');
      throw AuthException(
        code: 'update_error',
        message: 'Erro ao atualizar dados: ${e.toString()}',
      );
    }
  }

  /// Debug: Verificar token de autenticação
  Future<void> debugAuthToken() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('🔍 Debug: Nenhum usuário logado');
        return;
      }

      print('🔍 Debug Auth:');
      print('  - UID: ${user.uid}');
      print('  - Email: ${user.email}');
      print('  - Display Name: ${user.displayName}');
      
      final token = await user.getIdToken();
      print('  - Token presente: ${token?.isNotEmpty}');
      print('  - Token length: ${token?.length}');
      
      // Verificar se token é válido
      final tokenResult = await user.getIdTokenResult();
      print('  - Token válido até: ${tokenResult.expirationTime}');
      print('  - Claims: ${tokenResult.claims?.keys.toList()}');
      
    } catch (e) {
      print('❌ Erro no debug do token: $e');
    }
  }

  /// Parsing de erros de autenticação
  String _parseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'ERROR_ABORTED_BY_USER':
      case 'popup-closed-by-user':
        return 'Login cancelado pelo usuário.';
      case 'popup-blocked':
        return 'Popup bloqueado pelo navegador. Permita popups para este site.';
      case 'unauthorized-domain':
        return 'Domínio não autorizado para este projeto.';
      case 'operation-not-allowed':
        return 'Operação não permitida. Verifique a configuração do Firebase.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente em alguns minutos.';
      case 'account-exists-with-different-credential':
        return 'Esta conta já existe com um método de login diferente.';
      default:
        return 'Falha na autenticação: ${e.message ?? 'Erro desconhecido'}';
    }
  }

  /// Verificar se o usuário tem permissões específicas
  Future<bool> hasPermission(String permission) async {
    try {
      final userData = await getUserData();
      if (userData == null) return false;
      
      final permissions = userData['permissions'] as List<dynamic>? ?? [];
      return permissions.contains(permission);
    } catch (e) {
      print('❌ Erro ao verificar permissões: $e');
      return false;
    }
  }

  /// Verificar se o usuário está ativo
  Future<bool> isUserActive() async {
    try {
      final userData = await getUserData();
      if (userData == null) return false;
      
      return userData['status'] == 'ativo';
    } catch (e) {
      print('❌ Erro ao verificar status do usuário: $e');
      return false;
    }
  }

  /// Função de teste para verificar conectividade dos emuladores
  Future<void> testEmulatorConnection() async {
    try {
      print('🧪 === TESTE DE CONEXÃO AUTH/FIRESTORE ===');
      
      // Teste 1: Verificar se está usando emulador
      print('🔧 Modo Debug: $kDebugMode');
      
      // Teste 2: Verificar usuário atual
      final user = currentUser;
      if (user != null) {
        print('✅ Usuário logado: ${user.email}');
        await debugAuthToken();
      } else {
        print('⚠️ Nenhum usuário logado');
      }

      // Teste 3: Testar Firestore
      final testDoc = _firestore.collection('test').doc('connection');
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'emulator_connection',
      });
      
      final result = await testDoc.get();
      if (result.exists) {
        print('✅ Firestore funcionando');
        await testDoc.delete(); // Limpar teste
      }

    } catch (e) {
      print('❌ Erro no teste de conexão: $e');
      rethrow;
    }
  }
}

/// Classe personalizada para exceções de autenticação
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}