import 'package:flutter/material.dart';
import 'package:project_granith/models/InventoryMovementType.dart'; // Importação necessária para o Enum
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/themes/app_theme.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryService _service = InventoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Controle de Estoque'),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: StreamBuilder<List<InventoryItem>>(
        stream: _service.getInventoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _InventoryItemCard(
                item: item,
                onWriteOff: () => _showWriteOffDialog(context, item),
              );
            },
          );
        },
      ),
    );
  }

  void _showWriteOffDialog(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => _WriteOffDialog(item: item, service: _service),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onWriteOff;

  const _InventoryItemCard({required this.item, required this.onWriteOff});

  @override
  Widget build(BuildContext context) {
    // Alerta visual se estoque estiver baixo
    final isLowStock = item.quantity <= item.minQuantity;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: isLowStock 
            ? Border.all(color: AppColors.accentRed.withOpacity(0.5)) 
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Ícone ou Avatar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: isLowStock ? AppColors.accentRed : AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 16),
          // Informações
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
                    color: isLowStock ? AppColors.accentRed : AppColors.accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Botão de Baixa
          ElevatedButton(
            onPressed: onWriteOff,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed.withOpacity(0.1),
              foregroundColor: AppColors.accentRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Dar Baixa'),
          ),
        ],
      ),
    );
  }
}

class _WriteOffDialog extends StatefulWidget {
  final InventoryItem item;
  final InventoryService service;

  const _WriteOffDialog({required this.item, required this.service});

  @override
  State<_WriteOffDialog> createState() => _WriteOffDialogState();
}

class _WriteOffDialogState extends State<_WriteOffDialog> {
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: Text('Dar Baixa: ${widget.item.name}', style: const TextStyle(color: Colors.white)),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Quantidade a utilizar',
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accentRed)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe a quantidade';
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
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.textMuted)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.accentRed)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
      final reason = _reasonController.text.isEmpty ? 'Uso Geral' : _reasonController.text;

      // === CORREÇÃO: Criar o objeto Movement e usar addMovement ===
      final movement = InventoryMovement(
        id: '', // Firestore gera
        itemId: widget.item.id,
        itemName: widget.item.name,
        quantity: qty,
        type: InventoryMovementType.outbound, // Define como Saída
        date: DateTime.now(),
        notes: reason,
        userId: 'current_user', // Substituir pelo ID do usuário real se houver Auth
      );

      // Chama o método que existe no Service
      await widget.service.addMovement(movement);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Baixa realizada com sucesso!'), backgroundColor: AppColors.accentGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
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