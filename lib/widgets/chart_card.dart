import 'package:flutter/material.dart';
import 'package:project_granith/models/statistics_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ChartData> chartData;
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),

            const SizedBox(height: 24),

            // Chart placeholder - aqui você pode integrar uma biblioteca de gráficos
            SizedBox(height: 200, child: _buildSimpleChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart() {
    if (chartType == ChartType.pie) {
      return _buildPieChart();
    } else {
      return _buildLineChart();
    }
  }

  Widget _buildPieChart() {
    return Row(
      children: [
        // Gráfico simulado
        Expanded(
          flex: 2,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryDark,
            ),
            child: const Center(
              child: Text(
                '24\nProjetos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Legenda
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                chartData.map((data) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: data.color ?? AppColors.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${data.label}: ${data.value.toInt()}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
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

  Widget _buildLineChart() {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: SimpleLinePainter(chartData),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Labels do eixo X
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              chartData.map((data) {
                return Text(
                  data.label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

// Simple line painter para demonstração
class SimpleLinePainter extends CustomPainter {
  final List<ChartData> data;

  SimpleLinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.accentGold
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].value / 500) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
