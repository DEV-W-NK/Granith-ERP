import 'dart:convert';

import 'package:http/http.dart' as http;

class MapsGeocodingService {
  static const _defaultApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'GOOGLE_MAPS_API_KEY_REMOVED',
  );
  static const _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const _timeout = Duration(seconds: 18);

  final http.Client _client;
  final String _apiKey;

  MapsGeocodingService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? _defaultApiKey;

  Future<MapsGeocodingResult?> geocodeAddress(String address) async {
    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) return null;

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'address': cleanAddress,
        'region': 'br',
        'language': 'pt-BR',
        'key': _apiKey,
      },
    );

    final response = await _client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw MapsGeocodingException(
        'Falha ao consultar endereco (${response.statusCode}).',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MapsGeocodingException('Resposta invalida do Google Maps.');
    }

    final status = decoded['status']?.toString() ?? '';
    if (status == 'ZERO_RESULTS') return null;
    if (status != 'OK') {
      throw MapsGeocodingException(
        decoded['error_message']?.toString() ??
            'Geocoding retornou status $status.',
      );
    }

    final results = decoded['results'];
    if (results is! List || results.isEmpty) return null;

    return MapsGeocodingResult.fromJson(
      Map<String, dynamic>.from(results.first as Map),
    );
  }

  void dispose() {
    _client.close();
  }
}

class MapsGeocodingResult {
  final String formattedAddress;
  final String? placeId;
  final double latitude;
  final double longitude;

  const MapsGeocodingResult({
    required this.formattedAddress,
    this.placeId,
    required this.latitude,
    required this.longitude,
  });

  factory MapsGeocodingResult.fromJson(Map<String, dynamic> json) {
    final geometry = Map<String, dynamic>.from(json['geometry'] as Map? ?? {});
    final location = Map<String, dynamic>.from(
      geometry['location'] as Map? ?? {},
    );

    return MapsGeocodingResult(
      formattedAddress: json['formatted_address']?.toString() ?? '',
      placeId: json['place_id']?.toString(),
      latitude: (location['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MapsGeocodingException implements Exception {
  final String message;

  MapsGeocodingException(this.message);

  @override
  String toString() => message;
}
