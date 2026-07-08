import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectMeasurementProjection {
  final double netAmount;
  final double accumulatedGrossAmount;
  final double measurementPercentage;
  final double accumulatedPercentage;
  final double contractBalance;

  const ProjectMeasurementProjection({
    required this.netAmount,
    required this.accumulatedGrossAmount,
    required this.measurementPercentage,
    required this.accumulatedPercentage,
    required this.contractBalance,
  });

  factory ProjectMeasurementProjection.fromValues({
    required double contractValue,
    required double previousAccumulatedGross,
    required double grossAmount,
    required double discountAmount,
  }) {
    final normalizedContractValue =
        contractValue < 0 ? 0.0 : contractValue.toDouble();
    final normalizedGrossAmount =
        grossAmount < 0 ? 0.0 : grossAmount.toDouble();
    final normalizedDiscountAmount =
        discountAmount < 0
            ? 0.0
            : discountAmount.clamp(0, normalizedGrossAmount).toDouble();
    final netAmount =
        (normalizedGrossAmount - normalizedDiscountAmount)
            .clamp(0, double.infinity)
            .toDouble();
    final accumulatedGrossAmount =
        (previousAccumulatedGross + normalizedGrossAmount)
            .clamp(0, double.infinity)
            .toDouble();

    if (normalizedContractValue == 0) {
      return ProjectMeasurementProjection(
        netAmount: netAmount,
        accumulatedGrossAmount: accumulatedGrossAmount,
        measurementPercentage: 0,
        accumulatedPercentage: 0,
        contractBalance: 0,
      );
    }

    return ProjectMeasurementProjection(
      netAmount: netAmount,
      accumulatedGrossAmount: accumulatedGrossAmount,
      measurementPercentage:
          (normalizedGrossAmount / normalizedContractValue * 100)
              .clamp(0, 100)
              .toDouble(),
      accumulatedPercentage:
          (accumulatedGrossAmount / normalizedContractValue * 100)
              .clamp(0, 100)
              .toDouble(),
      contractBalance:
          (normalizedContractValue - accumulatedGrossAmount)
              .clamp(0, double.infinity)
              .toDouble(),
    );
  }
}

class ProjectMeasurementService {
  static const String _table = 'project_measurements';
  static const String _projectsTable = 'projects';

  SupabaseClient get _client => AppSupabase.client;

  Future<List<ProjectMeasurement>> getMeasurements({String? projectId}) async {
    try {
      var query = _client.from(_table).select();
      if (projectId != null && projectId.trim().isNotEmpty) {
        query = query.eq('projectId', projectId.trim());
      }

      final response = await query
          .order('sequence', ascending: true)
          .order('measurementDate', ascending: true)
          .order('createdAt', ascending: true);

      return (response as List).map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        return ProjectMeasurement.fromMap((data['id'] ?? '').toString(), data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar medicoes: $e');
    }
  }

  Future<String> addMeasurement(ProjectMeasurement measurement) async {
    _validateMeasurement(measurement);
    final project = await _getProjectSnapshot(measurement.projectId);
    final existing = await getMeasurements(projectId: measurement.projectId);
    final sequence =
        existing.isEmpty
            ? 1
            : existing
                    .map((item) => item.sequence)
                    .reduce((a, b) => a > b ? a : b) +
                1;
    final title =
        measurement.title.trim().isEmpty
            ? '${sequence}a medicao'
            : measurement.title.trim();
    final now = DateTime.now();

    final payload = DbValue.normalizeMap({
      'projectId': measurement.projectId,
      'project_id': measurement.projectId,
      'projectName': project['name'],
      'project_name': project['name'],
      'projectClient': project['client'],
      'project_client': project['client'],
      'title': title,
      'sequence': sequence,
      'status': measurement.status.name,
      'measurementDate': measurement.measurementDate,
      'measurement_date': measurement.measurementDate,
      'grossAmount': measurement.grossAmount,
      'gross_amount': measurement.grossAmount,
      'discountAmount': measurement.discountAmount,
      'discount_amount': measurement.discountAmount,
      'netAmount': 0,
      'net_amount': 0,
      'accumulatedGrossAmount': 0,
      'accumulated_gross_amount': 0,
      'measurementPercentage': 0,
      'measurement_percentage': 0,
      'accumulatedPercentage': 0,
      'accumulated_percentage': 0,
      'contractBalance': 0,
      'contract_balance': 0,
      'notes': measurement.notes.trim(),
      'createdAt': now,
      'created_at': now,
      'updatedAt': now,
      'updated_at': now,
    });

    final inserted =
        await _client.from(_table).insert(payload).select('id').single();

    await _recalculateProject(measurement.projectId);
    final id = (inserted['id'] ?? '').toString();
    _notifyMeasurementsChanged();
    return id;
  }

  Future<void> updateMeasurement(ProjectMeasurement measurement) async {
    if (measurement.id.trim().isEmpty) {
      throw Exception('ID da medicao e obrigatorio para atualizacao.');
    }

    _validateMeasurement(measurement);

    final current =
        await _client
            .from(_table)
            .select('projectId')
            .eq('id', measurement.id)
            .single();
    final previousProjectId = (current['projectId'] ?? '').toString();
    final project = await _getProjectSnapshot(measurement.projectId);
    final now = DateTime.now();

    final payload = DbValue.normalizeMap({
      'projectId': measurement.projectId,
      'project_id': measurement.projectId,
      'projectName': project['name'],
      'project_name': project['name'],
      'projectClient': project['client'],
      'project_client': project['client'],
      'title':
          measurement.title.trim().isEmpty
              ? '${measurement.sequence}a medicao'
              : measurement.title.trim(),
      'status': measurement.status.name,
      'measurementDate': measurement.measurementDate,
      'measurement_date': measurement.measurementDate,
      'grossAmount': measurement.grossAmount,
      'gross_amount': measurement.grossAmount,
      'discountAmount': measurement.discountAmount,
      'discount_amount': measurement.discountAmount,
      'notes': measurement.notes.trim(),
      'updatedAt': now,
      'updated_at': now,
    });

    await _client.from(_table).update(payload).eq('id', measurement.id);
    await _recalculateProject(measurement.projectId);
    if (previousProjectId.isNotEmpty &&
        previousProjectId != measurement.projectId) {
      await _recalculateProject(previousProjectId);
    }
    _notifyMeasurementsChanged();
  }

  Future<void> deleteMeasurement(String measurementId) async {
    if (measurementId.trim().isEmpty) {
      throw Exception('ID da medicao e obrigatorio para exclusao.');
    }

    final current =
        await _client
            .from(_table)
            .select('projectId')
            .eq('id', measurementId)
            .single();
    final projectId = (current['projectId'] ?? '').toString();

    await _client.from(_table).delete().eq('id', measurementId);

    if (projectId.isNotEmpty) {
      await _recalculateProject(projectId);
    }
    _notifyMeasurementsChanged();
  }

  Future<void> _recalculateProject(String projectId) async {
    final project = await _getProjectSnapshot(projectId);
    final contractValue = ((project['budget'] ?? 0) as num).toDouble();
    final rows = await getMeasurements(projectId: projectId);

    var accumulatedGross = 0.0;
    for (var index = 0; index < rows.length; index++) {
      final measurement = rows[index];
      final normalizedSequence = index + 1;
      final projection = ProjectMeasurementProjection.fromValues(
        contractValue: contractValue,
        previousAccumulatedGross: accumulatedGross,
        grossAmount: measurement.grossAmount,
        discountAmount: measurement.discountAmount,
      );
      accumulatedGross = projection.accumulatedGrossAmount;

      await _client
          .from(_table)
          .update(
            DbValue.normalizeMap({
              'sequence': normalizedSequence,
              'title':
                  measurement.title.trim().isEmpty
                      ? '${normalizedSequence}a medicao'
                      : measurement.title.trim(),
              'netAmount': projection.netAmount,
              'net_amount': projection.netAmount,
              'accumulatedGrossAmount': projection.accumulatedGrossAmount,
              'accumulated_gross_amount': projection.accumulatedGrossAmount,
              'measurementPercentage': projection.measurementPercentage,
              'measurement_percentage': projection.measurementPercentage,
              'accumulatedPercentage': projection.accumulatedPercentage,
              'accumulated_percentage': projection.accumulatedPercentage,
              'contractBalance': projection.contractBalance,
              'contract_balance': projection.contractBalance,
              'updatedAt': DateTime.now(),
              'updated_at': DateTime.now(),
            }),
          )
          .eq('id', measurement.id);
    }

    final latestMeasurement = rows.isEmpty ? null : rows.last;
    final lastProjection =
        rows.isEmpty
            ? const ProjectMeasurementProjection(
              netAmount: 0,
              accumulatedGrossAmount: 0,
              measurementPercentage: 0,
              accumulatedPercentage: 0,
              contractBalance: 0,
            )
            : ProjectMeasurementProjection.fromValues(
              contractValue: contractValue,
              previousAccumulatedGross:
                  rows.length > 1
                      ? rows
                          .take(rows.length - 1)
                          .fold<double>(
                            0,
                            (sum, item) => sum + item.grossAmount,
                          )
                      : 0,
              grossAmount: latestMeasurement!.grossAmount,
              discountAmount: latestMeasurement.discountAmount,
            );

    await _client
        .from(_projectsTable)
        .update(
          DbValue.normalizeMap({
            'estimatedProgress': lastProjection.accumulatedPercentage,
            'estimated_progress': lastProjection.accumulatedPercentage,
            'measuredAmount': lastProjection.accumulatedGrossAmount,
            'measured_amount': lastProjection.accumulatedGrossAmount,
            'measurementCount': rows.length,
            'measurement_count': rows.length,
            'lastMeasurementAt': latestMeasurement?.measurementDate,
            'last_measurement_at': latestMeasurement?.measurementDate,
            'updatedAt': DateTime.now(),
            'updated_at': DateTime.now(),
          }),
        )
        .eq('id', projectId);
  }

  Future<Map<String, dynamic>> _getProjectSnapshot(String projectId) async {
    final row =
        await _client
            .from(_projectsTable)
            .select('id, name, client, budget')
            .eq('id', projectId)
            .maybeSingle();

    if (row == null) {
      throw Exception('Projeto vinculado a medicao nao foi encontrado.');
    }

    return Map<String, dynamic>.from(row);
  }

  void _validateMeasurement(ProjectMeasurement measurement) {
    if (measurement.projectId.trim().isEmpty) {
      throw Exception('Projeto e obrigatorio para registrar a medicao.');
    }

    if (measurement.grossAmount < 0) {
      throw Exception('Valor bruto da medicao nao pode ser negativo.');
    }

    if (measurement.discountAmount < 0) {
      throw Exception('Desconto nao pode ser negativo.');
    }

    if (measurement.discountAmount > measurement.grossAmount) {
      throw Exception('Desconto nao pode ser maior que o valor bruto.');
    }
  }

  void _notifyMeasurementsChanged() {
    AppDataRefreshBus.instance.notify(
      scopes: const [
        AppDataRefreshBus.projectMeasurements,
        AppDataRefreshBus.projects,
      ],
      source: 'ProjectMeasurementService',
    );
  }
}
