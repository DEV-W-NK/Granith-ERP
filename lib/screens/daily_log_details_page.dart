import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/daily_log_card/daily_log_form_dialog.dart';

class DailyLogDetailsPage extends StatelessWidget {
  final DailyLogModel log;

  const DailyLogDetailsPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.accentGold),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DailyLogFormDialog(log: log),
              );
            },
            tooltip: 'Editar Registro',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com Data e Projeto
            Text(
              log.projectName.toUpperCase(),
              style: const TextStyle(
                color: AppColors.accentBlue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(log.date),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Cartões de Clima e Mão de Obra
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Clima',
                    content: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWeatherColumn('Manhã', log.weatherMorning),
                        Container(width: 1, height: 40, color: Colors.white10),
                        _buildWeatherColumn('Tarde', log.weatherAfternoon),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Mão de Obra',
                    content: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.groups, color: AppColors.accentGold, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '${log.manpower.values.fold(0, (a, b) => a + b)} Operários',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Descrição das Atividades
            const Text(
              'Atividades Realizadas',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                log.activitiesDescription,
                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
              ),
            ),

            // Impedimentos (se houver)
            if (log.impediments.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Ocorrências & Impedimentos',
                style: TextStyle(color: AppColors.accentRed, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        log.impediments,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Galeria de Fotos
            if (log.photoUrls.isNotEmpty) ...[
              const Text(
                'Registro Fotográfico',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Ajuste para mobile/desktop se necessário
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: log.photoUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Expandir imagem (futuro)
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(log.photoUrls[index]),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildWeatherColumn(String label, WeatherCondition condition) {
    IconData icon;
    Color color;
    String text;

    switch (condition) {
      case WeatherCondition.sol:
        icon = Icons.wb_sunny_rounded; color = Colors.orangeAccent; text = 'Sol'; break;
      case WeatherCondition.nublado:
        icon = Icons.cloud_rounded; color = Colors.grey; text = 'Nublado'; break;
      case WeatherCondition.chuvoso:
        icon = Icons.water_drop_rounded; color = Colors.blueAccent; text = 'Chuva'; break;
      case WeatherCondition.tempestade:
        icon = Icons.flash_on_rounded; color = Colors.purpleAccent; text = 'Tempestade'; break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}