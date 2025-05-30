// lib/models/chart_data_point.dart
class ChartDataPoint {
  final String label;       // Label untuk sumbu X (misal: 'Sen', 'Min 1', 'Jan')
  final double value;       // Nilai untuk sumbu Y (misal: jumlah hidrasi)
  final int originalIndex; // Indeks asli dari data (misal: 0 untuk Senin, 0 untuk Minggu ke-1)

  ChartDataPoint({required this.label, required this.value, required this.originalIndex});
}