class MonthlyChartData {
  final String label;   // "Jan", "Fev"...
  final double income;
  final double expense;
  double get profit => income - expense;

  MonthlyChartData({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class CategoryChartData {
  final String label;
  final double value;

  CategoryChartData({required this.label, required this.value});
}