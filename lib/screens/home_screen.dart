import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wallet_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';
import 'transactions_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // نافذة اختيار وإدارة المحافظ المتعددة (BottomSheet)
  void _showWalletsBottomSheet(
      BuildContext context, TransactionProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<TransactionProvider>(
          builder: (context, txProvider, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'محافظي المالية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddOrEditWalletDialog(context, txProvider),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('محفظة جديدة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: txProvider.wallets.length,
                      itemBuilder: (context, index) {
                        final WalletModel wallet = txProvider.wallets[index];
                        final bool isSelected =
                            txProvider.currentWallet?.id == wallet.id;

                        return Card(
                          color: isSelected ? Colors.blue[50] : Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue[800]!
                                  : Colors.grey[300]!,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              txProvider.selectWallet(wallet);
                              Navigator.pop(ctx);
                            },
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.blue[800]
                                  : Colors.grey[200],
                              child: Icon(
                                Icons.account_balance_wallet,
                                color:
                                    isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                            title: Text(
                              wallet.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.blue[900]
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: isSelected
                                ? const Text(
                                    'المحفظة النشطة حالياً',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: Colors.blueGrey),
                                  onPressed: () => _showAddOrEditWalletDialog(
                                    context,
                                    txProvider,
                                    existingWallet: wallet,
                                  ),
                                ),
                                if (txProvider.wallets.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final bool? confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (dCtx) => AlertDialog(
                                          title: const Text('حذف المحفظة'),
                                          content: Text(
                                              'هل أنت متأكد من حذف محفظة "${wallet.name}" وجميع معاملاتها؟'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dCtx, false),
                                              child: const Text('إلغاء'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              onPressed: () =>
                                                  Navigator.pop(dCtx, true),
                                              child: const Text('حذف',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await txProvider.deleteWallet(wallet.id);
                                      }
                                    },
                                  ),
                              ],
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
        );
      },
    );
  }

  void _showAddOrEditWalletDialog(
    BuildContext context,
    TransactionProvider provider, {
    WalletModel? existingWallet,
  }) {
    final nameController =
        TextEditingController(text: existingWallet?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existingWallet == null
            ? 'إنشاء محفظة جديدة'
            : 'تعديل اسم المحفظة'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'مثال: مصاريف العمل، مصاريف المشروع...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                if (existingWallet == null) {
                  provider.addWallet(name);
                } else {
                  provider.updateWalletName(existingWallet, name);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    TransactionProvider txProvider,
    AuthProvider authProvider,
  ) {
    final List<String> availableCurrencies = [
      'ريال',
      'دولار',
      'يورو',
      'درهم',
      'دينار',
      'جنيه'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('الإعدادات والحساب السحابي',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات الحساب السحابي
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      authProvider.isAuthenticated
                          ? Icons.verified_user
                          : Icons.cloud_off,
                      color: authProvider.isAuthenticated
                          ? Colors.green[700]
                          : Colors.grey[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.isAuthenticated
                                ? authProvider.currentUser!.username
                                : 'الوضع المحلي (بدون حساب)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            authProvider.isAuthenticated
                                ? authProvider.currentUser!.email
                                : 'سجل دخولك لتفعيل النسخ الاحتياطي السحابي',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: authProvider.isAuthenticated
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          await authProvider.logout();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('تسجيل الخروج من السحابة',
                            style: TextStyle(color: Colors.red)),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('تسجيل الدخول / إنشاء حساب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                        ),
                      ),
              ),
              const Divider(height: 24),
              const Text('اختر العملة الأساسية:'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: txProvider.currency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: availableCurrencies.map((String c) {
                  return DropdownMenuItem<String>(value: c, child: Text(c));
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    txProvider.updateCurrency(newValue);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerManualSync(
    BuildContext context,
    TransactionProvider txProvider,
    AuthProvider authProvider,
  ) async {
    if (!authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final bool ok = await txProvider.syncWithCloud(manual: true);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          txProvider.syncStatusMessage ??
              (ok ? 'تمت المزامنة بنجاح' : 'تعذر إجراء المزامنة حالياً'),
        ),
        backgroundColor: ok ? Colors.green[700] : Colors.orange[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, AuthProvider>(
      builder: (context, provider, authProvider, _) {
        final String currentWalletName =
            provider.currentWallet?.name ?? 'المحفظة الشخصية';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            // زر التبديل السريع بين المحافظ في عنوان الشريط العلوي
            title: InkWell(
              onTap: () => _showWalletsBottomSheet(context, provider),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        currentWalletName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
            actions: [
              // زر المزامنة السحابية والنسخ الاحتياطي
              IconButton(
                tooltip: 'المزامنة السحابية',
                onPressed: provider.isSyncing
                    ? null
                    : () =>
                        _triggerManualSync(context, provider, authProvider),
                icon: provider.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        authProvider.isAuthenticated
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_upload_outlined,
                      ),
              ),
              IconButton(
                tooltip: 'الإحصائيات',
                icon: const Icon(Icons.pie_chart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StatisticsScreen()),
                  );
                },
              ),
              IconButton(
                tooltip: 'الإعدادات والحساب',
                icon: const Icon(Icons.settings),
                onPressed: () =>
                    _showSettingsDialog(context, provider, authProvider),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  provider.balance,
                  provider.totalIncome,
                  provider.totalExpense,
                  provider.currency,
                  currentWalletName,
                ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddTransactionScreen(isIncome: true),
                            ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddTransactionScreen(isIncome: false),
                            ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionsListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text(
                      'عرض سجل المعاملات والبحث والفلترة',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[800],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المعاملات الأخيرة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showWalletsBottomSheet(context, provider),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('تغيير المحفظة'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: provider.transactions.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد معاملات في هذه المحفظة حتى الآن.',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.transactions.length > 10
                              ? 10
                              : provider.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = provider.transactions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddTransactionScreen(
                                        isIncome: tx.isIncome,
                                        existingTransaction: tx,
                                      ),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: tx.isIncome
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  child: Icon(
                                    tx.isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: tx.isIncome
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  tx.category,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  tx.note.isNotEmpty ? tx.note : 'بدون ملاحظة',
                                ),
                                trailing: Text(
                                  '${tx.isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ${provider.currency}',
                                  style: TextStyle(
                                    color:
                                        tx.isIncome ? Colors.green : Colors.red,
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
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    double balance,
    double income,
    double expense,
    String currency,
    String walletName,
  ) {
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
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'الرصيد الحالي ($walletName)',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(2)} $currency',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseInfo(
                'الإيرادات',
                income,
                Icons.arrow_downward,
                Colors.greenAccent,
                currency,
              ),
              _buildIncomeExpenseInfo(
                'المصروفات',
                expense,
                Icons.arrow_upward,
                Colors.redAccent,
                currency,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseInfo(
    String title,
    double amount,
    IconData icon,
    Color color,
    String currency,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 16,
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '${amount.toStringAsFixed(2)} $currency',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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