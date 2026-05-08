import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:project_granith/services/maps_geocoding_service.dart';

void main() {
  group('MapsGeocodingService', () {
    test('converte resposta do Google em coordenada da obra', () async {
      final service = MapsGeocodingService(
        apiKey: 'test-key',
        client: _FakeHttpClient(
          http.Response(
            json.encode({
              'status': 'OK',
              'results': [
                {
                  'formatted_address': 'Av. Paulista, Sao Paulo - SP',
                  'place_id': 'place-1',
                  'geometry': {
                    'location': {'lat': -23.561, 'lng': -46.655},
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

      final result = await service.geocodeAddress('Avenida Paulista');

      expect(result?.formattedAddress, 'Av. Paulista, Sao Paulo - SP');
      expect(result?.latitude, -23.561);
      expect(result?.longitude, -46.655);
      service.dispose();
    });

    test('retorna null quando endereco nao tem resultado', () async {
      final service = MapsGeocodingService(
        apiKey: 'test-key',
        client: _FakeHttpClient(
          http.Response(json.encode({'status': 'ZERO_RESULTS'}), 200),
        ),
      );

      expect(await service.geocodeAddress('sem resultado'), isNull);
      service.dispose();
    });
  });
}

class _FakeHttpClient extends http.BaseClient {
  final http.Response response;

  _FakeHttpClient(this.response);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stream = Stream<List<int>>.fromIterable([response.bodyBytes]);
    return http.StreamedResponse(stream, response.statusCode);
  }
}
