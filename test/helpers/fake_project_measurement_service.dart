import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/services/project_measurement_service.dart';

class FakeProjectMeasurementService extends ProjectMeasurementService {
  FakeProjectMeasurementService({List<ProjectMeasurement>? initialMeasurements})
    : _measurements = List<ProjectMeasurement>.from(
        initialMeasurements ?? const <ProjectMeasurement>[],
      );

  final List<ProjectMeasurement> _measurements;
  Object? getMeasurementsError;
  Object? addMeasurementError;
  Object? updateMeasurementError;
  Object? deleteMeasurementError;
  ProjectMeasurement? lastAddedMeasurement;
  ProjectMeasurement? lastUpdatedMeasurement;
  String? deletedMeasurementId;

  @override
  Future<List<ProjectMeasurement>> getMeasurements({String? projectId}) async {
    if (getMeasurementsError != null) {
      throw getMeasurementsError!;
    }

    final measurements =
        projectId == null || projectId.trim().isEmpty
            ? _measurements
            : _measurements
                .where((measurement) => measurement.projectId == projectId)
                .toList();

    return List<ProjectMeasurement>.from(measurements);
  }

  @override
  Future<String> addMeasurement(ProjectMeasurement measurement) async {
    if (addMeasurementError != null) {
      throw addMeasurementError!;
    }

    lastAddedMeasurement = measurement;
    final created = measurement.copyWith(
      id: measurement.id.isEmpty ? 'measurement-created' : measurement.id,
    );
    _measurements.add(created);
    return created.id;
  }

  @override
  Future<void> updateMeasurement(ProjectMeasurement measurement) async {
    if (updateMeasurementError != null) {
      throw updateMeasurementError!;
    }

    lastUpdatedMeasurement = measurement;
    final index = _measurements.indexWhere((item) => item.id == measurement.id);
    if (index != -1) {
      _measurements[index] = measurement;
    }
  }

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    if (deleteMeasurementError != null) {
      throw deleteMeasurementError!;
    }

    deletedMeasurementId = measurementId;
    _measurements.removeWhere((measurement) => measurement.id == measurementId);
  }
}
