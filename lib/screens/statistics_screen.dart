import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final String walletName =
            provider.currentWallet?.name ?? 'المحفظة الشخصية';
        final expenses = provider.transactions
            .where((tx) => !tx.isIncome)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('إحصائيات المصروفات ($walletName)'),
            backgroundColor: Colors.purple[800],
            foregroundColor: Colors.white,
          ),
          body: expenses.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مصروفات في هذه المحفظة لرسمها بيانياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : _buildStatisticsContent(context, expenses, provider.currency),
        );
      },
    );
  }

  Widget _buildStatisticsContent(
    BuildContext context,
    List<dynamic> expenses,
    String currency,
  ) {
    final Map<String, double> dataMap = <String, double>{};
    double totalExpense = 0.0;

    for (final tx in expenses) {
      final String cat = tx.category as String;
      final double amt = tx.amount as double;
      dataMap[cat] = (dataMap[cat] ?? 0.0) + amt;
      totalExpense += amt;
    }

    // ترتيب الفئات تنازلياً من الأكبر استهلاكاً إلى الأصغر
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const List<Color> chartColors = [
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.pink,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'أين تذهب أموالك؟',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 28),
          PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 1200),
            chartLegendSpacing: 32,
            chartRadius: MediaQuery.of(context).size.width / 1.6,
            colorList: chartColors,
            initialAngleInDegree: 0,
            chartType: ChartType.ring,
            ringStrokeWidth: 32,
            centerText: 'المصروفات',
            legendOptions: const LegendOptions(
              showLegendsInRow: false,
              legendPosition: LegendPosition.right,
              showLegends: true,
              legendTextStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: true,
              showChartValues: true,
              showChartValuesInPercentage: true,
              showChartValuesOutside: false,
            ),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'تفاصيل الفئات (من الأعلى استهلاكاً):',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(sortedEntries.length, (index) {
            final entry = sortedEntries[index];
            final double percentage = totalExpense > 0
                ? (entry.value / totalExpense) * 100
                : 0.0;
            final Color color = chartColors[index % chartColors.length];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: LinearProgressIndicator(
                  value: totalExpense > 0 ? (entry.value / totalExpense) : 0,
                  color: color,
                  backgroundColor: Colors.grey[200],
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                trailing: Text(
                  '${entry.value.toStringAsFixed(2)} $currency',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
