import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/geofence_controller.dart';
import 'package:project_granith/models/geofence_model.dart';
import 'package:project_granith/services/geofence_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/geofencing/geofencing_page_widgets.dart';

Widget _mapPreview(BuildContext context, GeofenceController controller) {
  return ColoredBox(
    color: AppColors.primaryDark,
    child: Center(
      child: Text(
        controller.selectedGeofence?.centerCoordinate ?? 'mapa sem cerca',
        key: const Key('geofence-map-preview'),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    ),
  );
}

GeofenceArea _geofence() {
  return GeofenceArea(
    id: 'geo-1',
    name: 'Obra Matriz',
    code: 'OBRA-001',
    centerLatitude: -23.55052,
    centerLongitude: -46.633308,
    sideMeters: 140,
    createdAt: DateTime(2026, 5, 8),
    updatedAt: DateTime(2026, 5, 8),
  );
}

void main() {
  group('GeofencingPageView', () {
    testWidgets('renderiza mapa e cercas vindas das obras', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final service = GeofenceService(
        seedDefaults: false,
        initialItems: [_geofence()],
      );
      final controller = GeofenceController(service: service)..init();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: GeofencingPageView(
            controller: controller,
            mapBuilder: _mapPreview,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Geofencing'), findsOneWidget);
      expect(find.text('Cercas das obras'), findsOneWidget);
      expect(find.text('Obra Matriz'), findsWidgets);
      expect(find.textContaining('-23.550520, -46.633308'), findsWidgets);
      expect(find.text('Criar cerca'), findsNothing);
      expect(controller.totalGeofences, 1);

      controller.dispose();
    });

    testWidgets('renderiza sem overflow no mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final service = GeofenceService(
        seedDefaults: false,
        initialItems: [_geofence()],
      );
      final controller = GeofenceController(service: service)..init();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: GeofencingPageView(
            controller: controller,
            mapBuilder: _mapPreview,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Geofencing'), findsOneWidget);
      expect(find.text('Obra Matriz'), findsWidgets);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });
  });
}
