import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/usage_stats_model.dart';

class UsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UsageStatsModel> getCurrentUsage(String tenantId) async {
    try {
      final docId = '${tenantId}_${DateTime.now().month}_${DateTime.now().year}';
      // Tenta buscar documento real (se existir)
      // final doc = await _firestore.collection('usage_stats').doc(docId).get();
      // if (doc.exists && doc.data() != null) {
      //   return UsageStatsModel.fromMap(doc.data()!);
      // }

      // RETORNA DADOS MOCKADOS (Para você testar a tela agora)
      await Future.delayed(const Duration(milliseconds: 800));
      return UsageStatsModel(
        tenantId: tenantId,
        totalReads: 45200,
        totalWrites: 1250,
        storageUsedMB: 450.5,
        aiRequests: 12,
        periodStart: DateTime(DateTime.now().year, DateTime.now().month, 1),
        periodEnd: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erro ao buscar dados de consumo: $e');
    }
  }
}