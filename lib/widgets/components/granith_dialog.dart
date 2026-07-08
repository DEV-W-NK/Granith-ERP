import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class GranithDialogSurface extends StatelessWidget {
  final Widget child;
  final double width;
  final double? maxHeight;
  final Color accentColor;
  final EdgeInsets? insetPadding;

  const GranithDialogSurface({
    super.key,
    required this.child,
    required this.width,
    this.maxHeight,
    this.accentColor = AppColors.accentBlue,
    this.insetPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding:
          insetPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
        decoration: AppDecorations.dialogSurface(glowColor: accentColor),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class GranithDialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;

  const GranithDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accentColor = AppColors.accentBlue,
    this.onClose,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 12, 16),
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Container(
      padding: padding,
      decoration: AppDecorations.dialogHeader(accent: accentColor),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: AppDecorations.iconTile(accentColor),
            child: Icon(icon, color: accentColor, size: compact ? 20 : 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              tooltip: 'Fechar',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class GranithFormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry padding;

  const GranithFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor = AppColors.accentBlue,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppDecorations.formPanel(borderColor: accentColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class GranithFieldLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const GranithFieldLabel(
    this.text, {
    super.key,
    this.icon,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration granithInputDecoration({
  required String hint,
  IconData? icon,
  String? label,
  Color accentColor = AppColors.accentBlue,
}) {
  final radius = BorderRadius.circular(12);

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    filled: true,
    fillColor: AppColors.surfaceElevated.withValues(alpha: 0.52),
    hintStyle: const TextStyle(color: AppColors.textMuted),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    floatingLabelStyle: TextStyle(color: accentColor),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: AppColors.borderColor.withValues(alpha: 0.72),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: AppColors.borderColor.withValues(alpha: 0.72),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: accentColor, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.accentRed, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.accentRed, width: 1.4),
    ),
  );
}
