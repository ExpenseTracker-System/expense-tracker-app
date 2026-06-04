import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  // 1. المتغيرات الخاصة (قاعدة البيانات والذاكرة)
  List<TransactionModel> _transactions = [];
  String _currency = 'ريال'; // العملة الافتراضية
  SharedPreferences? _prefs; // [إصلاح P-2] نخزن الـ instance مرة واحدة فقط

  // قوائم الفئات الافتراضية
  List<String> _incomeCategories = ['راتب', 'مكافأة', 'هدايا', 'أخرى'];
  List<String> _expenseCategories = ['طعام', 'مواصلات', 'فواتير', 'تسوق', 'صحة', 'أخرى'];

  // 2. بوابات الوصول (Getters) لكي تقرأ الشاشات هذه البيانات
  List<TransactionModel> get transactions => _transactions;
  String get currency => _currency;
  List<String> get incomeCategories => _incomeCategories;
  List<String> get expenseCategories => _expenseCategories;

  // [إصلاح P-1] Getters للأرصدة — يُحسَب مرة واحدة عند الطلب بدلاً من داخل build()
  double get totalIncome => _transactions
      .where((tx) => tx.isIncome)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _transactions
      .where((tx) => !tx.isIncome)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get balance => totalIncome - totalExpense;

  // 3. المُنشئ (Constructor): يعمل تلقائياً أول ما يشتغل التطبيق
  // [إصلاح B-6] يُهيئ الإعدادات والبيانات معاً بدلاً من الاعتماد على الشاشة
  TransactionProvider() {
    _initAll();
  }

  // دالة التهيئة الشاملة
  Future<void> _initAll() async {
    await _initPreferences(); // أولاً: الإعدادات (العملة والفئات)
    await fetchTransactions(); // ثانياً: البيانات من قاعدة البيانات
  }

  // --- دوال الإعدادات (SharedPreferences) ---

  // [إصلاح P-2] دالة قراءة الإعدادات — تستدعي getInstance() مرة واحدة فقط
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance(); // مرة واحدة، تُحفظ في _prefs

    // أ. تحميل أو تعيين العملة
    if (_prefs!.containsKey('currency')) {
      _currency = _prefs!.getString('currency')!;
    } else {
      await _prefs!.setString('currency', _currency);
    }

    // ب. تحميل أو تعيين فئات الإيرادات
    if (_prefs!.containsKey('income_categories')) {
      _incomeCategories = _prefs!.getStringList('income_categories')!;
    } else {
      await _prefs!.setStringList('income_categories', _incomeCategories);
    }

    // ج. تحميل أو تعيين فئات المصروفات
    if (_prefs!.containsKey('expense_categories')) {
      _expenseCategories = _prefs!.getStringList('expense_categories')!;
    } else {
      await _prefs!.setStringList('expense_categories', _expenseCategories);
    }

    notifyListeners(); // إطلاق صفارة التحديث بعد جلب الإعدادات
  }

  // [إصلاح P-2] دالة تغيير العملة — تستخدم _prefs المحفوظ بدلاً من getInstance جديد
  Future<void> updateCurrency(String newCurrency) async {
    _currency = newCurrency;
    await _prefs!.setString('currency', newCurrency);
    notifyListeners();
  }

  // [إصلاح P-2] دالة إضافة فئة جديدة — تستخدم _prefs المحفوظ
  Future<void> addCategory(String category, bool isIncome) async {
    if (isIncome) {
      if (!_incomeCategories.contains(category)) {
        _incomeCategories.add(category);
        await _prefs!.setStringList('income_categories', _incomeCategories);
      }
    } else {
      if (!_expenseCategories.contains(category)) {
        _expenseCategories.add(category);
        await _prefs!.setStringList('expense_categories', _expenseCategories);
      }
    }
    notifyListeners();
  }

  // --- دوال قاعدة البيانات ---

  Future<void> fetchTransactions() async {
    final dataList = await DatabaseHelper.instance.getAllTransactions();
    _transactions = dataList;
    notifyListeners();
  }

  // [إصلاح P-3] إضافة معاملة — نُضيفها في الذاكرة مباشرة بدلاً من إعادة قراءة كل شيء
  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    _transactions.insert(0, transaction); // أول القائمة (الأحدث أولاً)
    notifyListeners();
  }

  // [إصلاح P-3] حذف معاملة — نحذفها من الذاكرة مباشرة
  Future<void> deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  // [إصلاح P-3 + B-1] تعديل معاملة — الاسم الصحيح + تحديث الذاكرة مباشرة
  Future<void> updateTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.updateTransaction(transaction); // اسم صحيح
    final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
    }
    notifyListeners();
  }
}