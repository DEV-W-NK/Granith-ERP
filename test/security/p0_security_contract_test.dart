import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/services/storage_asset_service.dart';
import 'package:project_granith/utils/image_upload_validator.dart';

void main() {
  group('P0 security contracts', () {
    test('project media is private and never uses public URLs', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );
      final service = _read('lib/services/service_projetos.dart');
      final dailyLogs = _read('lib/controllers/daily_log_controller.dart');

      expect(migration, contains('public = false'));
      expect(migration, contains("where id = 'project-images'"));
      expect(service, isNot(contains('getPublicUrl')));
      expect(dailyLogs, isNot(contains('getPublicUrl')));
    });

    test('edge functions reject wildcard CORS', () {
      final sharedCors = _read('supabase/functions/_shared/cors.ts');
      expect(sharedCors, isNot(contains("'Access-Control-Allow-Origin': '*'")));
      expect(sharedCors, contains('origin_not_allowed'));

      for (final functionName in const [
        'dispatch_mobile_push',
        'gemini_generate',
        'manage_internal_user',
        'sync_usage_stats',
      ]) {
        final function = _read('supabase/functions/$functionName/index.ts');
        expect(function, contains('withCors(request'));
        if (function.contains("npm:@supabase/supabase-js")) {
          expect(
            function,
            contains("npm:@supabase/supabase-js@2.101.1"),
          );
        }
      }
    });

    test('Gemini is internal-only and protected by a database rate limit', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );
      final function = _read('supabase/functions/gemini_generate/index.ts');

      expect(migration, contains('function public.consume_edge_rate_limit'));
      expect(migration, contains("'gemini_generate'::text, 300::integer"));
      expect(function, contains('enforceRateLimit(userClient)'));
      expect(function, contains("['admin', 'employee'].includes(role)"));
      expect(function, contains("status !== 'ativo'"));
    });

    test('push dispatch requires an explicit operational permission', () {
      final function = _read(
        'supabase/functions/dispatch_mobile_push/index.ts',
      );

      expect(function, isNot(contains("profile.role === 'employee'")));
      expect(
        function,
        contains("permissions.includes('mobile.notifications.dispatch')"),
      );
    });

    test('employee invite redirect uses the trusted origin allowlist', () {
      final cors = _read('supabase/functions/_shared/cors.ts');
      final function = _read(
        'supabase/functions/manage_internal_user/index.ts',
      );

      expect(cors, contains('export function isAllowedOrigin'));
      expect(function, contains('!isAllowedOrigin(url.origin)'));
    });

    test('time clock and mobile field writes enforce employee ownership', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );

      for (final contract in const [
        'enforce_time_clock_event_owner',
        'time_clock_afd_events_select_authorized',
        'enforce_mobile_work_hour_owner',
        'enforce_mobile_field_operation_owner',
        'mobile_inventory_operations_update_authorized',
        'mobile_vehicle_field_reports_update_authorized',
        'mobile_project_measurement_evidence_update_authorized',
        "mobile.inventory.operate",
        "mobile.vehicle_checklist.write",
        "mobile.measurements.evidence.write",
      ]) {
        expect(migration, contains(contract));
      }
      for (final serverValidation in const [
        'serverProjectAuthorized',
        'serverLocationReliable',
        'serverInsideGeofence',
        'serverSequenceValid',
        'new."accuracyMeters" between 0 and 80',
        'Obra nao atribuida ao funcionario.',
      ]) {
        expect(migration, contains(serverValidation));
      }
    });

    test('driver route writes cannot alter financial or GPS history', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );

      for (final contract in const [
        'enforce_driver_route_update',
        'enforce_driver_route_stop_update',
        'enforce_route_tracking_point',
        'new."kmRate" := old."kmRate"',
        'sum(point."distanceFromPreviousMeters")',
        'revoke update, delete on public.purchase_delivery_route_tracking_points',
      ]) {
        expect(migration, contains(contract));
      }
    });

    test('mobile fuel logs are bound and calculated by the database', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );

      for (final contract in const [
        'can_submit_mobile_fuel_log',
        'enforce_mobile_fuel_log',
        'enforce_mobile_vehicle_update',
        'apply_fuel_log_to_vehicle',
        'new."employeeId" := v_employee_id',
        'new."vehiclePlate" := v_vehicle.plate',
        'new."financialTransactionId" := null',
        'vehicle_fuel_logs_insert_authorized',
      ]) {
        expect(migration, contains(contract));
      }
    });

    test('mobile requisitions and daily logs cannot escalate workflow state', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );

      for (final contract in const [
        'enforce_mobile_material_requisition',
        'new.status := old.status',
        'new."approvedBy" := old."approvedBy"',
        'material_requisitions_insert_authorized',
        'enforce_mobile_daily_log',
        'Signing cannot modify daily log business fields.',
        'new."coordinatorId" := old."coordinatorId"',
        'daily_logs_insert_authorized',
        'daily_logs_update_authorized',
      ]) {
        expect(migration, contains(contract));
      }
    });

    test('task time and authorship are server-owned', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );

      for (final contract in const [
        'guard_granith_task_integrity',
        'Task authorship is immutable.',
        'granith.task_timer_operation',
        'Task timer fields can only be changed through the timer RPC.',
        'new."createdByUserId" := (select auth.uid())::text',
        'perform set_config(\'granith.task_timer_operation\', \'on\', true)',
      ]) {
        expect(migration, contains(contract));
      }
    });

    test('self-service user profiles cannot forge employee bindings', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );

      for (final contract in const [
        'guard_user_profile_privileged_fields',
        'No active employee matches the authenticated email.',
        'new."employeeId" := v_employee_id',
        'new.employee_id := v_employee_id',
        'new.username := null',
        'Only access managers can update identity or authorization fields.',
      ]) {
        expect(migration, contains(contract));
      }
    });

    test('team membership cannot be used to claim an arbitrary project', () {
      final migration = _read(
        'supabase/migrations/20260728120000_p0_security_hardening.sql',
      );

      for (final contract in const [
        'guard_team_assignment',
        'Team leaders can only maintain members of their assigned team.',
        'new."projectId" is distinct from old."projectId"',
        'teams_insert_authorized',
        'teams_update_authorized',
        '"leaderId"::text = private.current_user_employee_id()',
      ]) {
        expect(migration, contains(contract));
      }
    });

    test('hosting applies browser security headers', () {
      final firebase = _read('firebase.json');
      for (final header in const [
        'Content-Security-Policy',
        'Strict-Transport-Security',
        'X-Content-Type-Options',
        'X-Frame-Options',
        'Referrer-Policy',
        'Permissions-Policy',
      ]) {
        expect(firebase, contains(header));
      }
    });

    test('CI actions are pinned and client env excludes private secrets', () {
      final workflow = _read('.github/workflows/firebase-hosting.yml');
      final runDev = _read('scripts/run_dev.ps1');
      final envExample = _read('.env.example');

      expect(workflow, isNot(contains('uses: actions/checkout@v')));
      expect(workflow, isNot(contains('uses: subosito/flutter-action@v')));
      expect(
        workflow,
        isNot(contains('uses: FirebaseExtended/action-hosting-deploy@v')),
      );
      expect(runDev, isNot(contains('"GEMINI_API_KEY"')));
      expect(runDev, isNot(contains('"GOOGLE_OAUTH_CLIENT_SECRET"')));
      expect(envExample, isNot(contains('GOOGLE_OAUTH_CLIENT_SECRET=')));
    });

    test('critical workflows are backed by atomic RPCs', () {
      final migration = _read(
        'supabase/migrations/20260728121000_p0_transactional_workflows.sql',
      );
      for (final functionName in const [
        'approve_budget_atomic',
        'convert_quote_to_purchases_atomic',
        'consolidate_purchase_atomic',
        'confirm_purchase_delivery_atomic',
        'cancel_purchase_atomic',
        'create_purchase_route_atomic',
      ]) {
        expect(migration, contains('function public.$functionName'));
      }
      expect(
        migration,
        contains('Driver must be an active employee assigned to an active vehicle.'),
      );
    });

    test('Flutter services do not issue physical deletes', () {
      final services = Directory('lib/services')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(services, isNot(contains('.delete()')));
      expect(services, contains("'archive_record'"));
    });
  });

  group('ImageUploadValidator', () {
    test('accepts JPEG, PNG and WebP signatures', () {
      expect(
        ImageUploadValidator.validate(
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]),
        ).contentType,
        'image/jpeg',
      );
      expect(
        ImageUploadValidator.validate(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x00]),
        ).contentType,
        'image/png',
      );
      expect(
        ImageUploadValidator.validate(
          Uint8List.fromList([
            0x52,
            0x49,
            0x46,
            0x46,
            0,
            0,
            0,
            0,
            0x57,
            0x45,
            0x42,
            0x50,
          ]),
        ).contentType,
        'image/webp',
      );
    });

    test('rejects unknown and GIF payloads', () {
      expect(
        () => ImageUploadValidator.validate(Uint8List.fromList([0, 1, 2, 3])),
        throwsFormatException,
      );
      expect(
        () => ImageUploadValidator.validate(
          Uint8List.fromList([0x47, 0x49, 0x46, 0x38]),
        ),
        throwsFormatException,
      );
    });
  });

  group('StorageAssetService', () {
    final service = StorageAssetService();

    test('extracts object paths from old public and signed URLs', () {
      expect(
        service.objectPathFromReference(
          'https://example.supabase.co/storage/v1/object/public/'
          'project-images/project-1/photo.jpg',
        ),
        'project-1/photo.jpg',
      );
      expect(
        service.objectPathFromReference(
          'https://example.supabase.co/storage/v1/object/sign/'
          'project-images/project-2/photo.png?token=secret',
        ),
        'project-2/photo.png',
      );
    });

    test('keeps external URLs and normalizes private paths', () {
      const external = 'https://images.example.com/project.jpg';
      expect(service.objectPathFromReference(external), isNull);
      expect(service.normalizeForPersistence(external), external);
      expect(
        service.normalizeForPersistence('project-images/project-1/photo.jpg'),
        'project-1/photo.jpg',
      );
    });
  });
}

String _read(String path) => File(path).readAsStringSync();
