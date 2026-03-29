import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';
import '../providers/transaction_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إحصائيات المصروفات'),
        backgroundColor: Colors.purple[800], // لون مختلف لتمييز شاشة الإحصائيات
        foregroundColor: Colors.white,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          // 1. فلترة وتجهيز البيانات (نحتاج المصروفات فقط)
          final expenses = provider.transactions.where((tx) => !tx.isIncome).toList();

          // 2. إذا لم تكن هناك مصروفات، نظهر رسالة
          if (expenses.isEmpty) {
            return const Center(
              child: Text('لا توجد مصروفات لرسمها بيانيا', style: TextStyle(fontSize: 18)),
            );
          }

          // 3. تجميع المبالغ لكل فئة (الخوارزمية الذكية)
          Map<String, double> dataMap = {};
          for (var tx in expenses) {
            if (dataMap.containsKey(tx.category)) {
              dataMap[tx.category] = dataMap[tx.category]! + tx.amount;
            } else {
              dataMap[tx.category] = tx.amount;
            }
          }

          // 4. رسم الدائرة البيانية
          return Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'أين تذهب أموالك؟',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              const SizedBox(height: 40),
              PieChart(
                dataMap: dataMap,
                animationDuration: const Duration(milliseconds: 1500), // مدة حركة الأنميشن
                chartLegendSpacing: 32, // المسافة بين الدائرة وأسماء الفئات
                chartRadius: MediaQuery.of(context).size.width / 1.5, // حجم الدائرة
                colorList: const [
                  Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.brown
                ], // الألوان المتاحة للقطع
                initialAngleInDegree: 0,
                chartType: ChartType.ring, // شكل الخاتم المفرغ من الوسط
                ringStrokeWidth: 32, // سمك الخاتم
                centerText: "المصروفات",
                legendOptions: const LegendOptions(
                  showLegendsInRow: false,
                  legendPosition: LegendPosition.right, // مكان قائمة الفئات
                  showLegends: true,
                  legendTextStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                chartValuesOptions: const ChartValuesOptions(
                  showChartValueBackground: true,
                  showChartValues: true,
                  showChartValuesInPercentage: true, // إظهار الأرقام كنسبة مئوية %
                  showChartValuesOutside: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}