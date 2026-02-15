import 'package:flutter/material.dart';
import 'package:project_granith/widgets/home_page/stat_card.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/home_controller.dart';

class StatsGrid extends StatelessWidget {
  final bool isDesktop;
  final AnimationController animationController;

  const StatsGrid({
    super.key, 
    required this.isDesktop, 
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    // Ajuste de layout responsivo
    final crossAxisCount = isDesktop ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1);

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        // Aspect Ratio ajustado para o card não ficar muito esticado
        childAspectRatio: isDesktop ? 1.4 : 1.6,
      ),
      itemCount: controller.mainStats.length,
      itemBuilder: (context, index) {
        final stat = controller.mainStats[index];
        
        // Animação stagger (cascata)
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(
              0.2 + (index * 0.1), 
              0.6 + (index * 0.1), 
              curve: Curves.easeOutBack,
            ),
          ),
        );

        return ScaleTransition(
          scale: animation,
          child: StatCard(
            title: stat.title,
            value: stat.value,
            subtitle: stat.subtitle,
            icon: stat.icon,
            color: stat.color,
            trend: stat.trend,
            trendValue: stat.trendValue,
          ),
        );
      },
    );
  }
}