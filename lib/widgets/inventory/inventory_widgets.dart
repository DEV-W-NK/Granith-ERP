import 'package:flutter/material.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/models/InventoryMovementType.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onWriteOff;

  const InventoryItemCard({
    required this.item,
    required this.onWriteOff,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.quantity <= item.minQuantity;

    return Container(
      decoration: AppDecorations.cardSurface(
        accent: isLowStock ? AppColors.accentRed : AppColors.accentBlue,
        radius: 14,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppDecorations.iconTile(
              isLowStock ? AppColors.accentRed : AppColors.accentBlue,
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: isLowStock ? AppColors.accentRed : AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(
                    color:
                        isLowStock
                            ? AppColors.accentRed
                            : AppColors.accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onWriteOff,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed.withOpacity(0.1),
              foregroundColor: AppColors.accentRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Dar Baixa'),
          ),
        ],
      ),
    );
  }
}

class InventoryWriteOffDialog extends StatefulWidget {
  final InventoryItem item;
  final InventoryService service;

  const InventoryWriteOffDialog({
    required this.item,
    required this.service,
    super.key,
  });

  @override
  State<InventoryWriteOffDialog> createState() =>
      _InventoryWriteOffDialogState();
}

class _InventoryWriteOffDialogState extends State<InventoryWriteOffDialog> {
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text(
        'Dar Baixa: ${widget.item.name}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Disponível: ${widget.item.quantity} ${widget.item.unit}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Quantidade a utilizar',
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textMuted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accentRed),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a quantidade';
                }
                final qty = double.tryParse(value.replaceAll(',', '.'));
                if (qty == null || qty <= 0) return 'Valor inválido';
                if (qty > widget.item.quantity) return 'Saldo insuficiente';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Motivo (Opcional)',
                hintText: 'Ex: Produção, Obra X, Perda',
                hintStyle: TextStyle(color: Colors.white24),
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.textMuted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accentRed),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Confirmar Baixa'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final qty = double.parse(_qtyController.text.replaceAll(',', '.'));
      final reason =
          _reasonController.text.isEmpty ? 'Uso Geral' : _reasonController.text;
      final movement = InventoryMovement(
        id: '',
        itemId: widget.item.id,
        itemName: widget.item.name,
        quantity: qty,
        type: InventoryMovementType.outbound,
        date: DateTime.now(),
        notes: reason,
        userId: 'current_user',
      );
      await widget.service.addMovement(movement);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baixa realizada com sucesso!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class InventoryEmptyState extends StatelessWidget {
  const InventoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Estoque vazio',
            style: TextStyle(color: AppColors.textMuted, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Receba compras para alimentar o estoque.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
