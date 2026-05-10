import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/ViewModels/DailyLogsViewModel.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_card.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_form_dialog.dart';
import 'package:provider/provider.dart';

class DailyLogsPageView extends StatelessWidget {
  const DailyLogsPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => DailyLogsViewModel(context.read<DailyLogController>()),
      child: const _DailyLogsPageContent(),
    );
  }
}

enum _DailyLogSignatureFilter { all, pending, signed, withoutCoordinator }

class _DailyLogsPageContent extends StatefulWidget {
  const _DailyLogsPageContent();

  @override
  State<_DailyLogsPageContent> createState() => _DailyLogsPageContentState();
}

class _DailyLogsPageContentState extends State<_DailyLogsPageContent> {
  static const _allProjects = '__all_projects__';

  String _selectedProjectId = _allProjects;
  DateTime? _selectedDate;
  _DailyLogSignatureFilter _signatureFilter = _DailyLogSignatureFilter.all;
  final Set<String> _signingLogIds = <String>{};

  void _openForm(BuildContext context, {DailyLogModel? log}) {
    if (log?.isSigned == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diario assinado nao pode ser editado.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DailyLogFormDialog(log: log),
    );
  }

  Future<void> _signLog(BuildContext context, DailyLogModel log) async {
    setState(() {
      _signingLogIds.add(log.id);
    });

    try {
      await context.read<DailyLogsViewModel>().signLog(log);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diario assinado pelo coordenador.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _signingLogIds.remove(log.id);
        });
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    return message.isEmpty ? 'Nao foi possivel assinar o diario.' : message;
  }

  List<DailyLogModel> _filteredLogs(List<DailyLogModel> logs) {
    return logs.where((log) {
      final matchesProject =
          _selectedProjectId == _allProjects ||
          log.projectId == _selectedProjectId;
      final matchesDate =
          _selectedDate == null || DateUtils.isSameDay(log.date, _selectedDate);
      final matchesSignature = switch (_signatureFilter) {
        _DailyLogSignatureFilter.all => true,
        _DailyLogSignatureFilter.pending => log.isPendingSignature,
        _DailyLogSignatureFilter.signed => log.isSigned,
        _DailyLogSignatureFilter.withoutCoordinator =>
          !log.hasCoordinator && !log.isSigned,
      };

      return matchesProject && matchesDate && matchesSignature;
    }).toList();
  }

  List<DropdownMenuItem<String>> _projectItems(List<DailyLogModel> logs) {
    final seen = <String>{};
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: _allProjects,
        child: Text('Todas as obras'),
      ),
    ];

    for (final log in logs) {
      if (log.projectId.trim().isEmpty || seen.contains(log.projectId)) {
        continue;
      }
      seen.add(log.projectId);
      items.add(
        DropdownMenuItem(value: log.projectId, child: Text(log.projectName)),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 768;
    final viewModel = context.watch<DailyLogsViewModel>();
    final logs = viewModel.logs;
    final filteredLogs = _filteredLogs(logs);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: ResponsiveLayout.pagePadding(width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DailyLogsHeader(
              isDesktop: isDesktop,
              onNewLog: () => _openForm(context),
            ),
            if (!isDesktop) ...[
              const SizedBox(height: 16),
              const _AiInsightsButton(fullWidth: true),
            ],
            SizedBox(height: isDesktop ? 24 : 18),
            _DailyLogsSummaryStrip(logs: logs),
            const SizedBox(height: 14),
            _DailyLogsFilters(
              projectValue: _selectedProjectId,
              projectItems: _projectItems(logs),
              dateValue: _selectedDate,
              signatureValue: _signatureFilter,
              onProjectChanged: (value) {
                setState(() => _selectedProjectId = value ?? _allProjects);
              },
              onDateChanged: (value) {
                setState(() => _selectedDate = value);
              },
              onSignatureChanged: (value) {
                setState(
                  () =>
                      _signatureFilter = value ?? _DailyLogSignatureFilter.all,
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  viewModel.isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                        ),
                      )
                      : logs.isEmpty
                      ? const _DailyLogsEmptyState()
                      : filteredLogs.isEmpty
                      ? const _DailyLogsNoResultsState()
                      : ListView.separated(
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return DailyLogCard(
                            log: log,
                            onEdit:
                                log.isSigned
                                    ? null
                                    : () => _openForm(context, log: log),
                            onSign:
                                log.isPendingSignature
                                    ? () => _signLog(context, log)
                                    : null,
                            isSigning: _signingLogIds.contains(log.id),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          !isDesktop
              ? FloatingActionButton(
                onPressed: () => _openForm(context),
                backgroundColor: AppColors.accentGold,
                child: const Icon(Icons.add, color: AppColors.primaryDark),
              )
              : null,
    );
  }
}

class _DailyLogsHeader extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onNewLog;

  const _DailyLogsHeader({required this.isDesktop, required this.onNewLog});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diário de Obras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registro diario, assinatura do coordenador e liberacao para o cliente',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop)
          Row(
            children: [
              const _AiInsightsButton(),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: onNewLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Novo Registro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _DailyLogsSummaryStrip extends StatelessWidget {
  const _DailyLogsSummaryStrip({required this.logs});

  final List<DailyLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final signed = logs.where((log) => log.isSigned).length;
    final pending = logs.where((log) => log.isPendingSignature).length;
    final unlocked = logs.where((log) => !log.isSigned).length;
    final withoutCoordinator =
        logs.where((log) => !log.hasCoordinator && !log.isSigned).length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          label: 'Registros',
          value: logs.length.toString(),
          color: AppColors.accentBlue,
          icon: Icons.menu_book_rounded,
        ),
        _SummaryCard(
          label: 'Assinados',
          value: signed.toString(),
          color: AppColors.accentGreen,
          icon: Icons.verified_rounded,
        ),
        _SummaryCard(
          label: 'Pendentes',
          value: pending.toString(),
          color: AppColors.accentGold,
          icon: Icons.pending_actions_rounded,
        ),
        _SummaryCard(
          label: 'Editaveis',
          value: unlocked.toString(),
          color: AppColors.auraCyan,
          icon: Icons.edit_note_rounded,
        ),
        if (withoutCoordinator > 0)
          _SummaryCard(
            label: 'Sem coordenador',
            value: withoutCoordinator.toString(),
            color: AppColors.accentRed,
            icon: Icons.person_off_rounded,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyLogsFilters extends StatelessWidget {
  const _DailyLogsFilters({
    required this.projectValue,
    required this.projectItems,
    required this.dateValue,
    required this.signatureValue,
    required this.onProjectChanged,
    required this.onDateChanged,
    required this.onSignatureChanged,
  });

  final String projectValue;
  final List<DropdownMenuItem<String>> projectItems;
  final DateTime? dateValue;
  final _DailyLogSignatureFilter signatureValue;
  final ValueChanged<String?> onProjectChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<_DailyLogSignatureFilter?> onSignatureChanged;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        dateValue == null
            ? 'Todas as datas'
            : DateFormat('dd/MM/yyyy').format(dateValue!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.46),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 920;
          final projectFilter = _FilterShell(
            child: DropdownButtonFormField<String>(
              initialValue:
                  projectItems.any((item) => item.value == projectValue)
                      ? projectValue
                      : _DailyLogsPageContentState._allProjects,
              isExpanded: true,
              items: projectItems,
              onChanged: onProjectChanged,
              decoration: _filterDecoration(
                label: 'Obra',
                icon: Icons.business_rounded,
              ),
            ),
          );
          final signatureFilter = _FilterShell(
            child: DropdownButtonFormField<_DailyLogSignatureFilter>(
              initialValue: signatureValue,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: _DailyLogSignatureFilter.all,
                  child: Text('Todos os status'),
                ),
                DropdownMenuItem(
                  value: _DailyLogSignatureFilter.pending,
                  child: Text('Pendentes'),
                ),
                DropdownMenuItem(
                  value: _DailyLogSignatureFilter.signed,
                  child: Text('Assinados'),
                ),
                DropdownMenuItem(
                  value: _DailyLogSignatureFilter.withoutCoordinator,
                  child: Text('Sem coordenador'),
                ),
              ],
              onChanged: onSignatureChanged,
              decoration: _filterDecoration(
                label: 'Assinatura',
                icon: Icons.verified_user_outlined,
              ),
            ),
          );
          final dateFilter = _FilterShell(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dateValue ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  onDateChanged(picked);
                }
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(dateLabel, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 17,
                ),
                side: BorderSide(
                  color: AppColors.borderColor.withValues(alpha: 0.56),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
          final clearDate =
              dateValue == null
                  ? const SizedBox.shrink()
                  : IconButton(
                    tooltip: 'Limpar data',
                    onPressed: () => onDateChanged(null),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textMuted,
                  );

          if (isNarrow) {
            return Column(
              children: [
                projectFilter,
                const SizedBox(height: 10),
                signatureFilter,
                const SizedBox(height: 10),
                Row(children: [Expanded(child: dateFilter), clearDate]),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: projectFilter),
              const SizedBox(width: 12),
              Expanded(child: signatureFilter),
              const SizedBox(width: 12),
              Expanded(child: dateFilter),
              clearDate,
            ],
          );
        },
      ),
    );
  }

  InputDecoration _filterDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.accentGold, size: 19),
      filled: true,
      fillColor: AppColors.backgroundMid.withValues(alpha: 0.58),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.borderColor.withValues(alpha: 0.56),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.borderColor.withValues(alpha: 0.56),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

class _FilterShell extends StatelessWidget {
  const _FilterShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
          labelStyle: const TextStyle(color: AppColors.textMuted),
        ),
      ),
      child: child,
    );
  }
}

class _AiInsightsButton extends StatelessWidget {
  final bool fullWidth;
  const _AiInsightsButton({this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DailyLogsViewModel>();

    return Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.8),
            const Color(0xFF673AB7).withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF673AB7).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(viewModel.getAiInsight())));
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Insights IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyLogsEmptyState extends StatelessWidget {
  const _DailyLogsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum diário registrado',
            style: TextStyle(color: AppColors.textMuted, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Registre o progresso das obras hoje para gerar historico.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DailyLogsNoResultsState extends StatelessWidget {
  const _DailyLogsNoResultsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhum diario encontrado com os filtros selecionados.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 16),
      ),
    );
  }
}
