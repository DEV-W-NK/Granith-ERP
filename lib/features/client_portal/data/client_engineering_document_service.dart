import 'package:supabase_flutter/supabase_flutter.dart';

class ClientEngineeringDocument {
  const ClientEngineeringDocument({
    required this.publicationId,
    required this.projectId,
    required this.documentId,
    required this.revisionId,
    required this.title,
    required this.discipline,
    required this.revisionCode,
    required this.fileName,
    required this.bucket,
    required this.filePath,
    required this.pageCount,
    required this.sizeBytes,
    required this.digitallySigned,
    required this.publishedAt,
    this.signaturePolicy,
    this.notes = '',
  });

  final String publicationId;
  final String projectId;
  final String documentId;
  final String revisionId;
  final String title;
  final String discipline;
  final String revisionCode;
  final String fileName;
  final String bucket;
  final String filePath;
  final int pageCount;
  final int sizeBytes;
  final bool digitallySigned;
  final DateTime publishedAt;
  final String? signaturePolicy;
  final String notes;
}

class ClientEngineeringReport {
  const ClientEngineeringReport({
    required this.publicationId,
    required this.projectId,
    required this.reportId,
    required this.reportType,
    required this.title,
    required this.version,
    required this.fileName,
    required this.bucket,
    required this.filePath,
    required this.sizeBytes,
    required this.sha256,
    required this.summary,
    required this.publishedAt,
    this.sourceType = 'manual',
    this.sourceId,
    this.notes = '',
  });

  final String publicationId;
  final String projectId;
  final String reportId;
  final String sourceType;
  final String? sourceId;
  final String reportType;
  final String title;
  final int version;
  final String fileName;
  final String bucket;
  final String filePath;
  final int sizeBytes;
  final String sha256;
  final Map<String, dynamic> summary;
  final String notes;
  final DateTime publishedAt;
}

class ClientEngineeringDocumentService {
  ClientEngineeringDocumentService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<ClientEngineeringDocument>> getPublishedForProjects(
    Iterable<String> projectIds,
  ) async {
    final ids = projectIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <ClientEngineeringDocument>[];

    final response = await _supabase
        .from('client_portal_engineering_documents')
        .select()
        .inFilter('projectId', ids)
        .order('publishedAt', ascending: false);

    return response
        .whereType<Map>()
        .map((row) => _map(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Uri> createViewUri(ClientEngineeringDocument document) async {
    final response = await _supabase.storage
        .from(document.bucket)
        .createSignedUrl(document.filePath, 10 * 60);
    return Uri.parse(response);
  }

  Future<List<ClientEngineeringReport>> getPublishedReportsForProjects(
    Iterable<String> projectIds,
  ) async {
    final ids = projectIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <ClientEngineeringReport>[];

    final response = await _supabase
        .from('client_portal_engineering_reports')
        .select()
        .inFilter('projectId', ids)
        .order('publishedAt', ascending: false);

    return response
        .whereType<Map>()
        .map((row) => _mapReport(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Uri> createReportViewUri(ClientEngineeringReport report) async {
    final response = await _supabase.storage
        .from(report.bucket)
        .createSignedUrl(report.filePath, 10 * 60);
    return Uri.parse(response);
  }

  static ClientEngineeringDocument _map(Map<String, dynamic> row) {
    return ClientEngineeringDocument(
      publicationId: _text(row['publicationId']),
      projectId: _text(row['projectId']),
      documentId: _text(row['documentId']),
      revisionId: _text(row['documentRevisionId']),
      title: _text(row['title'], fallback: 'Documento técnico'),
      discipline: _text(row['discipline'], fallback: 'Geral'),
      revisionCode: _text(row['revisionCode'], fallback: 'R00'),
      fileName: _text(row['originalFileName'], fallback: 'documento.pdf'),
      bucket: _text(row['bucket'], fallback: 'engineering-documents'),
      filePath: _text(row['filePath']),
      pageCount: _integer(row['pageCount']),
      sizeBytes: _integer(row['sizeBytes']),
      digitallySigned: row['digitallySigned'] == true,
      signaturePolicy: _nullableText(row['signaturePolicy']),
      notes: _text(row['notes']),
      publishedAt:
          DateTime.tryParse(_text(row['publishedAt']))?.toLocal() ??
          DateTime.now(),
    );
  }

  static ClientEngineeringReport _mapReport(Map<String, dynamic> row) {
    return ClientEngineeringReport(
      publicationId: _text(row['publicationId']),
      projectId: _text(row['projectId']),
      reportId: _text(row['reportId']),
      sourceType: _text(row['sourceType'], fallback: 'manual'),
      sourceId: _nullableText(row['sourceId']),
      reportType: _text(row['reportType'], fallback: 'technical'),
      title: _text(row['title'], fallback: 'Relatório técnico'),
      version: _integer(row['version']),
      fileName: _text(row['originalFileName'], fallback: 'relatorio.pdf'),
      bucket: _text(row['bucket'], fallback: 'engineering-reports'),
      filePath: _text(row['filePath']),
      sizeBytes: _integer(row['sizeBytes']),
      sha256: _text(row['sha256']),
      summary:
          row['summary'] is Map
              ? Map<String, dynamic>.from(row['summary'] as Map)
              : const <String, dynamic>{},
      notes: _text(row['notes']),
      publishedAt:
          DateTime.tryParse(_text(row['publishedAt']))?.toLocal() ??
          DateTime.now(),
    );
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(Object? value) {
    final valueText = _text(value);
    return valueText.isEmpty ? null : valueText;
  }

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
