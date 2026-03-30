import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/models/reports_chart_models.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg       = Color(0xFF0F1117);
  static const s1       = Color(0xFF161B27);
  static const s2       = Color(0xFF1C2333);
  static const s3       = Color(0xFF222A3D);
  static const border   = Color(0x12FFFFFF);
  static const border2  = Color(0x1FFFFFFF);
  static const gold     = Color(0xFFC9A84C);
  static const gold2    = Color(0xFFE8C56A);
  static const goldDim  = Color(0x22C9A84C);
  static const tx       = Color(0xFFE8EAF0);
  static const tx2      = Color(0xFF8B93A8);
  static const tx3      = Color(0xFF5A6178);
  static const green    = Color(0xFF3ECF8E);
  static const greenDim = Color(0x1A3ECF8E);
  static const red      = Color(0xFFF87171);
  static const redDim   = Color(0x1AF87171);
  static const orange   = Color(0xFFFB923C);
  static const blue     = Color(0xFF60A5FA);
  static const purple   = Color(0xFFA78BFA);
  static const List<Color> chartColors = [green, blue, gold, orange, purple, red];
}

final _brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // ── Dados reais do Firestore ──────────────────────────────────────────────
  List<Map<String, dynamic>>  _dreData     = [];
  List<MonthlyChartData>      _monthlyData = [];
  List<CategoryChartData>     _categoryData= [];
  bool _loading = true;

  int _touchedDonut = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ctrl = context.read<ReportsController>();

    final results = await Future.wait([
      ctrl.generateReport('financial_dre'),
      ctrl.fetchMonthlyData(),
      ctrl.fetchExpensesByCategory(),
    ]);

    if (!mounted) return;
    setState(() {
      _dreData      = results[0] as List<Map<String, dynamic>>;
      _monthlyData  = results[1] as List<MonthlyChartData>;
      _categoryData = results[2] as List<CategoryChartData>;
      _loading      = false;
    });
  }

  // ── Totais derivados do DRE real ──────────────────────────────────────────
  double get _totalIncome {
    for (final r in _dreData) {
      if (r['concept'] == 'Receita Bruta') {
        return (r['value'] as num?)?.toDouble() ?? 0;
      }
    }
    return 0;
  }

  double get _totalExpense {
    double t = 0;
    for (final r in _dreData) {
      if (r['isHeader'] != true && r['isResult'] != true) {
        final v = (r['value'] as num?)?.toDouble() ?? 0;
        if (v < 0) t += v.abs();
      }
    }
    return t;
  }

  double get _netProfit {
    for (final r in _dreData) {
      if (r['highlight'] == true) return (r['value'] as num?)?.toDouble() ?? 0;
    }
    return _totalIncome - _totalExpense;
  }

  double get _margin =>
      _totalIncome > 0 ? (_netProfit / _totalIncome * 100) : 0;

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ctrl      = context.watch<ReportsController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _C.bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _C.gold, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load,
              color: _C.gold,
              backgroundColor: _C.s2,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 28 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(ctrl),
                    const SizedBox(height: 18),
                    _buildStatCards(isDesktop),
                    const SizedBox(height: 14),
                    isDesktop ? _buildMidRow() : _buildMidRowMobile(),
                    const SizedBox(height: 14),
                    isDesktop ? _buildBottomRow() : _buildBottomRowMobile(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(ReportsController ctrl) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _C.goldDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.gold.withOpacity(0.3)),
        ),
        child: const Icon(Icons.bar_chart_rounded, color: _C.gold, size: 20),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DRE Gerencial',
              style: TextStyle(color: _C.tx, fontSize: 17,
                  fontWeight: FontWeight.w600, letterSpacing: -0.3)),
          SizedBox(height: 2),
          Text('Demonstrativo de resultado do exercício',
              style: TextStyle(color: _C.tx3, fontSize: 12)),
        ]),
      ),
      // Filtro rápido de período
      _PeriodSelector(
        from: ctrl.periodFrom,
        to:   ctrl.periodTo,
        onYear:  () { ctrl.setCurrentYear();  _load(); },
        onMonth: () { ctrl.setCurrentMonth(); _load(); },
        onClear: () { ctrl.clearPeriod();     _load(); },
      ),
    ]);
  }

  // ── STAT CARDS ────────────────────────────────────────────────────────────
  Widget _buildStatCards(bool isDesktop) {
    // Variação mês anterior — calcula dos dados mensais reais
    final currentMonth = _monthlyData.isNotEmpty ? _monthlyData.last : null;
    final prevMonth    = _monthlyData.length > 1
        ? _monthlyData[_monthlyData.length - 2]
        : null;

    String incDelta = '—';
    bool   incUp    = true;
    if (currentMonth != null && prevMonth != null && prevMonth.income > 0) {
      final pct = ((currentMonth.income - prevMonth.income) / prevMonth.income * 100);
      incDelta = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% vs mês anterior';
      incUp    = pct >= 0;
    }

    final cards = [
      _StatCard(
        label:    'RECEITA TOTAL',
        value:    _brl.format(_totalIncome),
        delta:    incDelta,
        deltaUp:  incUp,
        accent:   _C.green,
      ),
      _StatCard(
        label:    'DESPESAS TOTAIS',
        value:    _brl.format(_totalExpense),
        delta:    _dreData.isEmpty ? '—' : 'No período selecionado',
        deltaUp:  false,
        accent:   _C.red,
      ),
      _StatCard(
        label:    'LUCRO LÍQUIDO',
        value:    _brl.format(_netProfit),
        delta:    'Margem ${_margin.toStringAsFixed(1)}%',
        deltaUp:  _netProfit >= 0,
        accent:   _C.gold,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .expand((c) => [Expanded(child: c), const SizedBox(width: 12)])
            .toList()
          ..removeLast(),
      );
    }
    return Column(
      children: cards
          .expand((c) => [c, const SizedBox(height: 10)])
          .toList()
        ..removeLast(),
    );
  }

  // ── MID ROW ───────────────────────────────────────────────────────────────
  Widget _buildMidRow() => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 2, child: _BarChartCard(data: _monthlyData)),
          const SizedBox(width: 14),
          Expanded(flex: 1, child: _GaugeCard(margin: _margin)),
        ]),
      );

  Widget _buildMidRowMobile() => Column(children: [
        _BarChartCard(data: _monthlyData),
        const SizedBox(height: 14),
        _GaugeCard(margin: _margin),
      ]);

  // ── BOTTOM ROW ────────────────────────────────────────────────────────────
  Widget _buildBottomRow() => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              flex: 1,
              child: _DonutCard(
                data:    _categoryData,
                touched: _touchedDonut,
                onTouch: (i) => setState(() => _touchedDonut = i),
              )),
          const SizedBox(width: 14),
          Expanded(flex: 2, child: _LineChartCard(data: _monthlyData)),
        ]),
      );

  Widget _buildBottomRowMobile() => Column(children: [
        _DonutCard(
          data:    _categoryData,
          touched: _touchedDonut,
          onTouch: (i) => setState(() => _touchedDonut = i),
        ),
        const SizedBox(height: 14),
        _LineChartCard(data: _monthlyData),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// PERIOD SELECTOR
// ─────────────────────────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onYear, onMonth, onClear;

  const _PeriodSelector({
    required this.from, required this.to,
    required this.onYear, required this.onMonth, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasPeriod = from != null;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _PeriodBtn(label: 'Ano',  onTap: onYear),
      const SizedBox(width: 6),
      _PeriodBtn(label: 'Mês',  onTap: onMonth),
      if (hasPeriod) ...[
        const SizedBox(width: 6),
        _PeriodBtn(label: 'Limpar', onTap: onClear, active: true),
      ],
    ]);
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _PeriodBtn({required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color:  active ? _C.goldDim : _C.s2,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: active ? _C.gold.withOpacity(0.4) : _C.border2),
          ),
          child: Text(label,
              style: TextStyle(
                color: active ? _C.gold : _C.tx3,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED CARD SHELL
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _C.s1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: child,
      );
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
              color: _C.tx2, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 0.8,
            )),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, delta;
  final bool deltaUp;
  final Color accent;

  const _StatCard({
    required this.label, required this.value,
    required this.delta, required this.deltaUp, required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: _C.s1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 28, height: 2,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  color: _C.tx3, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  color: accent, fontSize: 18,
                  fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(
                deltaUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: deltaUp ? _C.green : _C.red),
            const SizedBox(width: 3),
            Flexible(
              child: Text(delta,
                  style: TextStyle(
                      color: deltaUp ? _C.green : _C.red, fontSize: 10)),
            ),
          ]),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BAR CHART — dados reais
// ─────────────────────────────────────────────────────────────────────────────
class _BarChartCard extends StatefulWidget {
  final List<MonthlyChartData> data;
  const _BarChartCard({required this.data});

  @override
  State<_BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<_BarChartCard> {
  int _touched = -1;

  double get _maxY {
    if (widget.data.isEmpty) return 100;
    final values = widget.data
        .expand((d) => [d.income, d.expense])
        .toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max * 1.2).ceilToDouble();
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CardTitle('Receita vs Despesa — mensal'),
          const SizedBox(height: 60),
          const Center(child: Text('Sem dados no período',
              style: TextStyle(color: _C.tx3, fontSize: 12))),
        ]),
      );
    }

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Receita vs Despesa — mensal'),
        Row(children: [
          _LegDot(color: _C.green, label: 'Receita'),
          const SizedBox(width: 14),
          _LegDot(color: _C.red,   label: 'Despesa'),
          const SizedBox(width: 14),
          _LegDot(color: _C.gold,  label: 'Lucro'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _maxY,
              minY: 0,
              barTouchData: BarTouchData(
                touchCallback: (evt, resp) => setState(() {
                  _touched = resp?.spot?.touchedBarGroupIndex ?? -1;
                }),
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => _C.s3,
                  getTooltipItem: (group, _, rod, rodIdx) {
                    final d      = widget.data[group.x];
                    final labels = ['Receita', 'Despesa', 'Lucro'];
                    final values = [d.income, d.expense, d.profit];
                    return BarTooltipItem(
                      '${d.label}\n${labels[rodIdx]}: ${_fmt(values[rodIdx])}',
                      const TextStyle(color: _C.tx, fontSize: 11, height: 1.5),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= widget.data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(widget.data[i].label,
                          style: const TextStyle(color: _C.tx3, fontSize: 9)),
                    );
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 52,
                  getTitlesWidget: (v, _) => Text(_fmt(v),
                      style: const TextStyle(color: _C.tx3, fontSize: 9)),
                )),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0x0AFFFFFF), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(widget.data.length, (i) {
                final d         = widget.data[i];
                final isTouched = i == _touched;
                return BarChartGroupData(x: i, barRods: [
                  _rod(d.income,  _C.green, isTouched),
                  _rod(d.expense, _C.red,   isTouched),
                  _rod(d.profit,  _C.gold,  isTouched),
                ]);
              }),
            ),
            swapAnimationDuration: const Duration(milliseconds: 300),
          ),
        ),
      ]),
    );
  }

  BarChartRodData _rod(double y, Color color, bool touched) => BarChartRodData(
        toY:    y.clamp(0, double.infinity),
        color:  color.withOpacity(touched ? 1.0 : 0.7),
        width:  5,
        borderRadius: BorderRadius.circular(3),
        backDrawRodData: BackgroundBarChartRodData(
          show: true, toY: _maxY, color: color.withOpacity(0.04),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// GAUGE CARD — usa _margin derivado do DRE real (inalterado)
// ─────────────────────────────────────────────────────────────────────────────
class _GaugeCard extends StatelessWidget {
  final double margin;
  const _GaugeCard({required this.margin});

  @override
  Widget build(BuildContext context) {
    const target    = 28.0;
    final isOnTarget= margin >= target;

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _CardTitle('Margem de lucro'),
        const SizedBox(height: 4),
        SizedBox(
          height: 150,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            PieChart(PieChartData(
              startDegreeOffset: 180,
              sectionsSpace: 0,
              centerSpaceRadius: 52,
              sections: [
                PieChartSectionData(
                  value: margin.clamp(0, 100),
                  color: isOnTarget ? _C.green : _C.gold,
                  radius: 18, showTitle: false,
                ),
                PieChartSectionData(
                  value: (target - margin).clamp(0, 100),
                  color: _C.tx3.withOpacity(0.25),
                  radius: 18, showTitle: false,
                ),
                PieChartSectionData(
                  value: (100 - target).clamp(0, 100),
                  color: Colors.transparent,
                  radius: 18, showTitle: false,
                ),
              ],
            )),
            Positioned(
              bottom: 6,
              child: Column(children: [
                Text('${margin.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: _C.gold2, fontSize: 26,
                        fontWeight: FontWeight.w700, letterSpacing: -1)),
                const Text('Meta: 28%',
                    style: TextStyle(color: _C.tx3, fontSize: 10)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: _C.s2, borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _C.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _MiniMetric(label: 'Meta',    value: '${target.toStringAsFixed(0)}%', color: _C.tx2),
            Container(width: 1, height: 28, color: _C.border),
            _MiniMetric(label: 'Atual',   value: '${margin.toStringAsFixed(1)}%',
                color: isOnTarget ? _C.green : _C.gold),
            Container(width: 1, height: 28, color: _C.border),
            _MiniMetric(label: 'Status',
                value: isOnTarget ? 'Atingiu' : 'Abaixo',
                color: isOnTarget ? _C.green : _C.red),
          ]),
        ),
      ]),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: const TextStyle(
                color: _C.tx3, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// DONUT CARD — dados reais por categoria
// ─────────────────────────────────────────────────────────────────────────────
class _DonutCard extends StatelessWidget {
  final List<CategoryChartData> data;
  final int touched;
  final ValueChanged<int> onTouch;
  const _DonutCard({required this.data, required this.touched, required this.onTouch});

  double get _total => data.fold(0.0, (double s, e) => s + e.value);

  String _fmt(double v) {
    if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CardTitle('Composição das despesas'),
          const SizedBox(height: 60),
          const Center(child: Text('Sem despesas no período',
              style: TextStyle(color: _C.tx3, fontSize: 12))),
        ]),
      );
    }

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Composição das despesas'),
        SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (evt, resp) {
                  onTouch(evt is FlTapUpEvent
                      ? (resp?.touchedSection?.touchedSectionIndex ?? -1)
                      : touched);
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 54,
              sections: List.generate(data.length, (i) {
                final d         = data[i];
                final color     = _C.chartColors[i % _C.chartColors.length];
                final isTouched = i == touched;
                final pct       = _total > 0
                    ? (d.value / _total * 100).toStringAsFixed(0)
                    : '0';
                return PieChartSectionData(
                  value:     d.value,
                  color:     color.withOpacity(isTouched ? 1.0 : 0.75),
                  radius:    isTouched ? 26 : 20,
                  showTitle: isTouched,
                  title:     '$pct%',
                  titleStyle: const TextStyle(
                      color: _C.tx, fontSize: 11, fontWeight: FontWeight.w700),
                );
              }),
            ),
            swapAnimationDuration: const Duration(milliseconds: 250),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(data.length, (i) {
          final d     = data[i];
          final color = _C.chartColors[i % _C.chartColors.length];
          final pct   = _total > 0
              ? (d.value / _total * 100).toStringAsFixed(0)
              : '0';
          return _DonutLegRow(
            color:     color,
            label:     d.label,
            value:     _fmt(d.value),
            pct:       '$pct%',
            highlight: i == touched,
            onTap:     () => onTouch(i == touched ? -1 : i),
          );
        }),
      ]),
    );
  }
}

class _DonutLegRow extends StatelessWidget {
  final Color color;
  final String label, value, pct;
  final bool highlight;
  final VoidCallback onTap;
  const _DonutLegRow({
    required this.color, required this.label, required this.value,
    required this.pct, required this.highlight, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            color: highlight ? color.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(label,
                style: TextStyle(
                  color: highlight ? _C.tx : _C.tx2, fontSize: 11,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                ))),
            Text(value,
                style: const TextStyle(
                    color: _C.tx, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            SizedBox(width: 30, child: Text(pct,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: highlight ? color : _C.tx3, fontSize: 10))),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LINE CHART — dados reais (lucro mensal)
// ─────────────────────────────────────────────────────────────────────────────
class _LineChartCard extends StatelessWidget {
  final List<MonthlyChartData> data;
  const _LineChartCard({required this.data});

  List<FlSpot> _spots(List<double> values) =>
      List.generate(values.length,
          (i) => FlSpot(i.toDouble(), values[i]));

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _CardTitle('Evolução do lucro líquido'),
          const SizedBox(height: 60),
          const Center(child: Text('Sem dados no período',
              style: TextStyle(color: _C.tx3, fontSize: 12))),
        ]),
      );
    }

    final profits = data.map((d) => d.profit).toList();
    final incomes = data.map((d) => d.income).toList();
    final allVals = <double>[...profits, ...incomes];
    final minY    = allVals.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY    = allVals.reduce((a, b) => a > b ? a : b) * 1.1;

    String fmt(double v) {
      if (v.abs() >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
      if (v.abs() >= 1000)    return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
      return 'R\$ ${v.toStringAsFixed(0)}';
    }

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _CardTitle('Evolução do lucro líquido'),
        Row(children: [
          _LegDot(color: _C.gold,  label: 'Lucro líquido'),
          const SizedBox(width: 14),
          _LegDot(color: _C.green, label: 'Receita', dashed: true),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: LineChart(
            LineChartData(
              minY: minY, maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _C.s3,
                  getTooltipItems: (spots) => spots.map((s) {
                    final label = s.barIndex == 0 ? 'Lucro' : 'Receita';
                    final color = s.barIndex == 0 ? _C.gold : _C.green;
                    final month = data[s.x.toInt()].label;
                    return LineTooltipItem(
                      '$month · $label\n${fmt(s.y)}',
                      TextStyle(color: color, fontSize: 11, height: 1.5),
                    );
                  }).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 24, interval: 1,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(data[i].label,
                          style: const TextStyle(color: _C.tx3, fontSize: 9)),
                    );
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 52,
                  getTitlesWidget: (v, _) =>
                      Text(fmt(v), style: const TextStyle(color: _C.tx3, fontSize: 9)),
                )),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0x0AFFFFFF), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Lucro líquido
                LineChartBarData(
                  spots:  _spots(profits),
                  color:  _C.gold, barWidth: 2.5,
                  isCurved: true, curveSmoothness: 0.35,
                  dotData: FlDotData(
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3.5, color: _C.gold,
                      strokeWidth: 1.5, strokeColor: _C.s1,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [_C.gold.withOpacity(0.18), _C.gold.withOpacity(0.0)],
                    ),
                  ),
                ),
                // Receita (linha de referência)
                LineChartBarData(
                  spots:  _spots(incomes),
                  color:  _C.green, barWidth: 1.5,
                  isCurved: true, curveSmoothness: 0.35,
                  dashArray: [6, 5],
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGEND DOT
// ─────────────────────────────────────────────────────────────────────────────
class _LegDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegDot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        dashed
            ? SizedBox(
                width: 14, height: 2,
                child: CustomPaint(painter: _DashPainter(color)),
              )
            : Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: _C.tx2, fontSize: 11)),
      ]);
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(x + 4, size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}