import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/services/auth_service.dart';

class DailyLogService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  DailyLogService({FirebaseFirestore? firestore, AuthService? authService}) : _firestore = firestore ?? FirebaseFirestore.instance, _authService = authService ?? AuthService();

  CollectionReference get _logsCollection => _firestore.collection('daily_logs');

  Future<void> saveLog(DailyLogModel log) async {
    try {
      final user = _authService.currentUser;
      // if (user == null) throw Exception('Usuário não autenticado'); // Descomentar em produção

      final logData = {
        ...log.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (log.id.isEmpty) {
        await _logsCollection.add({
          ...logData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _logsCollection.doc(log.id).update(logData);
      }
    } catch (e) {
      throw Exception('Erro ao salvar diário: $e');
    }
  }

  Future<List<DailyLogModel>> getRecentLogs({int limit = 20}) async {
    try {
      final snapshot = await _logsCollection
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return DailyLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar logs: $e');
      return [];
    }
  }
}