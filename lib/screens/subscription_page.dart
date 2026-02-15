import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/widgets/subscription/subscription_dashboard.dart';
import 'package:project_granith/themes/app_theme.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubscriptionController(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text('Transparência & Custos'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: const SubscriptionDashboard(),
          ),
        ),
      ),
    );
  }
}