import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart'; // 🔴 التعديل 1: استدعاء شاشة الإضافة (الحرباء)

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المعاملات بالكامل'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.transactions.isEmpty) {
            return const Center(child: Text('لا توجد معاملات مسجلة حتى الآن.', style: TextStyle(fontSize: 18)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final tx = provider.transactions[index];

              return Dismissible(
                key: Key(tx.id),
                direction: DismissDirection.startToEnd,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                // [إصلاح B-5] نطلب تأكيداً من المستخدم قبل الحذف
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: Text(
                        'هل أنت متأكد من حذف معاملة "${tx.category}" بمبلغ ${tx.amount.toStringAsFixed(2)} ${provider.currency}؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('حذف', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (direction) {
                  provider.deleteTransaction(tx.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المعاملة بنجاح'), backgroundColor: Colors.red),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    // 🔴 التعديل 2: السر الهندسي للتعديل! (عند الضغط على الكرت)
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(
                            isIncome: tx.isIncome, // نخبرها بنوع المعاملة (أخضر أم أحمر)
                            existingTransaction: tx, // 🔴 نرسل الصندوق القديم بالكامل للشاشة!
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: tx.isIncome ? Colors.green[100] : Colors.red[100],
                      child: Icon(tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: tx.isIncome ? Colors.green : Colors.red),
                    ),
                    title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tx.note.isNotEmpty) Text(tx.note),
                        Text(tx.date.toString().substring(0, 10), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: Text(
                      // [إصلاح B-4] تنسيق المبلغ بمنزلتين عشريتين
                      '${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ${provider.currency}',
                      style: TextStyle(color: tx.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}