import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'dart:math' as math;

enum ChartType { pie, line }

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic
  chartData; // Map<String, double> para Pie, List<double> para Line
  final ChartType chartType;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chartData,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: double.infinity,
            child:
                chartType == ChartType.pie
                    ? _buildPieChart(chartData as Map<String, double>)
                    : _buildLineChart(chartData as List<double>),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    // CustomPainter para desenhar um Donut Chart
    return Row(
      children: [
        Expanded(flex: 1, child: CustomPaint(painter: _PieChartPainter(data))),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                data.entries.map((entry) {
                  final color =
                      _PieChartPainter.colors[data.keys.toList().indexOf(
                            entry.key,
                          ) %
                          _PieChartPainter.colors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<double> data) {
    return CustomPaint(painter: _LineChartPainter(data));
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  static const List<Color> colors = [
    AppColors.accentGold,
    AppColors.accentBlue,
    AppColors.accentRed,
    AppColors.accentGreen,
  ];

  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.3;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    final total = data.values.reduce((a, b) => a + b);

    int i = 0;
    for (var entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final paint =
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      ); // -0.05 para dar um espacinho
      startAngle += sweepAngle;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;

  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.accentGold
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.accentGold.withOpacity(0.3),
              AppColors.accentGold.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    final path = Path();
    final widthStep = size.width / (data.length - 1);
    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final normalized = (data[i] - minVal) / range;
      final y =
          size.height - (normalized * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * widthStep;
        final prevNormalized = (data[i - 1] - minVal) / range;
        final prevY =
            size.height -
            (prevNormalized * size.height * 0.8) -
            (size.height * 0.1);

        final controlX = prevX + (x - prevX) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Pontos
    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final normalized = (data[i] - minVal) / range;
      final y =
          size.height - (normalized * size.height * 0.8) - (size.height * 0.1);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
