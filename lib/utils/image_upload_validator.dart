import 'dart:typed_data';

class ValidatedImageUpload {
  const ValidatedImageUpload({
    required this.bytes,
    required this.extension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String extension;
  final String contentType;
}

abstract final class ImageUploadValidator {
  static const maxBytes = 10 * 1024 * 1024;

  static ValidatedImageUpload validate(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('O arquivo de imagem esta vazio.');
    }
    if (bytes.length > maxBytes) {
      throw const FormatException('A imagem deve ter no maximo 10 MB.');
    }

    if (_matches(bytes, const [0xFF, 0xD8, 0xFF])) {
      return ValidatedImageUpload(
        bytes: bytes,
        extension: 'jpg',
        contentType: 'image/jpeg',
      );
    }
    if (_matches(bytes, const [0x89, 0x50, 0x4E, 0x47])) {
      return ValidatedImageUpload(
        bytes: bytes,
        extension: 'png',
        contentType: 'image/png',
      );
    }
    if (bytes.length >= 12 &&
        _matches(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        _matches(bytes, const [0x57, 0x45, 0x42, 0x50], offset: 8)) {
      return ValidatedImageUpload(
        bytes: bytes,
        extension: 'webp',
        contentType: 'image/webp',
      );
    }

    throw const FormatException(
      'Formato nao suportado. Use JPEG, PNG ou WebP.',
    );
  }

  static bool _matches(Uint8List bytes, List<int> signature, {int offset = 0}) {
    if (bytes.length < offset + signature.length) return false;
    for (var index = 0; index < signature.length; index += 1) {
      if (bytes[offset + index] != signature[index]) return false;
    }
    return true;
  }
}
