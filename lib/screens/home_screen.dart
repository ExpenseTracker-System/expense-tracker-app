import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'transactions_list_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // [إصلاح B-6] initState لم تعد تحتاج لاستدعاء fetchTransactions()
  // لأن TransactionProvider يُحمّل البيانات تلقائياً في Constructor

  // 🔴 إضافة جديدة: دالة لإظهار نافذة اختيار العملة
  void _showSettingsDialog(BuildContext context, TransactionProvider provider) {
    // قائمة العملات المتاحة للاختيار
    final List<String> availableCurrencies = ['ريال', 'دولار', 'يورو', 'درهم', 'دينار', 'جنيه'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إعدادات التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر العملة الأساسية:'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: provider.currency, // العملة الحالية
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: availableCurrencies.map((String c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    provider.updateCurrency(newValue); // تحديث العملة في المذيع
                    Navigator.pop(context); // إغلاق النافذة المنبثقة
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المصاريف', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        // 🔴 إضافة جديدة: زر الإعدادات في الشريط العلوي
        actions: [
           IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen()),);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // نجلب المذيع لكي نمرره للنافذة المنبثقة
              final provider = Provider.of<TransactionProvider>(context, listen: false);
              _showSettingsDialog(context, provider);
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          // [إصلاح P-1] نقرأ القيم الجاهزة من Provider مباشرة — لا حسابات هنا
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(provider.balance, provider.totalIncome, provider.totalExpense, provider.currency),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'إضافة إيراد',
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                        onTap: () {
                         Navigator.push(context,
                         MaterialPageRoute(builder: (context) => const AddTransactionScreen(isIncome: true)),
                         );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        title: 'إضافة مصروف',
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                        onTap: () {
                        Navigator.push(context,
                         MaterialPageRoute(builder: (context) => const AddTransactionScreen(isIncome: false)),
                         );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                     Navigator.push(context,MaterialPageRoute(builder: (context) => const TransactionsListScreen()),);
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('عرض سجل المعاملات بالكامل', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[800],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('المعاملات الأخيرة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Expanded(
                  child: provider.transactions.isEmpty
                      ? const Center(child: Text('لا توجد معاملات حتى الآن.'))
                      : ListView.builder(
                          itemCount: provider.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = provider.transactions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: tx.isIncome ? Colors.green[100] : Colors.red[100],
                                  child: Icon(
                                    tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: tx.isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(tx.note.isNotEmpty ? tx.note : 'بدون ملاحظة'),
                                trailing: Text(
                                  // [إصلاح B-4] تنسيق الرقم بمنزلتين عشريتين
                                  '${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ${provider.currency}',
                                  style: TextStyle(
                                    color: tx.isIncome ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- دوال مساعدة لبناء التصميم ---

  // 🔴 التعديل هنا: الدالة أصبحت تستقبل متغيراً رابعاً وهو العملة (currency)
  Widget _buildSummaryCard(double balance, double income, double expense, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text('الرصيد الحالي', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            // [إصلاح B-4] تنسيق الرصيد بمنزلتين عشريتين
            '${balance.toStringAsFixed(2)} $currency',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseInfo('الإيرادات', income, Icons.arrow_downward, Colors.greenAccent, currency),
              _buildIncomeExpenseInfo('المصروفات', expense, Icons.arrow_upward, Colors.redAccent, currency),
            ],
          ),
        ],
      ),
    );
  }

  // 🔴 التعديل هنا: الدالة أصبحت تستقبل متغيراً خامساً وهو العملة (currency)
  Widget _buildIncomeExpenseInfo(String title, double amount, IconData icon, Color color, String currency) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: Colors.white24, radius: 16, child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              // [إصلاح B-4] تنسيق المبلغ بمنزلتين عشريتين
              '${amount.toStringAsFixed(2)} $currency',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}