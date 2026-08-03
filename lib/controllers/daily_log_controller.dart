import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/services/daily_log_service.dart';
import 'package:project_granith/services/storage_asset_service.dart';
import 'package:project_granith/utils/image_upload_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyLogController extends ChangeNotifier {
  static const _bucket = 'project-images';

  final DailyLogService _service;
  final StorageAssetService _storageAssets = StorageAssetService();

  DailyLogController({DailyLogService? service, Object? storage})
    : _service = service ?? DailyLogService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DailyLogModel> _logs = [];
  List<DailyLogModel> get logs => _logs;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadLogs() async {
    _setLoading(true);
    try {
      _logs = await _service.getRecentLogs(limit: 200);
    } catch (e) {
      debugPrint('Erro ao carregar logs: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signLog(DailyLogModel log) async {
    _setLoading(true);
    try {
      await _service.signLogAsCurrentCoordinator(log);
      await loadLogs();
    } catch (e) {
      debugPrint('Erro ao assinar diario: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveLogWithPhotos(
    DailyLogModel log,
    List<XFile> newPhotos,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uploadedUrls =
          log.photoUrls.map(_storageAssets.normalizeForPersistence).toList();

      for (final photo in newPhotos) {
        try {
          final validated = ImageUploadValidator.validate(
            await photo.readAsBytes(),
          );
          final baseName = _sanitizeFileName(
            photo.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
          );
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_$baseName.'
              '${validated.extension}';
          final path = '${log.projectId}/daily-logs/$fileName';

          await AppSupabase.client.storage
              .from(_bucket)
              .uploadBinary(
                path,
                validated.bytes,
                fileOptions: FileOptions(
                  contentType: validated.contentType,
                  upsert: true,
                ),
              );

          uploadedUrls.add(path);
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
}
