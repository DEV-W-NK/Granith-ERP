import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

Future<void>? _loadFuture;

Future<void> ensureGoogleMapsWebApiLoaded() {
  if (_isGoogleMapsReady()) return Future.value();
  return _loadFuture ??= _loadGoogleMapsScript().catchError((Object error) {
    _loadFuture = null;
    throw error;
  });
}

Future<void> _loadGoogleMapsScript() async {
  final key = _readGoogleMapsKey();
  if (key.isEmpty) {
    throw StateError(
      'GOOGLE_MAPS_API_KEY nao configurada em window.GRANITH_ENV.',
    );
  }

  final existing = document.querySelector('script#$_scriptId');
  if (existing != null) {
    if (_isGoogleMapsReady()) return;
    await _waitForScriptLoad(existing as HTMLScriptElement);
    return;
  }

  final script =
      document.createElement('script') as HTMLScriptElement
        ..id = _scriptId
        ..async = true
        ..defer = true
        ..src =
            'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeComponent(key)}';

  final target = document.head ?? document.body;
  if (target == null) {
    throw StateError('Documento web ainda nao esta pronto para carregar Maps.');
  }

  final load = _waitForScriptLoad(script);
  target.appendChild(script);

  try {
    await load;
  } catch (_) {
    script.remove();
    rethrow;
  }
}

Future<void> _waitForScriptLoad(HTMLScriptElement script) {
  final completer = Completer<void>();

  final loadListener =
      ((Event _) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }).toJS;

  final errorListener =
      ((Event _) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Falha ao carregar Google Maps JavaScript API.'),
          );
        }
      }).toJS;

  script
    ..addEventListener('load', loadListener)
    ..addEventListener('error', errorListener);

  return completer.future.timeout(_loadTimeout);
}

bool _isGoogleMapsReady() {
  final google = globalContext['google'];
  if (google.isUndefinedOrNull || !google.typeofEquals('object')) return false;
  return (google as JSObject).has('maps');
}

String _readGoogleMapsKey() {
  final env = globalContext['GRANITH_ENV'];
  if (env.isUndefinedOrNull || !env.typeofEquals('object')) return '';
  final envObject = env as JSObject;
  if (!envObject.has('GOOGLE_MAPS_API_KEY')) return '';
  final value = envObject['GOOGLE_MAPS_API_KEY'];
  return value.dartify()?.toString().trim() ?? '';
}

const _scriptId = 'granith-google-maps-js';
const _loadTimeout = Duration(seconds: 12);
