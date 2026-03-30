import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/screens/daily_log_details_page.dart';
import 'package:project_granith/themes/app_theme.dart';

class DailyLogCard extends StatelessWidget {
  final DailyLogModel log;

  const DailyLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // NAVEGAÇÃO PARA A TELA DE DETALHES
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyLogDetailsPage(log: log),
              ),  
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna de Data
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        log.date.day.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM', 'pt_BR').format(log.date).toUpperCase(),
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),

                // Conteúdo Principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.projectName,
                              style: const TextStyle(color: AppColors.accentBlue, fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (log.photoUrls.isNotEmpty)
                             Row(
                               children: [
                                 const Icon(Icons.photo_camera, size: 14, color: AppColors.textSecondary),
                                 const SizedBox(width: 4),
                                 Text('${log.photoUrls.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                               ],
                             )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.activitiesDescription,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      
                      // Footer
                      Row(
                        children: [
                          _buildWeatherIcon(log.weatherMorning),
                          const SizedBox(width: 8),
                          _buildWeatherIcon(log.weatherAfternoon),
                          const Spacer(),
                          const Icon(Icons.group, color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${log.manpower.values.fold(0, (a, b) => a + b)} Op.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherIcon(WeatherCondition condition) {
    IconData icon;
    Color color;
    switch (condition) {
      case WeatherCondition.sol: icon = Icons.wb_sunny; color = Colors.orangeAccent; break;
      case WeatherCondition.nublado: icon = Icons.cloud; color = Colors.grey; break;
      case WeatherCondition.chuvoso: icon = Icons.water_drop; color = Colors.blueAccent; break;
      case WeatherCondition.tempestade: icon = Icons.flash_on; color = Colors.purpleAccent; break;
      default: icon = Icons.cloud; color = Colors.grey;
    }
    return Icon(icon, color: color, size: 18);
  }
}