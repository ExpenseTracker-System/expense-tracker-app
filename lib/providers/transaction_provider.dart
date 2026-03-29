import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔴 أضفنا هذه المكتبة لحفظ الإعدادات
import '../data/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  // 1. المتغيرات الخاصة (قاعدة البيانات والذاكرة)
  List<TransactionModel> _transactions = [];
  String _currency = 'ريال'; // العملة الافتراضية
  
  // قوائم الفئات الافتراضية
  List<String> _incomeCategories = ['راتب', 'مكافأة', 'هدايا', 'أخرى'];
  List<String> _expenseCategories = ['طعام', 'مواصلات', 'فواتير', 'تسوق', 'صحة', 'أخرى'];

  // 2. بوابات الوصول (Getters) لكي تقرأ الشاشات هذه البيانات
  List<TransactionModel> get transactions => _transactions;
  String get currency => _currency;
  List<String> get incomeCategories => _incomeCategories;
  List<String> get expenseCategories => _expenseCategories;

  // 3. المُنشئ (Constructor): يعمل تلقائياً أول ما يشتغل التطبيق
  TransactionProvider() {
    _initPreferences(); // نطلب منه قراءة الإعدادات المحفوظة فوراً
  }

  // --- دوال الإعدادات (SharedPreferences) ---

  // دالة قراءة الإعدادات من ذاكرة الهاتف
  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // أ. تحميل أو تعيين العملة
    if (prefs.containsKey('currency')) {
      _currency = prefs.getString('currency')!;
    } else {
      await prefs.setString('currency', _currency);
    }

    // ب. تحميل أو تعيين فئات الإيرادات
    if (prefs.containsKey('income_categories')) {
      _incomeCategories = prefs.getStringList('income_categories')!;
    } else {
      await prefs.setStringList('income_categories', _incomeCategories);
    }

    // ج. تحميل أو تعيين فئات المصروفات
    if (prefs.containsKey('expense_categories')) {
      _expenseCategories = prefs.getStringList('expense_categories')!;
    } else {
      await prefs.setStringList('expense_categories', _expenseCategories);
    }

    notifyListeners(); // إطلاق صفارة التحديث بعد جلب الإعدادات
  }

  // دالة لتغيير العملة (يستخدمها المستخدم من الشاشة)
  Future<void> updateCurrency(String newCurrency) async {
    _currency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', newCurrency); // حفظها للأبد
    notifyListeners(); // تحديث كل الشاشات
  }

  // دالة لإضافة فئة جديدة (يستخدمها المستخدم عند إضافة معاملة)
  Future<void> addCategory(String category, bool isIncome) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (isIncome) {
      // إذا لم تكن الفئة موجودة مسبقاً، أضفها واحفظها
      if (!_incomeCategories.contains(category)) {
        _incomeCategories.add(category);
        await prefs.setStringList('income_categories', _incomeCategories);
      }
    } else {
      if (!_expenseCategories.contains(category)) {
        _expenseCategories.add(category);
        await prefs.setStringList('expense_categories', _expenseCategories);
      }
    }
    notifyListeners(); // تحديث القوائم المنسدلة في الشاشات
  }

  // --- دوال قاعدة البيانات القديمة (كما هي لم تتغير) ---

  Future<void> fetchTransactions() async {
    final dataList = await DatabaseHelper.instance.getAllTransactions();
    _transactions = dataList;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.insertTransaction(transaction);
    await fetchTransactions();
  }
  Future<void> deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await fetchTransactions();
  }
  Future<void> updateTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.ubdateTransaction(transaction);
    await fetchTransactions();
  }
}