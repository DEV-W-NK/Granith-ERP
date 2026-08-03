import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/storage/private_storage_image.dart';

class ProjectImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  const ProjectImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.construction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: AppColors.surfaceDark,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    // Se não há URL ou URL está vazia, mostrar placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return PrivateStorageImage(
      reference: imageUrl,
      width: width,
      height: height,
      fit: fit,
      loading: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.accentGold,
            ),
          ),
        ),
      ),
      error: _buildErrorPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              placeholderIcon,
              size: (height != null && height! < 100) ? 24 : 40,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            if (height == null || height! >= 80) ...[
              const SizedBox(height: 8),
              Text(
                'Sem imagem',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: (height != null && height! < 100) ? 24 : 40,
              color: AppColors.accentRed.withValues(alpha: 0.7),
            ),
            if (height == null || height! >= 80) ...[
              const SizedBox(height: 8),
              Text(
                'Erro ao carregar',
                style: TextStyle(
                  color: AppColors.accentRed.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget de exemplo de como usar no ProjectCard
class ProjectCardImageExample extends StatelessWidget {
  final String? projectImageUrl;

  const ProjectCardImageExample({super.key, required this.projectImageUrl});

  @override
  Widget build(BuildContext context) {
    return ProjectImageWidget(
      imageUrl: projectImageUrl,
      width: double.infinity,
      height: 200,
      borderRadius: BorderRadius.circular(12),
      placeholderIcon: Icons.construction,
    );
  }
}
