import 'package:flutter/material.dart';
import 'package:project_granith/contants/budget_type_constants.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/controllers/budget_type_controller.dart';
import 'package:project_granith/widgets/Budget_Type/budget_type_form_dialog.dart';
import 'package:provider/provider.dart';

// Mostrar dialog de formulário
Future<void> showBudgetTypeDialog(
  BuildContext context, {
  BudgetType? budgetType,
}) async {
  final controller = Provider.of<BudgetTypeController>(context, listen: false);
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => BudgetTypeFormDialog(
      budgetType: budgetType,
      onSave: (budgetType) async {
        if (budgetType.id.isEmpty) {
          await controller.createBudgetType(budgetType);
        } else {
          await controller.updateBudgetType(budgetType);
        }
      },
    ),
  );
}

// Mostrar dialog de confirmação de exclusão
Future<void> showDeleteBudgetTypeDialog(
  BuildContext context,
  BudgetType budgetType,
) async {
  final controller = Provider.of<BudgetTypeController>(context, listen: false);
  
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DeleteConfirmationDialog(budgetType: budgetType),
  );

  if (confirmed == true) {
    final success = await controller.deleteBudgetType(budgetType.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tipo de orçamento "${budgetType.name}" excluído com sucesso'),
          backgroundColor: AppColors.accentGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Mostrar detalhes do tipo de orçamento
Future<void> showBudgetTypeDetails(
  BuildContext context,
  BudgetType budgetType,
) async {
  await showDialog(
    context: context,
    builder: (context) => _BudgetTypeDetailsDialog(budgetType: budgetType),
  );
}

// Dialog de confirmação de exclusão
class _DeleteConfirmationDialog extends StatelessWidget {
  final BudgetType budgetType;

  const _DeleteConfirmationDialog({required this.budgetType});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_outlined,
              color: AppColors.accentRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirmar Exclusão',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tem certeza que deseja excluir o tipo de orçamento:',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color: AppColors.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${budgetType.name}"',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Esta ação não pode ser desfeita.',
            style: TextStyle(
              color: AppColors.accentRed.withOpacity(0.8),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Excluir',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// Dialog de detalhes do tipo de orçamento
class _BudgetTypeDetailsDialog extends StatelessWidget {
  final BudgetType budgetType;

  const _BudgetTypeDetailsDialog({required this.budgetType});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailsHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildDetailsContent(),
              ),
            ),
            _buildDetailsActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsHeader() {
    final color = budgetType.color != null 
        ? Color(int.parse(budgetType.color!))
        : BudgetTypeConstants.categoryColors[budgetType.category] ?? AppColors.accentGold;

    final icon = budgetType.iconName != null
        ? BudgetTypeConstants.availableIcons[budgetType.iconName!] ?? Icons.category
        : BudgetTypeConstants.categoryIcons[budgetType.category] ?? Icons.category;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budgetType.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    budgetType.category,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem(
          'Descrição',
          budgetType.description,
          Icons.description_outlined,
        ),
        const SizedBox(height: 20),
        _buildDetailItem(
          'Status',
          budgetType.isActive ? 'Ativo' : 'Inativo',
          budgetType.isActive ? Icons.check_circle : Icons.cancel,
          valueColor: budgetType.isActive ? AppColors.accentGold : AppColors.accentRed,
        ),
        const SizedBox(height: 20),
        _buildDetailItem(
          'Data de Criação',
          _formatDateTime(budgetType.createdAt),
          Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 20),
        _buildDetailItem(
          'Última Atualização',
          _formatDateTime(budgetType.updatedAt),
          Icons.update_outlined,
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(
                  color: AppColors.borderColor.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}