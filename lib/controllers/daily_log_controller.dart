import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/services/daily_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyLogController extends ChangeNotifier {
  static const _bucket = 'project-images';

  final DailyLogService _service;

  DailyLogController({DailyLogService? service, Object? storage})
    : _service = service ?? DailyLogService();

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

  Future<bool> saveLogWithPhotos(
    DailyLogModel log,
    List<XFile> newPhotos,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uploadedUrls = [...log.photoUrls];

      for (final photo in newPhotos) {
        try {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(photo.name)}';
          final path = 'daily_logs/${log.projectId}/$fileName';

          await AppSupabase.client.storage
              .from(_bucket)
              .uploadBinary(
                path,
                await photo.readAsBytes(),
                fileOptions: FileOptions(
                  contentType: _contentTypeFor(photo.name),
                  upsert: true,
                ),
              );

          uploadedUrls.add(
            AppSupabase.client.storage.from(_bucket).getPublicUrl(path),
          );
        } catch (e) {
          debugPrint('Erro no upload da imagem ${photo.name}: $e');
        }
      }

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
        coordinatorId: log.coordinatorId,
        coordinatorName: log.coordinatorName,
        signatureRequestedAt: log.signatureRequestedAt,
        signedAt: log.signedAt,
        signedByCoordinatorId: log.signedByCoordinatorId,
        signedByCoordinatorName: log.signedByCoordinatorName,
      );

      await _service.saveLog(updatedLog);
      await loadLogs();

      return true;
    } catch (e) {
      debugPrint('Erro geral ao salvar diario: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
