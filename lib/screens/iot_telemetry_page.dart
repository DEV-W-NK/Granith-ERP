import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/iot_telemetry_models.dart';
import 'package:project_granith/services/iot_telemetry_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';
import 'package:project_granith/widgets/iot/iot_device_provisioning_dialog.dart';

class IoTTelemetryPage extends StatefulWidget {
  const IoTTelemetryPage({super.key});

  @override
  State<IoTTelemetryPage> createState() => _IoTTelemetryPageState();
}

class _IoTTelemetryPageState extends State<IoTTelemetryPage> {
  static const _allFilter = '__all__';

  final IoTTelemetryService _service = IoTTelemetryService();
  Timer? _refreshTimer;
  IoTTelemetryDashboardData? _data;
  Object? _error;
  bool _loading = true;
  bool _refreshing = false;
  String _projectFilter = _allFilter;
  String _deviceFilter = _allFilter;
  _IoTPeriod _period = _IoTPeriod.last24Hours;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    setState(() {
      if (silent) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      final data = await _service.loadDashboard(
        from: DateTime.now().subtract(_period.duration),
        projectId: _filterValue(_projectFilter),
        deviceId: _filterValue(_deviceFilter),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  String? _filterValue(String value) => value == _allFilter ? null : value;

  void _selectProject(String value) {
    setState(() {
      _projectFilter = value;
      _deviceFilter = _allFilter;
    });
    _load();
  }

  void _selectDevice(String value) {
    setState(() => _deviceFilter = value);
    _load();
  }

  void _selectPeriod(_IoTPeriod value) {
    if (_period == value) return;
    setState(() => _period = value);
    _load();
  }

  Future<void> _openDeviceProvisioning() async {
    final kit = await showIoTDeviceProvisioningDialog(context);
    if (kit == null || !mounted) return;
    await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final data = _data;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.accentBlue,
          backgroundColor: AppColors.surfaceDark,
          onRefresh: _load,
          child: ListView(
            padding: ResponsiveLayout.pagePadding(width),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              GranithReveal(
                delay: const Duration(milliseconds: 40),
                child: _IoTHeader(
                  data: data,
                  refreshing: _refreshing,
                  onRefresh: _load,
                  onProvisionDevice: _openDeviceProvisioning,
                ),
              ),
              const SizedBox(height: 14),
              GranithReveal(
                delay: const Duration(milliseconds: 100),
                child: _IoTFilters(
                  data: data,
                  projectFilter: _projectFilter,
                  deviceFilter: _deviceFilter,
                  period: _period,
                  onProjectChanged: _selectProject,
                  onDeviceChanged: _selectDevice,
                  onPeriodChanged: _selectPeriod,
                ),
              ),
              const SizedBox(height: 14),
              if (_loading && data == null)
                const _IoTLoadingState()
              else if (_error != null && data == null)
                _IoTErrorState(error: _error!, onRetry: _load)
              else if (data != null) ...[
                if (_error != null) ...[
                  _IoTErrorNotice(error: _error!, onRetry: _load),
                  const SizedBox(height: 14),
                ],
                GranithReveal(
                  delay: const Duration(milliseconds: 160),
                  child: _IoTMetricGrid(data: data),
                ),
                const SizedBox(height: 14),
                GranithReveal(
                  delay: const Duration(milliseconds: 220),
                  child: _IoTChartWorkspace(data: data, period: _period),
                ),
                const SizedBox(height: 14),
                GranithReveal(
                  delay: const Duration(milliseconds: 280),
                  child: _IoTMonitoringDetail(data: data),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _IoTHeader extends StatelessWidget {
  const _IoTHeader({
    required this.data,
    required this.refreshing,
    required this.onRefresh,
    required this.onProvisionDevice,
  });

  final IoTTelemetryDashboardData? data;
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onProvisionDevice;

  @override
  Widget build(BuildContext context) {
    final latest = data?.latestReading;
    final recent = latest != null && _isRecent(latest.receivedAt);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 680;

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: AppDecorations.iconTile(AppColors.accentBlue),
          child: const Icon(
            Icons.sensors_rounded,
            color: AppColors.accentBlue,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monitoramento IoT',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Sinal, saúde do dispositivo e telemetria das obras em tempo operacional.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      children: [
        _HeaderStatus(
          icon: recent ? Icons.cloud_done_rounded : Icons.schedule_rounded,
          label:
              latest == null
                  ? 'Aguardando leitura'
                  : recent
                  ? 'Telemetria recebida'
                  : 'Sem leitura recente',
          color:
              latest == null
                  ? AppColors.textMuted
                  : recent
                  ? AppColors.accentGreen
                  : AppColors.accentGold,
        ),
        _HeaderStatus(
          icon: Icons.sync_rounded,
          label:
              data == null
                  ? 'Conectando'
                  : 'Atualizado ${_ageLabel(data!.loadedAt)}',
          color: AppColors.accentBlue,
        ),
        FilledButton.icon(
          onPressed: refreshing ? null : onProvisionDevice,
          icon: const Icon(Icons.add_to_queue_rounded),
          label: const Text('Novo sensor'),
        ),
        IconButton.filledTonal(
          tooltip: 'Atualizar telemetria',
          onPressed: refreshing ? null : onRefresh,
          icon:
              refreshing
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.refresh_rounded),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentBlue,
        emphasized: true,
        radius: 22,
      ),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [identity, const SizedBox(height: 14), actions],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 16),
                  actions,
                ],
              ),
    );
  }
}

class _HeaderStatus extends StatelessWidget {
  const _HeaderStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppDecorations.cardInnerSurface(accent: color, radius: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
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
}

class _IoTFilters extends StatelessWidget {
  const _IoTFilters({
    required this.data,
    required this.projectFilter,
    required this.deviceFilter,
    required this.period,
    required this.onProjectChanged,
    required this.onDeviceChanged,
    required this.onPeriodChanged,
  });

  static const _allFilter = '__all__';

  final IoTTelemetryDashboardData? data;
  final String projectFilter;
  final String deviceFilter;
  final _IoTPeriod period;
  final ValueChanged<String> onProjectChanged;
  final ValueChanged<String> onDeviceChanged;
  final ValueChanged<_IoTPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final projects =
        <String>{
            ...?data?.devices.map((item) => item.projectId),
            ...?data?.readings.map((item) => item.projectId),
          }.where((id) => id.trim().isNotEmpty).toList()
          ..sort();
    final selectedProject = projectFilter == _allFilter ? null : projectFilter;
    final devices = (data?.devices ?? const <IoTDeviceRecord>[])
        .where(
          (device) =>
              selectedProject == null || device.projectId == selectedProject,
        )
        .toList(growable: false);
    final validDeviceIds = devices.map((device) => device.id).toSet();
    final safeDeviceFilter =
        deviceFilter == _allFilter || validDeviceIds.contains(deviceFilter)
            ? deviceFilter
            : _allFilter;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.duskBlue,
        elevated: false,
        radius: 18,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AppDecorations.iconTile(AppColors.duskBlue),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.duskBlue,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leitura operacional',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Filtre por obra, dispositivo e janela de observação.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: narrow ? double.infinity : 260,
                    child: _IoTSelect(
                      label: 'Obra',
                      icon: Icons.business_rounded,
                      value: projectFilter,
                      items: [
                        const DropdownMenuItem(
                          value: _allFilter,
                          child: Text('Todas as obras'),
                        ),
                        ...projects.map(
                          (projectId) => DropdownMenuItem(
                            value: projectId,
                            child: Text(
                              data?.projectNameFor(projectId) ?? projectId,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: onProjectChanged,
                    ),
                  ),
                  SizedBox(
                    width: narrow ? double.infinity : 280,
                    child: _IoTSelect(
                      label: 'Sensor',
                      icon: Icons.sensors_rounded,
                      value: safeDeviceFilter,
                      items: [
                        const DropdownMenuItem(
                          value: _allFilter,
                          child: Text('Todos os sensores'),
                        ),
                        ...devices.map(
                          (device) => DropdownMenuItem(
                            value: device.id,
                            child: Text(
                              device.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: onDeviceChanged,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _IoTPeriod.values
                        .map(
                          (option) => ChoiceChip(
                            label: Text(option.label),
                            selected: option == period,
                            onSelected: (_) => onPeriodChanged(option),
                            selectedColor: AppColors.accentGold.withValues(
                              alpha: 0.18,
                            ),
                            backgroundColor: AppColors.surfaceDark,
                            side: BorderSide(
                              color:
                                  option == period
                                      ? AppColors.accentGold.withValues(
                                        alpha: 0.52,
                                      )
                                      : AppColors.borderColor.withValues(
                                        alpha: 0.56,
                                      ),
                            ),
                            labelStyle: TextStyle(
                              color:
                                  option == period
                                      ? AppColors.accentGold
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IoTSelect extends StatelessWidget {
  const _IoTSelect({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.borderColor,
        radius: 12,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                iconEnabledColor: AppColors.accentGold,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                selectedItemBuilder:
                    (context) => items
                        .map(
                          (item) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$label: ${(item.child as Text).data}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                items: items,
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IoTMetricGrid extends StatelessWidget {
  const _IoTMetricGrid({required this.data});

  final IoTTelemetryDashboardData data;

  @override
  Widget build(BuildContext context) {
    final latest = data.latestReading;
    final activeDevices =
        data.devices.where((device) => device.isActive).length;
    final recentDevices =
        data.devices
            .where(
              (device) =>
                  device.lastSeenAt != null && _isRecent(device.lastSeenAt!),
            )
            .length;
    final signal = latest?.rssiDbm ?? _latestDeviceRssi(data.devices);
    final signalMeta = _signalMeta(signal);
    final heap = latest?.freeHeap;
    final latestAt = latest?.receivedAt ?? _latestDeviceSeenAt(data.devices);

    final metrics = [
      _IoTMetric(
        label: 'Sensores ativos',
        value: '$activeDevices',
        detail:
            activeDevices == 0
                ? 'Nenhum sensor registrado'
                : '$recentDevices com contato recente',
        icon: Icons.sensors_rounded,
        color: AppColors.accentBlue,
      ),
      _IoTMetric(
        label: 'Sinal atual',
        value: signal == null ? '--' : '$signal dBm',
        detail: signalMeta.label,
        icon: signalMeta.icon,
        color: signalMeta.color,
      ),
      _IoTMetric(
        label: 'Memória livre',
        value: heap == null ? '--' : _formatBytes(heap),
        detail:
            heap == null
                ? 'Aguardando telemetria'
                : 'Heap informado pelo ESP32',
        icon: Icons.memory_rounded,
        color: AppColors.purple,
      ),
      _IoTMetric(
        label: 'Leituras no período',
        value: '${data.readings.length}',
        detail:
            latestAt == null
                ? 'Ainda não há dados'
                : 'Última ${_ageLabel(latestAt)}',
        icon: Icons.monitor_heart_rounded,
        color: AppColors.accentGold,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 560
                ? 1
                : constraints.maxWidth < 980
                ? 2
                : 4;
        const gap = 12.0;
        final tileWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: tileWidth,
                  child: _IoTMetricCard(metric: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _IoTMetric {
  const _IoTMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _IoTMetricCard extends StatelessWidget {
  const _IoTMetricCard({required this.metric});

  final _IoTMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(15),
      decoration: AppDecorations.statCardSurface(metric.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppDecorations.iconTile(metric.color),
                child: Icon(metric.icon, size: 18, color: metric.color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  metric.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: metric.color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            metric.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IoTChartWorkspace extends StatelessWidget {
  const _IoTChartWorkspace({required this.data, required this.period});

  final IoTTelemetryDashboardData data;
  final _IoTPeriod period;

  @override
  Widget build(BuildContext context) {
    final signalPoints = data.readings
        .where((item) => item.rssiDbm != null)
        .map((item) => _ChartPoint(item.receivedAt, item.rssiDbm!.toDouble()))
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    final heapPoints = data.readings
        .where((item) => item.freeHeap != null)
        .map((item) => _ChartPoint(item.receivedAt, item.freeHeap!.toDouble()))
        .toList(growable: false)
        .reversed
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final signalChart = _TelemetryLineChart(
          title: 'Qualidade do sinal',
          subtitle: 'RSSI recebido a cada publicação MQTT.',
          icon: Icons.network_cell_rounded,
          color: AppColors.accentBlue,
          points: signalPoints,
          period: period,
          valueLabel: (value) => '${value.toStringAsFixed(0)} dBm',
        );
        final heapChart = _TelemetryLineChart(
          title: 'Memória disponível',
          subtitle: 'Heap livre informado pelo dispositivo.',
          icon: Icons.memory_rounded,
          color: AppColors.purple,
          points: heapPoints,
          period: period,
          valueLabel: (value) => _formatBytes(value.round()),
        );

        if (compact) {
          return Column(
            children: [signalChart, const SizedBox(height: 14), heapChart],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: signalChart),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: heapChart),
          ],
        );
      },
    );
  }
}

class _ChartPoint {
  const _ChartPoint(this.timestamp, this.value);

  final DateTime timestamp;
  final double value;
}

class _TelemetryLineChart extends StatelessWidget {
  const _TelemetryLineChart({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.points,
    required this.period,
    required this.valueLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_ChartPoint> points;
  final _IoTPeriod period;
  final String Function(double value) valueLabel;

  @override
  Widget build(BuildContext context) {
    final sampled = _samplePoints(points, maximum: 90);
    final values = sampled.map((point) => point.value).toList(growable: false);
    final hasData = values.isNotEmpty;
    final minimum = hasData ? values.reduce(math.min) : 0.0;
    final maximum = hasData ? values.reduce(math.max) : 1.0;
    final range = math.max(1.0, maximum - minimum).toDouble();
    final minY = hasData ? minimum - range * 0.20 : 0.0;
    final maxY = hasData ? maximum + range * 0.20 : 1.0;
    final interval = math.max(1.0, (maxY - minY) / 4).toDouble();

    return Container(
      height: 344,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: AppDecorations.cardSurface(accent: color, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: AppDecorations.iconTile(color),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasData)
                Text(
                  valueLabel(sampled.last.value),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                hasData
                    ? LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: math.max(1, sampled.length - 1).toDouble(),
                        minY: minY,
                        maxY: maxY,
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor:
                                (_) => AppColors.surfaceDark.withValues(
                                  alpha: 0.96,
                                ),
                            getTooltipItems:
                                (spots) => spots
                                    .map((spot) {
                                      final index = spot.x.round().clamp(
                                        0,
                                        sampled.length - 1,
                                      );
                                      final point = sampled[index];
                                      return LineTooltipItem(
                                        '${_tooltipDate(point.timestamp)}\n${valueLabel(point.value)}',
                                        const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                          ),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine:
                              (_) => FlLine(
                                color: AppColors.borderColor.withValues(
                                  alpha: 0.32,
                                ),
                                strokeWidth: 1,
                              ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: interval,
                              getTitlesWidget:
                                  (value, meta) => SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      _axisValue(value),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 26,
                              interval: 1,
                              getTitlesWidget:
                                  (value, meta) => _chartTimeTitle(
                                    value,
                                    meta,
                                    sampled,
                                    period,
                                  ),
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: sampled
                                .asMap()
                                .entries
                                .map(
                                  (entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value.value,
                                  ),
                                )
                                .toList(growable: false),
                            isCurved: sampled.length > 2,
                            curveSmoothness: 0.22,
                            color: color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: sampled.length <= 12),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withValues(alpha: 0.28),
                                  color.withValues(alpha: 0.01),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : const _ChartEmptyState(),
          ),
        ],
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: AppColors.textMuted,
            size: 28,
          ),
          const SizedBox(height: 10),
          const Text(
            'Ainda não há leituras neste período.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IoTMonitoringDetail extends StatelessWidget {
  const _IoTMonitoringDetail({required this.data});

  final IoTTelemetryDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        final devices = _DeviceStatusPanel(data: data);
        final history = _TelemetryHistoryPanel(data: data);
        if (compact) {
          return Column(
            children: [devices, const SizedBox(height: 14), history],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: devices),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: history),
          ],
        );
      },
    );
  }
}

class _DeviceStatusPanel extends StatelessWidget {
  const _DeviceStatusPanel({required this.data});

  final IoTTelemetryDashboardData data;

  @override
  Widget build(BuildContext context) {
    final devices = data.devices.take(7).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentGreen,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.hub_rounded,
            color: AppColors.accentGreen,
            title: 'Estado dos sensores',
            subtitle: 'Visão rápida de conectividade por dispositivo.',
          ),
          const SizedBox(height: 14),
          if (devices.isEmpty)
            const _PanelEmptyState(
              icon: Icons.sensors_off_rounded,
              message: 'Nenhum sensor IoT disponível para este filtro.',
            )
          else ...[
            ...devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _DeviceStatusRow(
                  device: device,
                  projectName: data.projectNameFor(device.projectId),
                ),
              ),
            ),
            if (data.devices.length > devices.length)
              Text(
                '+ ${data.devices.length - devices.length} sensores no filtro atual',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DeviceStatusRow extends StatelessWidget {
  const _DeviceStatusRow({required this.device, required this.projectName});

  final IoTDeviceRecord device;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    final recent = device.lastSeenAt != null && _isRecent(device.lastSeenAt!);
    final signal = _signalMeta(device.lastRssiDbm);
    final color =
        !device.isActive
            ? AppColors.textMuted
            : recent
            ? signal.color
            : AppColors.accentGold;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.cardInnerSurface(accent: color, radius: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: AppDecorations.iconTile(color),
            child: Icon(
              recent ? Icons.sensors_rounded : Icons.sensors_off_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                device.lastRssiDbm == null ? '--' : '${device.lastRssiDbm} dBm',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                device.lastSeenAt == null
                    ? 'Sem leitura'
                    : _ageLabel(device.lastSeenAt!),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryHistoryPanel extends StatelessWidget {
  const _TelemetryHistoryPanel({required this.data});

  final IoTTelemetryDashboardData data;

  @override
  Widget build(BuildContext context) {
    final readings = data.readings.take(7).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentGold,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.accentGold,
                  title: 'Últimas leituras',
                  subtitle: 'Recebimentos persistidos no Supabase.',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: AppDecorations.cardInnerSurface(
                  accent: AppColors.accentGold,
                  radius: 9,
                ),
                child: Text(
                  '${data.readings.length} registro(s)',
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (readings.isEmpty)
            const _PanelEmptyState(
              icon: Icons.inbox_rounded,
              message: 'Aguardando a primeira publicação do sensor.',
            )
          else
            ...readings.map(
              (reading) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TelemetryHistoryRow(
                  reading: reading,
                  device: _deviceFor(data.devices, reading.deviceId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TelemetryHistoryRow extends StatelessWidget {
  const _TelemetryHistoryRow({required this.reading, required this.device});

  final IoTTelemetryReading reading;
  final IoTDeviceRecord? device;

  @override
  Widget build(BuildContext context) {
    final signal = _signalMeta(reading.rssiDbm);
    final timestamp = DateFormat('dd/MM HH:mm:ss').format(reading.receivedAt);
    final details = <String>[
      if (reading.freeHeap != null) '${_formatBytes(reading.freeHeap!)} livre',
      if (reading.firmwareVersion != null) 'FW ${reading.firmwareVersion}',
      'Seq. ${reading.sequence}',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: AppDecorations.cardInnerSurface(
        accent: signal.color,
        radius: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: AppDecorations.iconTile(signal.color),
            child: Icon(signal.icon, color: signal.color, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device?.displayName ?? reading.deviceId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details.join('  |  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reading.rssiDbm == null ? '--' : '${reading.rssiDbm} dBm',
                style: TextStyle(
                  color: signal.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timestamp,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: AppDecorations.iconTile(color),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelEmptyState extends StatelessWidget {
  const _PanelEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 28),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IoTLoadingState extends StatelessWidget {
  const _IoTLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentBlue,
        radius: 20,
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accentBlue),
            SizedBox(height: 14),
            Text(
              'Consultando telemetria dos sensores...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IoTErrorState extends StatelessWidget {
  const _IoTErrorState({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentRed,
        radius: 20,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.accentRed,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar a telemetria.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _friendlyError(error),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IoTErrorNotice extends StatelessWidget {
  const _IoTErrorNotice({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentRed,
        radius: 14,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _friendlyError(error),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tentar novamente',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentRed),
          ),
        ],
      ),
    );
  }
}

enum _IoTPeriod {
  last24Hours('24 h', Duration(hours: 24)),
  last7Days('7 dias', Duration(days: 7)),
  last30Days('30 dias', Duration(days: 30));

  const _IoTPeriod(this.label, this.duration);

  final String label;
  final Duration duration;
}

class _SignalMeta {
  const _SignalMeta(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

_SignalMeta _signalMeta(int? rssi) {
  if (rssi == null) {
    return const _SignalMeta(
      'Sem sinal informado',
      AppColors.textMuted,
      Icons.signal_cellular_off_rounded,
    );
  }
  if (rssi >= -67) {
    return const _SignalMeta(
      'Sinal excelente',
      AppColors.accentGreen,
      Icons.signal_cellular_4_bar_rounded,
    );
  }
  if (rssi >= -75) {
    return const _SignalMeta(
      'Sinal estável',
      AppColors.accentBlue,
      Icons.network_cell_rounded,
    );
  }
  if (rssi >= -85) {
    return const _SignalMeta(
      'Sinal fraco',
      AppColors.accentGold,
      Icons.signal_cellular_alt_2_bar_rounded,
    );
  }
  return const _SignalMeta(
    'Sinal crítico',
    AppColors.accentRed,
    Icons.signal_cellular_connected_no_internet_0_bar_rounded,
  );
}

bool _isRecent(DateTime timestamp) =>
    DateTime.now().difference(timestamp) <= const Duration(minutes: 20);

int? _latestDeviceRssi(List<IoTDeviceRecord> devices) {
  for (final device in devices) {
    if (device.lastRssiDbm != null) return device.lastRssiDbm;
  }
  return null;
}

DateTime? _latestDeviceSeenAt(List<IoTDeviceRecord> devices) {
  for (final device in devices) {
    if (device.lastSeenAt != null) return device.lastSeenAt;
  }
  return null;
}

IoTDeviceRecord? _deviceFor(List<IoTDeviceRecord> devices, String id) {
  for (final device in devices) {
    if (device.id == id) return device;
  }
  return null;
}

List<_ChartPoint> _samplePoints(
  List<_ChartPoint> points, {
  required int maximum,
}) {
  if (points.length <= maximum) return points;
  final sampled = <_ChartPoint>[];
  final step = (points.length - 1) / (maximum - 1);
  var previousIndex = -1;
  for (var position = 0; position < maximum; position++) {
    final index = (position * step).round().clamp(0, points.length - 1);
    if (index != previousIndex) sampled.add(points[index]);
    previousIndex = index;
  }
  return sampled;
}

Widget _chartTimeTitle(
  double value,
  TitleMeta meta,
  List<_ChartPoint> points,
  _IoTPeriod period,
) {
  final index = value.round();
  if (index < 0 || index >= points.length) return const SizedBox.shrink();
  final sections = math.min(4, points.length - 1);
  final interval = math.max(1, (points.length - 1) ~/ math.max(1, sections));
  if (index != 0 && index != points.length - 1 && index % interval != 0) {
    return const SizedBox.shrink();
  }
  final format =
      period == _IoTPeriod.last24Hours
          ? DateFormat('HH:mm')
          : DateFormat('dd/MM');
  return SideTitleWidget(
    meta: meta,
    child: Text(
      format.format(points[index].timestamp),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _axisValue(double value) {
  if (value.abs() >= 1024) return _formatBytes(value.round());
  return value.toStringAsFixed(0);
}

String _formatBytes(int value) {
  if (value < 1024) return '$value B';
  final kilobytes = value / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(0)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}

String _ageLabel(DateTime timestamp) {
  final elapsed = DateTime.now().difference(timestamp);
  if (elapsed.isNegative || elapsed.inSeconds < 15) return 'agora';
  if (elapsed.inMinutes < 1) return '${elapsed.inSeconds}s atrás';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} min atrás';
  if (elapsed.inDays < 1) return '${elapsed.inHours} h atrás';
  return '${elapsed.inDays} dia(s) atrás';
}

String _tooltipDate(DateTime timestamp) =>
    DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp);

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission denied') || message.contains('42501')) {
    return 'Seu acesso atual não possui permissão para consultar os sensores IoT.';
  }
  return message.replaceFirst('Exception: ', '');
}
