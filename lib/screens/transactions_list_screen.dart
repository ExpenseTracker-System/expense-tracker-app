import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // مجموعة المعرفات المختارة للحذف الجماعي (Batch Delete)
  final Set<String> _selectedIds = <String>{};
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // فلترة قائمة المعاملات لحظياً حسب الكلمة المفتاحية والفترة الزمنية
  List<TransactionModel> _getFilteredTransactions(
      List<TransactionModel> allTransactions) {
    return allTransactions.where((tx) {
      // 1. فلتر البحث النصي
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchCategory = tx.category.toLowerCase().contains(query);
        final matchNote = tx.note.toLowerCase().contains(query);
        if (!matchCategory && !matchNote) return false;
      }

      // 2. فلتر التاريخ (من تاريخ - إلى تاريخ)
      if (_startDate != null) {
        final start =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (tx.date.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (tx.date.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      helpText: 'اختر الفترة الزمنية لفلترة المعاملات',
      cancelText: 'إلغاء',
      confirmText: 'تطبيق الفلتر',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _confirmBatchDelete(TransactionProvider provider) async {
    if (_selectedIds.isEmpty) return;

    final int count = _selectedIds.length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف الجماعي',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف ($count) معاملة محددة دفعة واحدة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteTransactionsInBatch(_selectedIds.toList());
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف $count معاملة بنجاح'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final filteredList = _getFilteredTransactions(provider.transactions);
        final bool hasActiveFilter = _searchController.text.isNotEmpty ||
            _startDate != null ||
            _endDate != null;

        return Scaffold(
          appBar: AppBar(
            backgroundColor:
                _isSelectionMode ? Colors.red[800] : Colors.blue[800],
            foregroundColor: Colors.white,
            title: Text(
              _isSelectionMode
                  ? 'تم تحديد (${_selectedIds.length}) معاملة'
                  : 'سجل المعاملات (${provider.currentWallet?.name ?? ""})',
            ),
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedIds.clear();
                        _isSelectionMode = false;
                      });
                    },
                  )
                : null,
            actions: [
              if (_isSelectionMode) ...[
                IconButton(
                  tooltip: 'تحديد الكل',
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == filteredList.length) {
                        _selectedIds.clear();
                        _isSelectionMode = false;
                      } else {
                        _selectedIds
                            .addAll(filteredList.map((e) => e.id).toList());
                      }
                    });
                  },
                ),
                IconButton(
                  tooltip: 'حذف المحدد',
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => _confirmBatchDelete(provider),
                ),
              ] else ...[
                IconButton(
                  tooltip: 'تحديد متعدد للحذف',
                  icon: const Icon(Icons.checklist_rtl),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = true;
                    });
                  },
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              // شريط البحث والفلترة بين تاريخين
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'ابحث بالفئة أو الملاحظة...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.date_range, size: 20),
                          label: const Text('التاريخ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _startDate != null
                                ? Colors.blue[800]
                                : Colors.blue[50],
                            foregroundColor: _startDate != null
                                ? Colors.white
                                : Colors.blue[800],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasActiveFilter) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _startDate != null && _endDate != null
                                  ? 'الفترة: ${_startDate.toString().substring(0, 10)} إلى ${_endDate.toString().substring(0, 10)} (${filteredList.length} نتيجة)'
                                  : 'نتائج البحث: ${filteredList.length} معاملة',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.filter_alt_off, size: 16),
                            label: const Text('إلغاء الفلتر'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // قائمة المعاملات
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          hasActiveFilter
                              ? 'لا توجد معاملات تطابق بحثك أو الفترة المحددة.'
                              : 'لا توجد معاملات مسجلة في هذه المحفظة حتى الآن.',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final tx = filteredList[index];
                          final bool isSelected = _selectedIds.contains(tx.id);

                          return Dismissible(
                            key: Key(tx.id),
                            direction: _isSelectionMode
                                ? DismissDirection.none
                                : DismissDirection.startToEnd,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 30),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        'تأكيد الحذف',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      content: Text(
                                        'هل أنت متأكد من حذف معاملة "${tx.category}" بمبلغ ${tx.amount.toStringAsFixed(2)} ${provider.currency}؟',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          child: const Text('حذف',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (direction) {
                              provider.deleteTransaction(tx.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حذف المعاملة بنجاح'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            child: Card(
                              color:
                                  isSelected ? Colors.red[50] : Colors.white,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isSelected
                                    ? const BorderSide(
                                        color: Colors.red, width: 1.5)
                                    : BorderSide.none,
                              ),
                              elevation: 2,
                              child: ListTile(
                                onLongPress: () => _toggleSelection(tx.id),
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleSelection(tx.id);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddTransactionScreen(
                                          isIncome: tx.isIncome,
                                          existingTransaction: tx,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                leading: _isSelectionMode
                                    ? Checkbox(
                                        value: isSelected,
                                        activeColor: Colors.red[800],
                                        onChanged: (_) =>
                                            _toggleSelection(tx.id),
                                      )
                                    : CircleAvatar(
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (tx.note.isNotEmpty) Text(tx.note),
                                    Text(
                                      tx.date.toString().substring(0, 10),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
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
  }
}