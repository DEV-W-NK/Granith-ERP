import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/purchase_delivery_route_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_delivery_route_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class PurchaseLogisticsPageView extends StatefulWidget {
  const PurchaseLogisticsPageView({super.key});

  @override
  State<PurchaseLogisticsPageView> createState() =>
      _PurchaseLogisticsPageViewState();
}

class _PurchaseLogisticsPageViewState extends State<PurchaseLogisticsPageView> {
  final _service = PurchaseDeliveryRouteService();
  final _routeNameCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _selectedPurchaseIds = <String>{};

  late Future<List<Purchase>> _candidatesFuture;
  List<Purchase> _currentCandidates = const [];
  DateTime? _scheduledDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _candidatesFuture = _service.fetchRouteCandidates();
  }

  @override
  void dispose() {
    _routeNameCtrl.dispose();
    _driverCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = ResponsiveLayout.pagePadding(width);
          final gap = ResponsiveLayout.gap(width);
          final desktop = width >= 1040;

          final content =
              desktop
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildRouteBuilder(gap)),
                      SizedBox(width: gap),
                      Expanded(flex: 6, child: _buildRoutesList(gap)),
                    ],
                  )
                  : Column(
                    children: [
                      _buildRouteBuilder(gap),
                      SizedBox(height: gap),
                      _buildRoutesList(gap),
                    ],
                  );

          return SingleChildScrollView(padding: padding, child: content);
        },
      ),
    );
  }

  Widget _buildRouteBuilder(double gap) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.add_road_outlined,
            title: 'Montar rota',
            subtitle: 'Compras consolidadas que ainda nao entraram em rota',
            trailing: IconButton(
              tooltip: 'Atualizar compras disponiveis',
              onPressed: _refreshCandidates,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          SizedBox(height: gap),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: _TextInput(
                  controller: _driverCtrl,
                  label: 'Motorista interno',
                  icon: Icons.badge_outlined,
                ),
              ),
              SizedBox(
                width: 260,
                child: _TextInput(
                  controller: _routeNameCtrl,
                  label: 'Nome da rota',
                  icon: Icons.route_outlined,
                ),
              ),
              _DateButton(date: _scheduledDate, onPressed: _pickDate),
            ],
          ),
          const SizedBox(height: 12),
          _TextInput(
            controller: _notesCtrl,
            label: 'Observacoes para o motorista',
            icon: Icons.sticky_note_2_outlined,
            maxLines: 2,
          ),
          SizedBox(height: gap),
          FutureBuilder<List<Purchase>>(
            future: _candidatesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _EmptyState(
                  icon: Icons.error_outline,
                  title: 'Nao foi possivel carregar compras',
                  subtitle: snapshot.error.toString(),
                );
              }

              _currentCandidates = snapshot.data ?? const [];
              _selectedPurchaseIds.removeWhere(
                (id) =>
                    !_currentCandidates.any((purchase) => purchase.id == id),
              );

              if (_currentCandidates.isEmpty) {
                return const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nenhuma compra disponivel',
                  subtitle:
                      'Consolide uma compra e informe coleta/entrega para montar rotas.',
                );
              }

              return Column(
                children: [
                  for (final purchase in _currentCandidates)
                    _CandidateTile(
                      purchase: purchase,
                      selected: _selectedPurchaseIds.contains(purchase.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPurchaseIds.add(purchase.id);
                          } else {
                            _selectedPurchaseIds.remove(purchase.id);
                          }
                        });
                      },
                    ),
                ],
              );
            },
          ),
          SizedBox(height: gap),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _createRoute,
              icon:
                  _saving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.route_rounded),
              label: Text(
                _selectedPurchaseIds.isEmpty
                    ? 'Selecione compras para montar rota'
                    : 'Criar rota com ${_selectedPurchaseIds.length} compra(s)',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesList(double gap) {
    return _Surface(
      child: StreamBuilder<List<PurchaseDeliveryRoute>>(
        stream: _service.watchRoutes(),
        builder: (context, snapshot) {
          final routes = snapshot.data ?? const <PurchaseDeliveryRoute>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                icon: Icons.alt_route_rounded,
                title: 'Rotas dos motoristas',
                subtitle: 'Base para o modulo mobile com Google Maps e KM',
              ),
              SizedBox(height: gap),
              if (!snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                  ),
                )
              else if (routes.isEmpty)
                const _EmptyState(
                  icon: Icons.route_outlined,
                  title: 'Nenhuma rota criada',
                  subtitle: 'As rotas montadas em compras aparecerem aqui.',
                )
              else
                for (final route in routes)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: _RouteCard(route: route, service: _service),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      setState(() => _scheduledDate = selected);
    }
  }

  void _refreshCandidates() {
    setState(() {
      _selectedPurchaseIds.clear();
      _candidatesFuture = _service.fetchRouteCandidates();
    });
  }

  Future<void> _createRoute() async {
    final selected =
        _currentCandidates
            .where((purchase) => _selectedPurchaseIds.contains(purchase.id))
            .toList();
    if (selected.isEmpty) {
      _showSnack('Selecione ao menos uma compra para montar a rota.', true);
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.createRoute(
        name: _routeNameCtrl.text,
        driverName: _driverCtrl.text,
        scheduledDate: _scheduledDate,
        purchases: selected,
        notes: _notesCtrl.text,
      );
      if (!mounted) return;
      _routeNameCtrl.clear();
      _driverCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _scheduledDate = null;
        _selectedPurchaseIds.clear();
        _candidatesFuture = _service.fetchRouteCandidates();
      });
      _showSnack('Rota criada e compras vinculadas ao motorista.', false);
    } catch (e) {
      _showSnack(e.toString(), true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.accentRed : AppColors.accentGreen,
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final PurchaseDeliveryRoute route;
  final PurchaseDeliveryRouteService service;

  const _RouteCard({required this.route, required this.service});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  route.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _RouteStatusChip(status: route.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Metric(icon: Icons.badge_outlined, label: route.driverName),
              if (route.scheduledDate != null)
                _Metric(
                  icon: Icons.event_outlined,
                  label: dateFormat.format(route.scheduledDate!),
                ),
              if (route.actualDistanceKm > 0)
                _Metric(
                  icon: Icons.speed_outlined,
                  label: '${route.actualDistanceKm.toStringAsFixed(1)} km',
                ),
              if (route.bonusValue > 0)
                _Metric(
                  icon: Icons.payments_outlined,
                  label: currency.format(route.bonusValue),
                  color: AppColors.accentGold,
                ),
            ],
          ),
          if (route.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              route.notes.trim(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          StreamBuilder<List<PurchaseDeliveryRouteStop>>(
            stream: service.watchStops(route.id),
            builder: (context, snapshot) {
              final stops =
                  snapshot.data ?? const <PurchaseDeliveryRouteStop>[];
              if (!snapshot.hasData) {
                return const LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.accentGold,
                );
              }
              if (stops.isEmpty) {
                return const Text(
                  'Sem paradas vinculadas.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                );
              }

              return Column(
                children: [for (final stop in stops) _StopLine(stop: stop)],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (route.status == PurchaseRouteStatus.planned)
                OutlinedButton.icon(
                  onPressed:
                      () => _updateStatus(
                        context,
                        PurchaseRouteStatus.inProgress,
                      ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Iniciar rota'),
                ),
              if (route.status != PurchaseRouteStatus.completed &&
                  route.status != PurchaseRouteStatus.cancelled)
                FilledButton.icon(
                  onPressed: () => _completeRoute(context),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Concluir e lancar KM'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    PurchaseRouteStatus status,
  ) async {
    try {
      await service.updateRouteStatus(routeId: route.id, status: status);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rota marcada como ${status.label.toLowerCase()}.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> _completeRoute(BuildContext context) async {
    final result = await showDialog<_CompletionResult>(
      context: context,
      builder: (context) => _CompletionDialog(route: route),
    );
    if (result == null) return;

    try {
      await service.updateRouteStatus(
        routeId: route.id,
        status: PurchaseRouteStatus.completed,
        actualDistanceKm: result.actualDistanceKm,
        kmRate: result.kmRate,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rota concluida com KM e bonus calculados.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }
}

class _CompletionDialog extends StatefulWidget {
  final PurchaseDeliveryRoute route;

  const _CompletionDialog({required this.route});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  final _distanceCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.route.actualDistanceKm > 0) {
      _distanceCtrl.text = widget.route.actualDistanceKm.toStringAsFixed(1);
    }
    if (widget.route.kmRate > 0) {
      _rateCtrl.text = widget.route.kmRate.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distance = _parseMoney(_distanceCtrl.text);
    final rate = _parseMoney(_rateCtrl.text);
    final bonus = distance * rate;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text('Concluir rota', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.route.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _distanceCtrl,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _dialogDecoration(
                'KM real rodado',
                Icons.speed_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateCtrl,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: _dialogDecoration(
                'Valor por KM',
                Icons.payments_outlined,
              ),
            ),
            const SizedBox(height: 14),
            _Metric(
              icon: Icons.calculate_outlined,
              label: 'Bonus estimado: ${currency.format(bonus)}',
              color: AppColors.accentGold,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (distance <= 0 || rate < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Informe KM rodado e valor por KM validos.'),
                  backgroundColor: AppColors.accentRed,
                ),
              );
              return;
            }
            Navigator.of(
              context,
            ).pop(_CompletionResult(actualDistanceKm: distance, kmRate: rate));
          },
          child: const Text('Concluir'),
        ),
      ],
    );
  }
}

class _CompletionResult {
  final double actualDistanceKm;
  final double kmRate;

  const _CompletionResult({
    required this.actualDistanceKm,
    required this.kmRate,
  });
}

class _CandidateTile extends StatelessWidget {
  final Purchase purchase;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _CandidateTile({
    required this.purchase,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final pickup = purchase.fulfillmentType == PurchaseFulfillmentType.pickup;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!selected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.accentGold.withValues(alpha: 0.10)
                  : AppColors.primaryDark.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected
                    ? AppColors.accentGold.withValues(alpha: 0.55)
                    : AppColors.borderColor.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              activeColor: AppColors.accentGold,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Metric(
                        icon: purchase.fulfillmentType.icon,
                        label: purchase.fulfillmentType.routeLabel,
                        color:
                            pickup
                                ? AppColors.accentGold
                                : AppColors.accentBlue,
                      ),
                      _Metric(
                        icon: Icons.store_outlined,
                        label: purchase.supplierName,
                      ),
                      _Metric(
                        icon: Icons.business_outlined,
                        label: purchase.projectName,
                      ),
                      _Metric(
                        icon: Icons.attach_money,
                        label: currency.format(purchase.totalValue),
                        color: AppColors.accentGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (pickup && purchase.pickupAddress.trim().isNotEmpty)
                    _AddressLine(
                      label: 'Coleta',
                      value: purchase.pickupAddress.trim(),
                    ),
                  _AddressLine(
                    label: pickup ? 'Destino' : 'Entrega',
                    value: purchase.deliveryAddress.trim(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopLine extends StatelessWidget {
  final PurchaseDeliveryRouteStop stop;

  const _StopLine({required this.stop});

  @override
  Widget build(BuildContext context) {
    final color =
        stop.stopType == PurchaseRouteStopType.pickup
            ? AppColors.accentGold
            : AppColors.accentBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              stop.sequence.toString(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stop.stopType.label} - ${stop.supplierName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stop.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  final String label;
  final String value;

  const _AddressLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.75),
        ),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentGold, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _dialogDecoration(label, icon),
    );
  }
}

class _DateButton extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onPressed;

  const _DateButton({required this.date, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.event_outlined, size: 18),
      label: Text(date == null ? 'Data da rota' : dateFormat.format(date!)),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Metric({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: effectiveColor, size: 13),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStatusChip extends StatelessWidget {
  final PurchaseRouteStatus status;

  const _RouteStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PurchaseRouteStatus.planned => AppColors.accentGold,
      PurchaseRouteStatus.inProgress => AppColors.accentBlue,
      PurchaseRouteStatus.completed => AppColors.accentGreen,
      PurchaseRouteStatus.cancelled => AppColors.accentRed,
    };
    return _Metric(icon: Icons.circle, label: status.label, color: color);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

InputDecoration _dialogDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textMuted),
    prefixIcon: Icon(icon, color: AppColors.accentGold, size: 18),
    filled: true,
    fillColor: AppColors.primaryDark.withValues(alpha: 0.34),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: AppColors.borderColor.withValues(alpha: 0.7),
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.accentGold),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

double _parseMoney(String value) {
  final normalized = value.trim();
  if (normalized.contains(',')) {
    return double.tryParse(
          normalized.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
  }
  return double.tryParse(normalized) ?? 0;
}
