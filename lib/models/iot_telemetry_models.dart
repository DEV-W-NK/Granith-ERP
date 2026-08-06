class IoTDeviceRecord {
  const IoTDeviceRecord({
    required this.id,
    required this.projectId,
    required this.name,
    required this.kind,
    required this.status,
    required this.mqttClientId,
    this.lastSeenAt,
    this.lastRssiDbm,
    this.firmwareVersion,
    this.hardwareId,
    this.telemetryIntervalSeconds = 900,
    this.notes = '',
  });

  final String id;
  final String projectId;
  final String name;
  final String kind;
  final String status;
  final String mqttClientId;
  final DateTime? lastSeenAt;
  final int? lastRssiDbm;
  final String? firmwareVersion;
  final String? hardwareId;
  final int telemetryIntervalSeconds;
  final String notes;

  bool get isActive => status == 'active';
  String get displayName => name.trim().isEmpty ? id : name.trim();

  factory IoTDeviceRecord.fromMap(Map<String, dynamic> row) {
    return IoTDeviceRecord(
      id: _text(row['id']),
      projectId: _text(row['projectId']),
      name: _text(row['name']),
      kind: _text(row['kind'], fallback: 'siteSensor'),
      status: _text(row['status'], fallback: 'active'),
      mqttClientId: _text(row['mqttClientId']),
      lastSeenAt: _date(row['lastSeenAt']),
      lastRssiDbm: _integerOrNull(row['lastRssiDbm']),
      firmwareVersion: _nullableText(row['firmwareVersion']),
      hardwareId: _nullableText(row['hardwareId']),
      telemetryIntervalSeconds:
          _integerOrNull(row['telemetryIntervalSeconds']) ?? 900,
      notes: _text(row['notes']),
    );
  }
}

class IoTProjectOption {
  const IoTProjectOption({required this.id, required this.name});

  final String id;
  final String name;

  factory IoTProjectOption.fromMap(Map<String, dynamic> row) {
    return IoTProjectOption(
      id: _text(row['id']),
      name: _text(row['name'], fallback: 'Obra sem nome'),
    );
  }
}

class IoTProvisioningKit {
  const IoTProvisioningKit({
    required this.secret,
    required this.projectId,
    required this.deviceName,
    required this.expiresAt,
    this.deviceId,
  });

  final String secret;
  final String projectId;
  final String deviceName;
  final DateTime expiresAt;
  final String? deviceId;

  factory IoTProvisioningKit.fromMap(Map<String, dynamic> row) {
    final token =
        row['token'] is Map
            ? Map<String, dynamic>.from(row['token'] as Map)
            : const <String, dynamic>{};
    return IoTProvisioningKit(
      secret: _text(row['provisioningSecret']),
      projectId: _text(token['projectId']),
      deviceName: _text(token['deviceName'], fallback: 'Sensor IoT'),
      deviceId: _nullableText(token['deviceId']),
      expiresAt: _date(token['expiresAt']) ?? DateTime.now(),
    );
  }
}

class IoTTelemetryReading {
  const IoTTelemetryReading({
    required this.id,
    required this.deviceId,
    required this.projectId,
    required this.bootId,
    required this.sequence,
    required this.receivedAt,
    required this.payload,
    this.sampledAt,
    this.rssiDbm,
    this.batteryMillivolts,
  });

  final String id;
  final String deviceId;
  final String projectId;
  final String bootId;
  final int sequence;
  final DateTime? sampledAt;
  final DateTime receivedAt;
  final int? rssiDbm;
  final int? batteryMillivolts;
  final Map<String, dynamic> payload;

  int? get freeHeap => _integerOrNull(payload['freeHeap']);
  String? get firmwareVersion => _nullableText(payload['firmware']);
  int? get uptimeSeconds => _integerOrNull(payload['uptimeSec']);

  factory IoTTelemetryReading.fromMap(Map<String, dynamic> row) {
    final receivedAt = _date(row['receivedAt']) ?? DateTime.now();
    final rawPayload = row['payload'];

    return IoTTelemetryReading(
      id: _text(row['id']),
      deviceId: _text(row['deviceId']),
      projectId: _text(row['projectId']),
      bootId: _text(row['bootId']),
      sequence: _integerOrNull(row['sequence']) ?? 0,
      sampledAt: _date(row['sampledAt']),
      receivedAt: receivedAt,
      rssiDbm: _integerOrNull(row['rssiDbm']),
      batteryMillivolts: _integerOrNull(row['batteryMillivolts']),
      payload:
          rawPayload is Map
              ? Map<String, dynamic>.from(rawPayload)
              : const <String, dynamic>{},
    );
  }
}

class IoTTelemetryDashboardData {
  const IoTTelemetryDashboardData({
    required this.devices,
    required this.readings,
    required this.projectNames,
    required this.loadedAt,
  });

  final List<IoTDeviceRecord> devices;
  final List<IoTTelemetryReading> readings;
  final Map<String, String> projectNames;
  final DateTime loadedAt;

  IoTTelemetryReading? get latestReading =>
      readings.isEmpty ? null : readings.first;

  String projectNameFor(String projectId) =>
      projectNames[projectId] ?? 'Obra $projectId';
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

int? _integerOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value.toLocal();
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed?.toLocal();
}
