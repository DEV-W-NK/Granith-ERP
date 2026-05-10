import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/services/auth_service.dart';

class DailyLogService {
  static const _table = 'daily_logs';
  static const _employeesTable = 'employees';

  final AuthService _authService;

  DailyLogService({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<void> saveLog(DailyLogModel log) async {
    if (log.isSigned) {
      throw const DailyLogSignatureException(
        'Diario assinado nao pode ser editado.',
      );
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final user = _authService.currentUser;
      final data = DbValue.normalizeMap({
        ...log.toMap(),
        if (log.createdByUserId.isEmpty && user != null)
          'createdByUserId': user.id,
        'updatedAt': now,
      });

      if (log.id.isEmpty) {
        await AppSupabase.client.from(_table).insert({
          ...data,
          'createdAt': now,
        });
      } else {
        await AppSupabase.client.from(_table).update(data).eq('id', log.id);
      }
    } catch (e) {
      throw Exception('Erro ao salvar diario: $e');
    }
  }

  Future<void> signLogAsCurrentCoordinator(DailyLogModel log) async {
    if (log.isSigned) {
      throw const DailyLogSignatureException('Este diario ja foi assinado.');
    }

    final signer = await resolveCurrentSigner(log);
    if (signer == null) {
      throw const DailyLogSignatureException(
        'Somente o coordenador responsavel ou uma conta administrativa pode assinar o diario.',
      );
    }

    await signLog(
      log,
      signedByCoordinatorId: signer.employeeId,
      signedByCoordinatorName: signer.name,
      allowMissingCoordinatorId: signer.isAdmin,
    );
  }

  Future<DailyLogSigner?> resolveCurrentSigner(DailyLogModel log) async {
    final user = _authService.currentUser;
    if (user == null) {
      return null;
    }

    final userId = _readString(user, 'id');
    final userEmail = _readString(user, 'email').trim().toLowerCase();
    final profile =
        userId.trim().isEmpty ? null : await _authService.fetchUserData(userId);
    final employee = await _findEmployeeByEmail(userEmail);

    if (profile?.isAdmin == true) {
      return DailyLogSigner(
        employeeId: employee?['id']?.toString(),
        name:
            profile?.displayName?.trim().isNotEmpty == true
                ? profile!.displayName!
                : employee?['name']?.toString().trim().isNotEmpty == true
                ? employee!['name'].toString()
                : userEmail.isNotEmpty
                ? userEmail
                : 'Administrador',
        isAdmin: true,
      );
    }

    final coordinatorId = log.coordinatorId?.trim();
    if (coordinatorId == null || coordinatorId.isEmpty) {
      return null;
    }

    if (userId == coordinatorId) {
      return DailyLogSigner(
        employeeId: coordinatorId,
        name: log.coordinatorName ?? userEmail,
      );
    }

    if (userEmail.isEmpty) {
      return null;
    }

    if (employee == null) {
      return null;
    }

    final data = Map<String, dynamic>.from(employee);
    final employeeId = data['id']?.toString();
    if (employeeId != coordinatorId) {
      return null;
    }

    return DailyLogSigner(
      employeeId: employeeId!,
      name:
          data['name']?.toString().trim().isNotEmpty == true
              ? data['name'].toString()
              : log.coordinatorName ?? userEmail,
    );
  }

  Future<Map<String, dynamic>?> _findEmployeeByEmail(String email) async {
    if (email.isEmpty) {
      return null;
    }

    final employee =
        await AppSupabase.client
            .from(_employeesTable)
            .select('id,name,email')
            .ilike('email', email)
            .maybeSingle();

    return employee == null ? null : Map<String, dynamic>.from(employee);
  }

  Future<void> signLog(
    DailyLogModel log, {
    String? signedByCoordinatorId,
    String? signedByCoordinatorName,
    bool allowMissingCoordinatorId = false,
  }) async {
    if (log.id.trim().isEmpty) {
      throw Exception('ID do diario e obrigatorio para assinatura');
    }

    try {
      final now = DateTime.now().toUtc();
      final data = DbValue.normalizeMap({
        'status': LogStatus.signed.name,
        'signedAt': now,
        'signedByCoordinatorId':
            allowMissingCoordinatorId
                ? signedByCoordinatorId
                : signedByCoordinatorId ?? log.coordinatorId,
        'signedByCoordinatorName':
            signedByCoordinatorName ?? log.coordinatorName,
        'updatedAt': now,
      });

      await AppSupabase.client.from(_table).update(data).eq('id', log.id);
    } catch (e) {
      throw Exception('Erro ao assinar diario: $e');
    }
  }

  Future<List<DailyLogModel>> getRecentLogs({int limit = 20}) async {
    try {
      final response = await AppSupabase.client
          .from(_table)
          .select()
          .order('date', ascending: false)
          .limit(limit);

      return (response as List).map((row) => _fromRow(row as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DailyLogModel>> getSignedLogsForProjects(
    Iterable<String> projectIds, {
    int limit = 100,
  }) async {
    final ids =
        projectIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
    if (ids.isEmpty) {
      return <DailyLogModel>[];
    }

    try {
      final response = await AppSupabase.client
          .from(_table)
          .select()
          .inFilter('projectId', ids)
          .eq('status', LogStatus.signed.name)
          .order('date', ascending: false)
          .limit(limit);

      return (response as List).map((row) => _fromRow(row as Map)).toList();
    } catch (e) {
      return <DailyLogModel>[];
    }
  }

  Stream<List<DailyLogModel>> watchByProject(String projectId) {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('projectId', projectId)
        .order('date', ascending: false)
        .map((rows) => rows.map((row) => _fromRow(row)).toList());
  }

  DailyLogModel _fromRow(Map<dynamic, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    return DailyLogModel.fromMap(data, data['id'] as String? ?? '');
  }

  String _readString(dynamic object, String field) {
    try {
      final value = object.toJson()[field];
      if (value != null) return value.toString();
    } catch (_) {
      // Supabase User exposes fields directly; tests may use plain fakes.
    }

    try {
      switch (field) {
        case 'id':
          return object.id?.toString() ?? '';
        case 'email':
          return object.email?.toString() ?? '';
      }
    } catch (_) {
      return '';
    }

    return '';
  }
}

class DailyLogSigner {
  final String? employeeId;
  final String name;
  final bool isAdmin;

  const DailyLogSigner({
    required this.employeeId,
    required this.name,
    this.isAdmin = false,
  });
}

class DailyLogSignatureException implements Exception {
  final String message;

  const DailyLogSignatureException(this.message);

  @override
  String toString() => message;
}
