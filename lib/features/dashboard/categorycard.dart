import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:finance_manager/features/budget/data.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final List<BudgetItem> items;
  final Color baseColor;

  const CategoryCard({
    super.key,
    required this.title,
    required this.items,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    // Build the data map for the PieChart
    final Map<String, double> dataMap = {};
    double total = 0.0;
    for (var item in items) {
      final sum = item.monthly.fold(0.0, (monthSum, month) => monthSum + month);
      dataMap[item.name] = sum;
      total += sum;
    }

    // Generate a unique shade for each slice
    final List<Color> colorShades =
        _generateColorShades(baseColor, items.length);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // This removes the rounded corners
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            // Chart + Legend side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Donut chart
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    dataMap: dataMap,
                    chartType: ChartType.ring,
                    baseChartColor: Colors.grey[200]!,
                    colorList: colorShades,
                    ringStrokeWidth: 14,
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValues: false,
                      showChartValuesOutside: false,
                      showChartValuesInPercentage: false,
                      showChartValueBackground: false,
                    ),
                    legendOptions: const LegendOptions(showLegends: false),
                  ),
                ),

                const SizedBox(width: 8),

                // Category table (labels + amounts)
                Expanded(
                  child: _buildCategoryTable(items, colorShades, total),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTable(
      List<BudgetItem> items, List<Color> colorShades, double total) {
    return Column(
      children: [
        // Scrollable items section
        SizedBox(
          height: 28 * 3, // Height for 3 items (28 * 3)
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Color box + Category label
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: colorShades[i],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(items[i].name.length > 15 ? '${items[i].name.substring(0, 15)}...' : items[i].name),
                        ],
                      ),
                      Text(_formatNumber(items[i]
                          .monthly
                          .fold(0.0, (sum, m) => sum + m)
                          .toDouble())),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),

        // Non-scrollable total section
        const Divider(thickness: 1, height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              total.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // Generate color variations for each slice
  List<Color> _generateColorShades(Color color, int count) {
    final List<Color> shades = [];
    final HSLColor hslColor = HSLColor.fromColor(color);

    for (int i = 0; i < count; i++) {
      // Vary both lightness and saturation for more distinct colors
      final double lightness = 0.3 + (i * 0.4 / count); // Range from 0.3 to 0.7
      final double saturation =
          0.9 - (i * 0.5 / count); // Range from 0.9 to 0.4

      final HSLColor adjusted =
          hslColor.withLightness(lightness).withSaturation(saturation);
      shades.add(adjusted.toColor());
    }
    return shades;
  }

  // Format number with comma separators (e.g., 1,234,567)
  String _formatNumber(double value) {
    final number = value.toInt();
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }
}
