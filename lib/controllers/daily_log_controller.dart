import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/services/daily_log_service.dart';

class DailyLogController extends ChangeNotifier {
  final DailyLogService _service = DailyLogService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DailyLogModel> _logs = [];
  List<DailyLogModel> get logs => _logs;

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _logs = await _service.getRecentLogs();
    } catch (e) {
      debugPrint('Erro ao carregar logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método que faltava no seu código anterior
  Future<bool> saveLogWithPhotos(DailyLogModel log, List<XFile> newPhotos) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<String> uploadedUrls = [...log.photoUrls];

      // 1. Upload das novas fotos
      if (newPhotos.isNotEmpty) {
        for (var photo in newPhotos) {
          try {
            String fileName = '${DateTime.now().millisecondsSinceEpoch}_${photo.name}';
            Reference ref = _storage.ref().child('daily_logs/${log.projectId}/$fileName');
            
            if (kIsWeb) {
               await ref.putData(await photo.readAsBytes());
            } else {
               await ref.putFile(File(photo.path));
            }
            
            String downloadUrl = await ref.getDownloadURL();
            uploadedUrls.add(downloadUrl);
          } catch (e) {
            debugPrint('Erro no upload da imagem ${photo.name}: $e');
            // Continua para a próxima imagem mesmo se uma falhar
          }
        }
      }

      // 2. Atualiza modelo com URLs
      final updatedLog = DailyLogModel(
        id: log.id,
        projectId: log.projectId,
        projectName: log.projectName,
        date: log.date,
        weatherMorning: log.weatherMorning,
        weatherAfternoon: log.weatherAfternoon,
        manpower: log.manpower,
        activitiesDescription: log.activitiesDescription,
        impediments: log.impediments,
        photoUrls: uploadedUrls,
        createdByUserId: log.createdByUserId,
        status: log.status,
      );

      // 3. Salva no Firestore
      await _service.saveLog(updatedLog);
      
      // 4. Atualiza lista local
      await loadLogs();
      
      return true;
    } catch (e) {
      debugPrint('Erro geral ao salvar diário: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}