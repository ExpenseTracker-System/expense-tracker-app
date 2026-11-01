import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class TransactionProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  List<WalletModel> _wallets = [];
  WalletModel? _currentWallet;
  List<TransactionModel> _transactions = [];

  SharedPreferences? _prefs;

  List<String> _incomeCategories = ['راتب', 'مكافأة', 'مبيعات', 'هدايا', 'أخرى'];
  List<String> _expenseCategories = ['طعام', 'مواصلات', 'فواتير', 'تسوق', 'صحة', 'قات', 'أخرى'];

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncStatusMessage;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // بوابات الوصول (Getters)
  List<WalletModel> get wallets => _wallets;
  WalletModel? get currentWallet => _currentWallet;
  List<TransactionModel> get transactions => _transactions;

  // العملة الآن مرتبطة بالمحفظة النشطة حالياً (وتكون افتراضياً ريال)
  String get currency => _currentWallet?.currency ?? 'ريال';

  List<String> get incomeCategories => _incomeCategories;
  List<String> get expenseCategories => _expenseCategories;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncStatusMessage => _syncStatusMessage;

  double get totalIncome => _transactions
      .where((tx) => tx.isIncome)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _transactions
      .where((tx) => !tx.isIncome)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get balance => totalIncome - totalExpense;

  TransactionProvider() {
    _initAll();
  }

  Future<void> _initAll() async {
    await _initPreferences();
    await loadWalletsAndTransactions();
    _lastSyncTime = await SyncService.instance.getLastSyncTime();
    _listenToConnectivityChanges();
    unawaited(syncWithCloud(manual: false));
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        unawaited(syncWithCloud(manual: false));
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // ==================== إعدادات الفئات وعملة المحفظة ====================

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    if (_prefs!.containsKey('income_categories')) {
      _incomeCategories = _prefs!.getStringList('income_categories')!;
    } else {
      await _prefs!.setStringList('income_categories', _incomeCategories);
    }

    if (_prefs!.containsKey('expense_categories')) {
      _expenseCategories = _prefs!.getStringList('expense_categories')!;
    } else {
      await _prefs!.setStringList('expense_categories', _expenseCategories);
    }

    notifyListeners();
  }

  // تحديث عملة المحفظة النشطة حالياً فقط وحفظها في قاعدة البيانات ومزامنتها
  Future<void> updateCurrency(String newCurrency) async {
    if (_currentWallet == null) return;
    final updatedWallet = _currentWallet!.copyWith(
      currency: newCurrency,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await DatabaseHelper.instance.updateWallet(updatedWallet);

    final index = _wallets.indexWhere((w) => w.id == updatedWallet.id);
    if (index != -1) {
      _wallets[index] = updatedWallet;
    }
    _currentWallet = updatedWallet;
    notifyListeners();
    unawaited(syncWithCloud(manual: false));
  }

  Future<void> addCategory(String category, bool isIncome) async {
    if (isIncome) {
      if (!_incomeCategories.contains(category)) {
        _incomeCategories.add(category);
        await _prefs?.setStringList('income_categories', _incomeCategories);
      }
    } else {
      if (!_expenseCategories.contains(category)) {
        _expenseCategories.add(category);
        await _prefs?.setStringList('expense_categories', _expenseCategories);
      }
    }
    notifyListeners();
  }

  // ==================== إدارة المحافظ المتعددة ====================

  Future<void> loadWalletsAndTransactions() async {
    _wallets = await DatabaseHelper.instance.getAllWallets();

    if (_wallets.isEmpty) {
      final defaultWallet = WalletModel(
        id: _uuid.v4(),
        name: 'المحفظة الشخصية',
        currency: 'ريال',
      );
      await DatabaseHelper.instance.insertWallet(defaultWallet);
      _wallets = [defaultWallet];
    }

    final savedWalletId = _prefs?.getString('selected_wallet_id');
    if (savedWalletId != null) {
      _currentWallet = _wallets.firstWhere(
        (w) => w.id == savedWalletId,
        orElse: () => _wallets.first,
      );
    } else {
      _currentWallet = _wallets.first;
      await _prefs?.setString('selected_wallet_id', _currentWallet!.id);
    }

    await fetchTransactions();
  }

  Future<void> selectWallet(WalletModel wallet) async {
    _currentWallet = wallet;
    await _prefs?.setString('selected_wallet_id', wallet.id);
    await fetchTransactions();
  }

  Future<void> addWallet(String name, {String walletCurrency = 'ريال'}) async {
    final newWallet = WalletModel(
      id: _uuid.v4(),
      name: name.trim(),
      currency: walletCurrency,
    );
    await DatabaseHelper.instance.insertWallet(newWallet);
    _wallets.add(newWallet);
    await selectWallet(newWallet);
    unawaited(syncWithCloud(manual: false));
  }

  Future<void> updateWalletDetails(
    WalletModel wallet,
    String newName,
    String newCurrency,
  ) async {
    final updated = wallet.copyWith(
      name: newName.trim(),
      currency: newCurrency,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await DatabaseHelper.instance.updateWallet(updated);

    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = updated;
    }
    if (_currentWallet?.id == wallet.id) {
      _currentWallet = updated;
    }
    notifyListeners();
    unawaited(syncWithCloud(manual: false));
  }

  Future<bool> deleteWallet(String walletId) async {
    if (_wallets.length <= 1) {
      return false;
    }
    await DatabaseHelper.instance.softDeleteWallet(walletId);
    _wallets.removeWhere((w) => w.id == walletId);

    if (_currentWallet?.id == walletId) {
      await selectWallet(_wallets.first);
    } else {
      notifyListeners();
    }
    unawaited(syncWithCloud(manual: false));
    return true;
  }

  // ==================== إدارة المعاملات ====================

  Future<void> fetchTransactions() async {
    if (_currentWallet == null) return;
    _transactions = await DatabaseHelper.instance.getTransactionsByWallet(_currentWallet!.id);
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final activeWalletId = _currentWallet?.id ?? _wallets.first.id;
    final txWithWallet = transaction.copyWith(
      id: transaction.id.isNotEmpty ? transaction.id : _uuid.v4(),
      walletId: activeWalletId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await DatabaseHelper.instance.insertTransaction(txWithWallet);
    _transactions.insert(0, txWithWallet);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    unawaited(syncWithCloud(manual: false));
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final updatedTx = transaction.copyWith(
      walletId: _currentWallet?.id ?? transaction.walletId,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    await DatabaseHelper.instance.updateTransaction(updatedTx);
    final index = _transactions.indexWhere((tx) => tx.id == updatedTx.id);
    if (index != -1) {
      _transactions[index] = updatedTx;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();

    unawaited(syncWithCloud(manual: false));
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();

    unawaited(syncWithCloud(manual: false));
  }

  Future<void> deleteTransactionsInBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    await DatabaseHelper.instance.deleteTransactionsInBatch(ids);
    final idSet = ids.toSet();
    _transactions.removeWhere((tx) => idSet.contains(tx.id));
    notifyListeners();

    unawaited(syncWithCloud(manual: false));
  }

  Future<List<TransactionModel>> filterTransactions({
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentWallet == null) return [];
    return await DatabaseHelper.instance.searchAndFilterTransactions(
      walletId: _currentWallet!.id,
      keyword: keyword,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ==================== المزامنة السحابية ====================

  Future<bool> syncWithCloud({bool manual = true}) async {
    if (_isSyncing) return false;

    final token = await ApiService.instance.getToken();
    if (token == null || token.isEmpty) {
      if (manual) {
        _syncStatusMessage = 'يرجى تسجيل الدخول أولاً لتفعيل المزامنة السحابية';
        notifyListeners();
      }
      return false;
    }

    _isSyncing = true;
    _syncStatusMessage = null;
    notifyListeners();

    try {
      final syncTime = await SyncService.instance.synchronizeWithServer();
      if (syncTime != null) {
        _lastSyncTime = syncTime;
        _syncStatusMessage = 'تمت المزامنة والنسخ الاحتياطي بنجاح';
        await loadWalletsAndTransactions();
      }
      _isSyncing = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSyncing = false;
      _syncStatusMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isSyncing = false;
      if (manual) {
        _syncStatusMessage = 'تعذر الاتصال بالسحابة حالياً، بياناتك محفوظة محلياً بأمان';
      }
      notifyListeners();
      return false;
    }
  }
}