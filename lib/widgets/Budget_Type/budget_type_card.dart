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
    final color = _resolveColor();
    final icon = _resolveIcon();

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: AppDecorations.cardSurface(
            accent: color,
            emphasized: !isListView,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactList = isListView && constraints.maxWidth < 560;

              return Padding(
                padding: const EdgeInsets.all(14),
                child:
                    isListView
                        ? compactList
                            ? _buildCompactListLayout(color, icon)
                            : _buildListLayout(color, icon)
                        : _buildGridLayout(color, icon),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridLayout(Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIcon(color, icon, size: 40),
            const Spacer(),
            _buildStatusBadge(),
            const SizedBox(width: 2),
            _buildActions(),
          ],
        ),
        const SizedBox(height: 14),
        _buildTitle(maxLines: 1),
        const SizedBox(height: 6),
        Expanded(child: _buildDescription(maxLines: 2)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildCategory(color)),
            const SizedBox(width: 10),
            _buildDateInfo(),
          ],
        ),
      ],
    );
  }

  Widget _buildListLayout(Color color, IconData icon) {
    return Row(
      children: [
        _buildAccentBar(color),
        const SizedBox(width: 12),
        _buildIcon(color, icon, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildTitle(maxLines: 1)),
                  const SizedBox(width: 8),
                  _buildCategory(color),
                ],
              ),
              const SizedBox(height: 6),
              _buildDescription(maxLines: 2),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatusBadge(),
                  const SizedBox(width: 10),
                  _buildDateInfo(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildActions(),
      ],
    );
  }

  Widget _buildCompactListLayout(Color color, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccentBar(color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(color, icon, size: 38),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTitle(maxLines: 2)),
                  _buildActions(),
                ],
              ),
              const SizedBox(height: 8),
              _buildDescription(maxLines: 2),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [_buildCategory(color), _buildStatusBadge()],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccentBar(Color color) {
    return Container(
      width: 4,
      height: 72,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildIcon(Color color, IconData icon, {required double size}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }

  Widget _buildTitle({required int maxLines}) {
    return Text(
      budgetType.name,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription({required int maxLines}) {
    final description =
        budgetType.description.trim().isEmpty
            ? 'Sem descrição'
            : budgetType.description.trim();

    return Text(
      description,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.35,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategory(Color color) {
    final label =
        budgetType.category.trim().isEmpty
            ? 'Sem categoria'
            : budgetType.category.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            BudgetTypeConstants.categoryIcons[budgetType.category] ??
                Icons.category,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
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

  Widget _buildStatusBadge() {
    final color =
        budgetType.isActive ? AppColors.accentGreen : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            budgetType.isActive ? 'Ativo' : 'Inativo',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo() {
    return Tooltip(
      message: 'Criado em ${_formatDate(budgetType.createdAt)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.textMuted,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            _formatDate(budgetType.createdAt),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      tooltip: 'Ações',
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.35)),
      ),
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Text(
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
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: AppColors.accentRed,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Text('Excluir', style: TextStyle(color: AppColors.accentRed)),
                ],
              ),
            ),
          ],
    );
  }

  Color _resolveColor() {
    final raw = budgetType.color?.trim();
    if (raw != null && raw.isNotEmpty) {
      final numeric = int.tryParse(raw);
      if (numeric != null) return Color(numeric);

      final hex = raw.replaceFirst('#', '');
      if (hex.length == 6 || hex.length == 8) {
        final parsed = int.tryParse(
          hex.length == 6 ? 'FF$hex' : hex,
          radix: 16,
        );
        if (parsed != null) return Color(parsed);
      }
    }

    return BudgetTypeConstants.categoryColors[budgetType.category] ??
        AppColors.accentGold;
  }

  IconData _resolveIcon() {
    return budgetType.iconName != null
        ? BudgetTypeConstants.availableIcons[budgetType.iconName!] ??
            Icons.category
        : BudgetTypeConstants.categoryIcons[budgetType.category] ??
            Icons.category;
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
