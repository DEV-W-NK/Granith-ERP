import 'package:flutter/material.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/constants/supplier_constants.dart';

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
    return Card(
      elevation: SupplierConstants.cardElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SupplierConstants.cardBorderRadius),
      ),
      color: AppColors.surfaceDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SupplierConstants.cardBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              SupplierConstants.cardBorderRadius,
            ),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: isListView ? _buildListView() : _buildGridView(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Row(
      children: [
        _buildLeadingIcon(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildSupplierName()),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 4),
              _buildSupplierCnpj(),
              const SizedBox(height: 8),
              _buildSupplierInfo(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildActions(),
      ],
    );
  }

  Widget _buildGridView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLeadingIcon(),
            const Spacer(),
            _buildStatusBadge(),
            const SizedBox(width: 8),
            _buildActions(),
          ],
        ),
        const SizedBox(height: 12),
        _buildSupplierName(),
        const SizedBox(height: 4),
        _buildSupplierCnpj(),
        const Spacer(),
        _buildSupplierInfo(),
      ],
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            supplier.isActive
                ? AppColors.accentGold.withOpacity(0.2)
                : AppColors.textMuted.withOpacity(0.1),
            supplier.isActive
                ? AppColors.accentGold.withOpacity(0.1)
                : AppColors.textMuted.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              supplier.isActive
                  ? AppColors.accentGold.withOpacity(0.3)
                  : AppColors.textMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.business_rounded,
        color:
            supplier.isActive
                ? AppColors.accentGold
                : AppColors.textMuted.withOpacity(0.6),
        size: 24,
      ),
    );
  }

  Widget _buildSupplierName() {
    return Text(
      supplier.name,
      style: TextStyle(
        color: supplier.isActive ? AppColors.textPrimary : AppColors.textMuted,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      maxLines: isListView ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSupplierCnpj() {
    return Text(
      supplier.formattedCnpj,
      style: TextStyle(
        color:
            supplier.isActive
                ? AppColors.textSecondary
                : AppColors.textMuted.withOpacity(0.7),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            supplier.isActive
                ? AppColors.accentGreen.withOpacity(0.15)
                : AppColors.textMuted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              supplier.isActive
                  ? AppColors.accentGreen.withOpacity(0.3)
                  : AppColors.textMuted.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        supplier.isActive
            ? SupplierConstants.statusActive
            : SupplierConstants.statusInactive,
        style: TextStyle(
          color:
              supplier.isActive ? AppColors.accentGreen : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSupplierInfo() {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: AppColors.textMuted.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Criado em ${_formatDate(supplier.createdAt)}',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.8),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: AppColors.textMuted.withOpacity(0.8),
        size: 20,
      ),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 8,
      onSelected: (String action) => _handleAction(action),
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
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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

  String _formatDate(DateTime date) {
    final months = [
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
}
