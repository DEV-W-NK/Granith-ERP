import 'package:flutter/material.dart';
import 'package:project_granith/services/storage_asset_service.dart';

class PrivateStorageImage extends StatefulWidget {
  const PrivateStorageImage({
    super.key,
    required this.reference,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loading,
    this.error,
  });

  final String? reference;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? loading;
  final Widget? error;

  @override
  State<PrivateStorageImage> createState() => _PrivateStorageImageState();
}

class _PrivateStorageImageState extends State<PrivateStorageImage> {
  final StorageAssetService _storage = StorageAssetService();
  Future<String?>? _url;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant PrivateStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) {
      _resolve();
    }
  }

  void _resolve() {
    _url = _storage.resolveProjectImage(widget.reference);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading ??
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Center(child: CircularProgressIndicator()),
              );
        }

        final url = snapshot.data;
        if (snapshot.hasError || url == null || url.isEmpty) {
          return widget.error ??
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              );
        }

        return Image.network(
          url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) {
            return widget.error ??
                SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                );
          },
        );
      },
    );
  }
}
