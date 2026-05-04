import 'package:flutter/material.dart';
import 'package:project_granith/constants/budget_type_constants.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/themes/app_theme.dart';

class BudgetTypeCard extends StatelessWidget {
  final BudgetType budgetType;
  final bool isListView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback? onToggleStatus;

  const BudgetTypeCard({
    super.key,
    required this.budgetType,
    this.isListView = false,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceDark,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: isListView ? _buildListLayout() : _buildGridLayout(),
        ),
      ),
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildContent(),
        const Spacer(),
        _buildFooter(),
      ],
    );
  }

  Widget _buildListLayout() {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 4),
              _buildDescription(),
              const SizedBox(height: 8),
              _buildCategory(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            _buildStatusBadge(),
            const SizedBox(height: 8),
            _buildActions(),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: 12),
        Expanded(child: _buildTitle()),
        _buildActions(),
      ],
    );
  }

  Widget _buildIcon() {
    Color color =
        budgetType.color != null
            ? Color(int.parse(budgetType.color!))
            : BudgetTypeConstants.categoryColors[budgetType.category] ??
                AppColors.accentGold;

    IconData icon =
        budgetType.iconName != null
            ? BudgetTypeConstants.availableIcons[budgetType.iconName!] ??
                Icons.category
            : BudgetTypeConstants.categoryIcons[budgetType.category] ??
                Icons.category;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, color: color, size: isListView ? 24 : 28),
    );
  }

  Widget _buildTitle() {
    return Text(
      budgetType.name,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: isListView ? 16 : 18,
      ),
      maxLines: isListView ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(),
        const SizedBox(height: 12),
        _buildCategory(),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      budgetType.description,
      style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
      maxLines: isListView ? 2 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategory() {
    final categoryColor =
        BudgetTypeConstants.categoryColors[budgetType.category] ??
        AppColors.accentGold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: categoryColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            BudgetTypeConstants.categoryIcons[budgetType.category],
            color: categoryColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            budgetType.category,
            style: TextStyle(
              color: categoryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [Expanded(child: _buildStatusBadge()), _buildDateInfo()],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            budgetType.isActive
                ? AppColors.accentGold.withOpacity(0.15)
                : AppColors.textMuted.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              budgetType.isActive
                  ? AppColors.accentGold.withOpacity(0.3)
                  : AppColors.textMuted.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color:
                  budgetType.isActive
                      ? AppColors.accentGold
                      : AppColors.textMuted,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            budgetType.isActive ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color:
                  budgetType.isActive
                      ? AppColors.accentGold
                      : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo() {
    if (isListView) return const SizedBox.shrink();

    return Tooltip(
      message: 'Criado em ${_formatDate(budgetType.createdAt)}',
      child: Icon(
        Icons.info_outline,
        color: AppColors.textMuted.withOpacity(0.6),
        size: 16,
      ),
    );
  }

  Widget _buildActions() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor.withOpacity(0.3)),
      ),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Editar',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    budgetType.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.accentBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    budgetType.isActive ? 'Desativar' : 'Ativar',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline,
                    color: AppColors.accentRed,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Excluir',
                    style: TextStyle(color: AppColors.accentRed),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit();
        break;
      case 'toggle_status':
        onToggleStatus?.call();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
