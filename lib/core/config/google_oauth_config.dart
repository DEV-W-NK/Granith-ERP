import 'package:flutter/foundation.dart' show TargetPlatform;

class GoogleOAuthConfig {
  static const webClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_WEB_CLIENT_ID',
  );
  static const iosClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_IOS_CLIENT_ID',
  );

  static String? nativeClientIdFor(TargetPlatform targetPlatform) {
    if (targetPlatform == TargetPlatform.iOS && iosClientId.isNotEmpty) {
      return iosClientId;
    }

    return null;
  }

  static bool get hasServerClientId => webClientId.isNotEmpty;
}
