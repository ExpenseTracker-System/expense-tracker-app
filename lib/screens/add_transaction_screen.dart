import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool isIncome;
  // 🔴 التعديل 1: استقبال معاملة قديمة (اختياري، لذلك وضعنا ?)
  final TransactionModel? existingTransaction;

  const AddTransactionScreen({
    super.key, 
    required this.isIncome,
    this.existingTransaction, // 🔴 إضافة المتغير للمُنشئ
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  // 🔴 التعديل 2: دالة التهيئة (تعمل مرة واحدة عند فتح الشاشة)
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

  // [إصلاح B-3] دالة آمنة للتحقق من صحة الفئة — تعمل بعد اكتمال البناء لا أثناءه
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

  // 🔴 التعديل 3: دالة الحفظ الذكية (تفرق بين الإضافة والتحديث)
  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار الفئة')),
        );
        return;
      }

      // بناء الصندوق بالبيانات الموجودة في الشاشة
      final transaction = TransactionModel(
        // إذا كنا نعدل، استخدم الـ ID القديم، وإلا اصنع ID جديد
        id: widget.existingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        note: _noteController.text,
        date: _selectedDate,
        isIncome: widget.isIncome,
      );

      final provider = Provider.of<TransactionProvider>(context, listen: false);

      // قرار الإرسال: إضافة أم تعديل؟
      if (widget.existingTransaction == null) {
        provider.addTransaction(transaction); // إضافة جديد
      } else {
        provider.updateTransaction(transaction); // 🔴 تحديث القديم
      }

      Navigator.pop(context); // إغلاق الشاشة
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
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة فئة جديدة'),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(hintText: 'اسم الفئة'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                  Navigator.pop(context);
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
    // [إصلاح P-4] listen: false — لا نحتاج لإعادة بناء الشاشة عند تغيير العملة
    final currency = Provider.of<TransactionProvider>(context, listen: false).currency;
    
    // 🔴 متغير يحدد هل نحن في وضع التعديل أم لا
    final isEditing = widget.existingTransaction != null;

    return Scaffold(
      appBar: AppBar(
        // 🔴 تغيير العنوان بناءً على الوضع
        title: Text(isEditing ? 'تعديل المعاملة' : (widget.isIncome ? 'إضافة إيراد' : 'إضافة مصروف')),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(top: 14, right: 12, left: 12),
                      child: Text(
                        currency,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'الرجاء إدخال المبلغ';
                    final amount = double.tryParse(value);
                    if (amount == null) return 'الرجاء إدخال رقم صحيح';
                    // [إصلاح B-2] رفض الأرقام السالبة والصفر
                    if (amount <= 0) return 'يجب أن يكون المبلغ أكبر من الصفر';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Consumer<TransactionProvider>(
                        builder: (context, provider, child) {
                          final categories = widget.isIncome ? provider.incomeCategories : provider.expenseCategories;

                          // [إصلاح B-3] نستدعي الدالة الآمنة بدلاً من تعديل State مباشرة داخل build()
                          _validateSelectedCategory(categories);

                          return DropdownButtonFormField<String>(
                            key: ValueKey(_selectedCategory), // إعادة البناء عند تغيير القيمة
                            initialValue: _selectedCategory, // [إصلاح B-3] initialValue — الأسلوب الصحيح
                            items: categories.map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val),
                            decoration: InputDecoration(
                              labelText: 'الفئة',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.calendar_today, color: color),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedDate.toString().substring(0, 10), style: const TextStyle(fontSize: 16)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    // 🔴 تغيير نص الزر بناءً على الوضع
                    child: Text(
                      isEditing ? 'تحديث المعاملة' : 'حفظ المعاملة',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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