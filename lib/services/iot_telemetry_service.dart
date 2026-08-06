import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/iot_telemetry_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IoTTelemetryService {
  IoTTelemetryService({SupabaseClient? client}) : _client = client;

  static const int _telemetryLimit = 1200;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? AppSupabase.client;

  Future<IoTTelemetryDashboardData> loadDashboard({
    required DateTime from,
    String? projectId,
    String? deviceId,
  }) async {
    final devices = await _loadDevices(projectId: projectId);
    final readings = await _loadReadings(
      from: from,
      projectId: projectId,
      deviceId: deviceId,
    );
    final projectNames = await _loadProjectNames(devices, readings);

    return IoTTelemetryDashboardData(
      devices: devices,
      readings: readings,
      projectNames: projectNames,
      loadedAt: DateTime.now(),
    );
  }

  Future<List<IoTDeviceRecord>> _loadDevices({String? projectId}) async {
    final List<dynamic> rows;
    if (_hasValue(projectId)) {
      rows = await _supabase
          .from('iot_devices')
          .select()
          .eq('projectId', projectId!.trim())
          .order('lastSeenAt', ascending: false);
    } else {
      rows = await _supabase
          .from('iot_devices')
          .select()
          .order('lastSeenAt', ascending: false);
    }

    return rows
        .whereType<Map>()
        .map((row) => IoTDeviceRecord.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<IoTTelemetryReading>> _loadReadings({
    required DateTime from,
    String? projectId,
    String? deviceId,
  }) async {
    final List<dynamic> rows;
    final fromIso = from.toUtc().toIso8601String();

    if (_hasValue(deviceId)) {
      rows = await _supabase
          .from('iot_telemetry')
          .select()
          .eq('deviceId', deviceId!.trim())
          .gte('receivedAt', fromIso)
          .order('receivedAt', ascending: false)
          .limit(_telemetryLimit);
    } else if (_hasValue(projectId)) {
      rows = await _supabase
          .from('iot_telemetry')
          .select()
          .eq('projectId', projectId!.trim())
          .gte('receivedAt', fromIso)
          .order('receivedAt', ascending: false)
          .limit(_telemetryLimit);
    } else {
      rows = await _supabase
          .from('iot_telemetry')
          .select()
          .gte('receivedAt', fromIso)
          .order('receivedAt', ascending: false)
          .limit(_telemetryLimit);
    }

    return rows
        .whereType<Map>()
        .map(
          (row) => IoTTelemetryReading.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<Map<String, String>> _loadProjectNames(
    List<IoTDeviceRecord> devices,
    List<IoTTelemetryReading> readings,
  ) async {
    final ids = <String>{
      ...devices.map((device) => device.projectId),
      ...readings.map((reading) => reading.projectId),
    }.where((id) => id.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const <String, String>{};

    try {
      final rows = await _supabase
          .from('projects')
          .select('id, name')
          .inFilter('id', ids);
      return {
        for (final row in rows.whereType<Map>())
          (row['id']?.toString() ?? ''): row['name']?.toString() ?? 'Obra',
      }..remove('');
    } catch (_) {
      // The telemetry is still useful when project metadata is restricted.
      return const <String, String>{};
    }
  }

  static bool _hasValue(String? value) => value?.trim().isNotEmpty ?? false;
}
