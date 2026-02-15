import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'dart:math' as math;

class SubscriptionDashboard extends StatefulWidget {
  const SubscriptionDashboard({super.key});

  @override
  State<SubscriptionDashboard> createState() => _SubscriptionDashboardState();
}

class _SubscriptionDashboardState extends State<SubscriptionDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionController>().loadUsageData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SubscriptionController>();
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    // Detecta se é uma tela grande (Desktop/Tablet Horizontal)
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Monitoramento de Recursos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // LayoutBuilder garante que podemos usar constraints da tela inteira
      body: LayoutBuilder(
        builder: (context, constraints) {
          return controller.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
              : controller.currentUsage == null
                  ? const Center(child: Text('Nenhum dado disponível', style: TextStyle(color: Colors.white)))
                  : SingleChildScrollView(
                      // Garante que o scroll view ocupe pelo menos a altura da tela
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabeçalho da Fatura Atual
                              _buildInvoiceHeader(controller.currentUsage!, currencyFormat),
                              
                              const SizedBox(height: 32),
                              
                              Text(
                                'Consumo em Tempo Real',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Gráficos Responsivos (Linha no Desktop, Coluna no Mobile)
                              _buildDetailedGraphs(controller.currentUsage!, isDesktop),

                              const SizedBox(height: 32),

                              // A Visão de "Valor Agregado"
                              _buildValueBreakdown(controller.currentUsage!, currencyFormat),
                            ],
                          ),
                        ),
                      ),
                    );
        },
      ),
    );
  }

  // --- GRÁFICOS RESPONSIVOS ---

  Widget _buildDetailedGraphs(UsageStatsModel usage, bool isDesktop) {
    // Lista dos cards de gráfico
    final graphs = [
      _buildGraphCard(
        title: "Banco de Dados",
        value: "${(usage.totalReads + usage.totalWrites) ~/ 1000}k",
        unit: "Operações (Leitura/Escrita)",
        mockData: [15, 22, 18, 25, 30, 28, 35, 42, 38, 45, 40, 50, 48, 55, 60], 
        color: Colors.blueAccent,
        icon: Icons.data_usage,
        type: _GraphType.line,
      ),
      _buildGraphCard(
        title: "Storage",
        value: usage.storageUsedMB.toStringAsFixed(0),
        unit: "MB Utilizados",
        mockData: [100, 102, 105, 108, 112, 115, 120, 125, 130, 135, 140, 145, 150, 152, 155],
        color: Colors.orangeAccent,
        icon: Icons.cloud_upload,
        type: _GraphType.area,
      ),
      _buildGraphCard(
        title: "Inteligência Artificial",
        value: usage.aiRequests.toString(),
        unit: "Análises Realizadas",
        mockData: [2, 5, 3, 8, 4, 10, 2, 5, 7, 12, 6, 8, 4, 9, 5],
        color: Colors.purpleAccent,
        icon: Icons.psychology,
        type: _GraphType.area,
      ),
    ];

    if (isDesktop) {
      // No Desktop: Exibe lado a lado (ocupa menos altura, preenche a tela)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: graphs[0]),
          const SizedBox(width: 16),
          Expanded(child: graphs[1]),
          const SizedBox(width: 16),
          Expanded(child: graphs[2]),
        ],
      );
    } else {
      // No Mobile: Empilha um embaixo do outro (scrolla para baixo)
      return Column(
        children: [
          graphs[0],
          const SizedBox(height: 16),
          graphs[1],
          const SizedBox(height: 16),
          graphs[2],
        ],
      );
    }
  }

  Widget _buildGraphCard({
    required String title,
    required String value,
    required String unit,
    required List<double> mockData,
    required Color color,
    required IconData icon,
    required _GraphType type,
  }) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header do Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(unit, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Área do Gráfico Visual
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: _MockChartPainter(
                data: mockData,
                color: color,
                type: type,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ANTIGOS MANTIDOS (Header e Breakdown) ---

  Widget _buildInvoiceHeader(UsageStatsModel usage, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentGold.withOpacity(0.2), AppColors.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fatura Estimada (Mês Atual)', 
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    format.format(usage.clientBillableAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text('ATIVO', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueBreakdown(UsageStatsModel usage, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Composição do Valor', 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          _buildBreakdownRow('Infraestrutura Cloud (Google)', usage.estimatedTechnicalCost, format, Colors.blueGrey),
          _buildBreakdownRow('Licença de Software & Suporte', usage.grossProfit, format, AppColors.accentGold, isBold: true),
          
          const Divider(color: Colors.white24, height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Estimado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                format.format(usage.clientBillableAmount),
                style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double value, NumberFormat format, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: Colors.white70, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
          Text(format.format(value), style: TextStyle(color: Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// --- PAINTERS E ENUMS ---

enum _GraphType { line, area, bar }

class _MockChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final _GraphType type;

  _MockChartPainter({required this.data, required this.color, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = type == _GraphType.bar ? PaintingStyle.fill : PaintingStyle.stroke;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.5), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final double widthStep = size.width / (data.length - 1);
    final double maxVal = data.reduce(math.max);
    final double minVal = data.reduce(math.min);
    // Evita divisão por zero se todos os dados forem iguais
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    if (type == _GraphType.bar) {
      // Desenha Barras
      final double barWidth = widthStep * 0.6;
      for (int i = 0; i < data.length; i++) {
        final double normalized = (data[i] - 0) / (maxVal * 1.2); // * 1.2 para dar respiro no topo
        final double barHeight = normalized * size.height;
        final double x = i * widthStep;
        final double y = size.height - barHeight;

        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        );
        canvas.drawRRect(r, paint);
      }
    } else {
      // Desenha Linha ou Área
      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final double normalized = (data[i] - minVal) / range;
        final double x = i * widthStep;
        // Invertemos Y porque 0 é no topo do canvas
        final double y = size.height - (normalized * size.height * 0.8) - (size.height * 0.1); 

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // Curva suave (Bézier)
          final double prevX = (i - 1) * widthStep;
          final double prevNormalized = (data[i - 1] - minVal) / range;
          final double prevY = size.height - (prevNormalized * size.height * 0.8) - (size.height * 0.1);
          
          final double controlX = prevX + (x - prevX) / 2;
          path.cubicTo(controlX, prevY, controlX, y, x, y);
        }
      }

      if (type == _GraphType.area) {
        // Fecha o caminho para preenchimento
        final fillPath = Path.from(path);
        fillPath.lineTo(size.width, size.height);
        fillPath.lineTo(0, size.height);
        fillPath.close();
        canvas.drawPath(fillPath, fillPaint);
        
        // Desenha a linha por cima para acabamento
        canvas.drawPath(path, paint..style = PaintingStyle.stroke);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}