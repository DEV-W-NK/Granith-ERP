import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/iot_telemetry_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IoTDeviceProvisioningService {
  IoTDeviceProvisioningService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? AppSupabase.client;

  Future<List<IoTProjectOption>> getAvailableProjects() async {
    final rows = await _supabase
        .from('projects')
        .select('id, name')
        .order('name', ascending: true);
    return rows
        .whereType<Map>()
        .map((row) => IoTProjectOption.fromMap(Map<String, dynamic>.from(row)))
        .where((project) => project.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<IoTProvisioningKit> createKit({
    required String projectId,
    required String name,
    required int telemetryIntervalSeconds,
    String kind = 'siteSensor',
  }) async {
    final response = await _supabase.functions.invoke(
      'provision_iot_device',
      body: {
        'action': 'create',
        'projectId': projectId,
        'name': name,
        'kind': kind,
        'telemetryIntervalSeconds': telemetryIntervalSeconds,
      },
    );
    return _kitFromResponse(response.data);
  }

  Future<IoTProvisioningKit> reissueKit(IoTDeviceRecord device) async {
    final response = await _supabase.functions.invoke(
      'provision_iot_device',
      body: {
        'action': 'reissue',
        'deviceId': device.id,
        'projectId': device.projectId,
      },
    );
    return _kitFromResponse(response.data);
  }

  IoTProvisioningKit _kitFromResponse(Object? data) {
    if (data is! Map) {
      throw Exception('Resposta inválida do provisionamento IoT.');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['ok'] != true) {
      throw Exception(
        map['message']?.toString() ?? 'Falha ao gerar o kit IoT.',
      );
    }
    final kit = IoTProvisioningKit.fromMap(map);
    if (kit.secret.isEmpty) {
      throw Exception('O segredo de provisionamento não foi retornado.');
    }
    return kit;
  }
}
