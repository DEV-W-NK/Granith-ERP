import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/themes/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final AnimationController animationController;

  const HomeHeader({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
    // Capitaliza a primeira letra
    final formattedDate = dateString.replaceFirst(dateString[0], dateString[0].toUpperCase());

    final headerAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: animationController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    return SlideTransition(
      position: headerAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Olá, Gestor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold, width: 2),
              ),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceDark,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}