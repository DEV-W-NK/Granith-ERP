import 'package:flutter/material.dart';

class BudgetTypeConstants {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Grid columns
  static const int mobileGridColumns = 1;
  static const int tabletGridColumns = 2;
  static const int desktopGridColumns = 3;

  // Categorias disponíveis
  static const List<String> categories = [
    'Material',
    'Mão de Obra',
    'Equipamento',
    'Serviço',
  ];

  // Ícones para categorias
  static const Map<String, IconData> categoryIcons = {
    'Material': Icons.construction,
    'Mão de Obra': Icons.person_outline,
    'Equipamento': Icons.precision_manufacturing,
    'Serviço': Icons.design_services,
  };

  // Cores para categorias
  static const Map<String, Color> categoryColors = {
    'Material': Color(0xFF4CAF50),     // Verde
    'Mão de Obra': Color(0xFF2196F3), // Azul
    'Equipamento': Color(0xFFFF9800), // Laranja
    'Serviço': Color(0xFF9C27B0),     // Roxo
  };

  // Opções de ícones disponíveis para tipos de orçamento
  static const Map<String, IconData> availableIcons = {
    'construction': Icons.construction,
    'build': Icons.build,
    'home_repair_service': Icons.home_repair_service,
    'handyman': Icons.handyman,
    'engineering': Icons.engineering,
    'precision_manufacturing': Icons.precision_manufacturing,
    'electrical_services': Icons.electrical_services,
    'plumbing': Icons.plumbing,
    'roofing': Icons.roofing,
    'foundation': Icons.foundation,
    'window': Icons.window,
    'door_front': Icons.door_front_door,
    'stairs': Icons.stairs,
    'kitchen': Icons.kitchen,
    'bathroom': Icons.bathroom,
    'bedroom': Icons.bed,
    'living': Icons.chair,
    'garage': Icons.garage,
    'fence': Icons.fence,
    'yard': Icons.grass,
    'pool': Icons.pool,
  };

  // Cores disponíveis
  static const List<Color> availableColors = [
    Color(0xFF4CAF50), // Verde
    Color(0xFF2196F3), // Azul
    Color(0xFFFF9800), // Laranja
    Color(0xFF9C27B0), // Roxo
    Color(0xFFF44336), // Vermelho
    Color(0xFF607D8B), // Azul Acinzentado
    Color(0xFF795548), // Marrom
    Color(0xFF009688), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFFCDDC39), // Lima
    Color(0xFFFF5722), // Laranja Escuro
  ];

  // Validações
  static const int minNameLength = 3;
  static const int maxNameLength = 50;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 200;
}