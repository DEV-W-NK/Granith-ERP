import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageAssetService {
  StorageAssetService({SupabaseClient? client}) : _client = client;

  static const projectImagesBucket = 'project-images';
  static const _signedUrlLifetime = Duration(hours: 1);
  static const _cacheSafetyWindow = Duration(minutes: 5);

  final SupabaseClient? _client;
  final Map<String, _SignedUrlCacheEntry> _cache = {};

  SupabaseClient get _supabase => _client ?? AppSupabase.client;

  Future<String?> resolveProjectImage(String? reference) async {
    final normalized = reference?.trim() ?? '';
    if (normalized.isEmpty) return null;

    final objectPath = objectPathFromReference(normalized);
    if (objectPath == null) {
      return _isHttpUrl(normalized) ? normalized : null;
    }

    final cached = _cache[objectPath];
    final now = DateTime.now();
    if (cached != null &&
        cached.expiresAt.difference(now) > _cacheSafetyWindow) {
      return cached.url;
    }

    final url = await _supabase.storage
        .from(projectImagesBucket)
        .createSignedUrl(objectPath, _signedUrlLifetime.inSeconds);
    _cache[objectPath] = _SignedUrlCacheEntry(
      url: url,
      expiresAt: now.add(_signedUrlLifetime),
    );
    return url;
  }

  String normalizeForPersistence(String reference) {
    return objectPathFromReference(reference.trim()) ?? reference.trim();
  }

  String? objectPathFromReference(String reference) {
    final normalized = reference.trim();
    if (normalized.isEmpty) return null;

    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.isAbsolute) {
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(projectImagesBucket);
      if (bucketIndex < 0 || bucketIndex + 1 >= segments.length) {
        return null;
      }
      return Uri.decodeComponent(segments.sublist(bucketIndex + 1).join('/'));
    }

    final withoutLeadingSlash = normalized.replaceFirst(RegExp(r'^/+'), '');
    if (withoutLeadingSlash.startsWith('$projectImagesBucket/')) {
      return withoutLeadingSlash.substring(projectImagesBucket.length + 1);
    }
    return withoutLeadingSlash;
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.isAbsolute &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

class _SignedUrlCacheEntry {
  const _SignedUrlCacheEntry({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
