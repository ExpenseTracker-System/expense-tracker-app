import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool isIncome;
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({
    super.key,
    required this.isIncome,
    this.existingTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final tx = widget.existingTransaction!;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note;
      _selectedCategory = tx.category;
      _selectedDate = tx.date;
    }
  }

  void _validateSelectedCategory(List<String> categories) {
    if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCategory = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الفئة')),
        );
        return;
      }

      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final activeWalletId = provider.currentWallet?.id ?? 'default_wallet';

      final transaction = TransactionModel(
        id: widget.existingTransaction?.id ?? _uuid.v4(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        note: _noteController.text.trim(),
        date: _selectedDate,
        isIncome: widget.isIncome,
        walletId: widget.existingTransaction?.walletId ?? activeWalletId,
        createdAt: widget.existingTransaction?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingTransaction == null) {
        provider.addTransaction(transaction);
      } else {
        provider.updateTransaction(transaction);
      }

      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddCategoryDialog() {
    final categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('إضافة فئة جديدة'),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(hintText: 'اسم الفئة'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCat = categoryController.text.trim();
                if (newCat.isNotEmpty) {
                  Provider.of<TransactionProvider>(context, listen: false)
                      .addCategory(newCat, widget.isIncome);
                  setState(() {
                    _selectedCategory = newCat;
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isIncome ? Colors.green : Colors.red;
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final currency = provider.currency;
    final walletName = provider.currentWallet?.name ?? 'المحفظة الشخصية';
    final isEditing = widget.existingTransaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'تعديل المعاملة'
              : (widget.isIncome
                  ? 'إضافة إيراد ($walletName)'
                  : 'إضافة مصروف ($walletName)'),
        ),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    prefixIcon: Padding(
                      padding:
                          const EdgeInsets.only(top: 14, right: 12, left: 12),
                      child: Text(
                        currency,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال المبلغ';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) return 'الرجاء إدخال رقم صحيح';
                    if (amount <= 0) return 'يجب أن يكون المبلغ أكبر من الصفر';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Consumer<TransactionProvider>(
                        builder: (context, txProv, child) {
                          final categories = widget.isIncome
                              ? txProv.incomeCategories
                              : txProv.expenseCategories;

                          _validateSelectedCategory(categories);

                          return DropdownButtonFormField<String>(
                            key: ValueKey(_selectedCategory),
                            initialValue: _selectedCategory,
                            items: categories.map((String cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                            decoration: InputDecoration(
                              labelText: 'الفئة',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.category, color: color),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add_circle, size: 40),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                    prefixIcon: Icon(Icons.note, color: color),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.calendar_today, color: color),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate.toString().substring(0, 10),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'تحديث المعاملة' : 'حفظ المعاملة',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}