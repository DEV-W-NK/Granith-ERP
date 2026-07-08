import 'package:flutter/material.dart';

import 'package:project_granith/constants/supplier_constants.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final bool isListView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onToggleStatus;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.isListView,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        supplier.isActive ? AppColors.accentBlue : AppColors.textMuted;
    final radius = BorderRadius.circular(16);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardSurface(
            accent: accent,
            emphasized: supplier.isActive,
            radius: 16,
          ),
          child:
              isListView
                  ? LayoutBuilder(
                    builder: (context, constraints) {
                      return constraints.maxWidth < ResponsiveLayout.compact
                          ? _buildCompactListView()
                          : _buildListView();
                    },
                  )
                  : _buildGridView(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeadingIcon(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSupplierName()),
                  const SizedBox(width: 12),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 6),
              _buildSupplierCnpj(),
              const SizedBox(height: 12),
              _buildSupplierInfo(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildActions(),
      ],
    );
  }

  Widget _buildCompactListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSupplierName(),
                  const SizedBox(height: 5),
                  _buildSupplierCnpj(),
                ],
              ),
            ),
            _buildActions(),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [_buildStatusBadge(), ..._buildSupplierInfoItems()],
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(),
            const Spacer(),
            _buildStatusBadge(),
            const SizedBox(width: 8),
            _buildActions(),
          ],
        ),
        const SizedBox(height: 13),
        _buildSupplierName(maxLines: 2),
        const SizedBox(height: 6),
        _buildSupplierCnpj(),
        const Spacer(),
        _buildSupplierInfo(),
      ],
    );
  }

  Widget _buildLeadingIcon() {
    final accent =
        supplier.isActive ? AppColors.accentBlue : AppColors.textMuted;

    return Container(
      width: 46,
      height: 46,
      decoration: AppDecorations.iconTile(accent),
      child: Icon(
        supplier.isActive
            ? Icons.storefront_rounded
            : Icons.storefront_outlined,
        color: accent,
        size: 23,
      ),
    );
  }

  Widget _buildSupplierName({int? maxLines}) {
    return Text(
      supplier.name,
      style: TextStyle(
        color: supplier.isActive ? AppColors.textPrimary : AppColors.textMuted,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.18,
      ),
      maxLines: maxLines ?? (isListView ? 1 : 2),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSupplierCnpj() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppDecorations.cardInnerSurface(
        accent: supplier.isActive ? AppColors.accentGold : AppColors.textMuted,
        radius: 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge_outlined,
            size: 15,
            color:
                supplier.isActive ? AppColors.accentGold : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              supplier.formattedCnpj,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    supplier.isActive
                        ? AppColors.textSecondary
                        : AppColors.textMuted.withValues(alpha: 0.82),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color =
        supplier.isActive ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        supplier.isActive
            ? SupplierConstants.statusActive
            : SupplierConstants.statusInactive,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSupplierInfo() {
    return Wrap(spacing: 8, runSpacing: 8, children: _buildSupplierInfoItems());
  }

  List<Widget> _buildSupplierInfoItems() {
    return [
      _SupplierInfoPill(
        icon: Icons.event_available_outlined,
        label: 'Criado em ${_formatLongDate(supplier.createdAt)}',
        color: AppColors.textSecondary,
      ),
      _SupplierInfoPill(
        icon: Icons.update_rounded,
        label: 'Atualizado ${_formatShortDate(supplier.updatedAt)}',
        color: AppColors.accentBlue,
      ),
    ];
  }

  Widget _buildActions() {
    return PopupMenuButton<String>(
      tooltip: 'Acoes do fornecedor',
      icon: Icon(
        Icons.more_vert_rounded,
        color: AppColors.textMuted.withValues(alpha: 0.9),
        size: 20,
      ),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderColor.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      elevation: 8,
      onSelected: _handleAction,
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'view',
              child: _buildMenuItem(
                Icons.visibility_rounded,
                'Visualizar',
                AppColors.accentBlue,
              ),
            ),
            PopupMenuItem<String>(
              value: 'edit',
              child: _buildMenuItem(
                Icons.edit_rounded,
                SupplierConstants.buttonEdit,
                AppColors.accentGold,
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_status',
              child: _buildMenuItem(
                supplier.isActive
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                supplier.isActive ? 'Desativar' : 'Ativar',
                supplier.isActive ? AppColors.accentRed : AppColors.accentGreen,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: _buildMenuItem(
                Icons.delete_rounded,
                SupplierConstants.buttonDelete,
                AppColors.accentRed,
              ),
            ),
          ],
    );
  }

  Widget _buildMenuItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'view':
        onTap?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'toggle_status':
        onToggleStatus?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  String _formatLongDate(DateTime date) {
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SupplierInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SupplierInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: AppDecorations.cardInnerSurface(accent: color, radius: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
