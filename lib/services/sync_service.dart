import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  static const String _lastSyncKey = 'last_cloud_sync_time';

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clearSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }

  /// تنفيذ المزامنة ثنائية الاتجاه مع سيرفر Spring Boot
  Future<DateTime?> synchronizeWithServer() async {
    final token = await ApiService.instance.getToken();
    if (token == null || token.isEmpty) {
      return null; // المستخدم يعمل في الوضع المحلي ولم يسجل دخوله بعد
    }

    final prefs = await SharedPreferences.getInstance();
    final String? lastSyncIso = prefs.getString(_lastSyncKey);

    // 1. جلب المحافظ والمعاملات التي لم تتم مزامنتها بعد من قاعدة بيانات الهاتف
    final List<WalletModel> unsyncedWallets = await DatabaseHelper.instance.getUnsyncedWallets();
    final List<TransactionModel> unsyncedTransactions = await DatabaseHelper.instance.getUnsyncedTransactions();

    // 2. بناء حقيبة الطلب (SyncRequest) مطابقة لكلاس الجافا في Spring Boot
    final Map<String, dynamic> syncRequestPayload = {
      'lastSyncTime': lastSyncIso,
      'wallets': unsyncedWallets.map((w) => w.toJson()).toList(),
      'transactions': unsyncedTransactions.map((t) => t.toJson()).toList(),
    };

    // 3. إرسال الطلب إلى /api/sync
    final Map<String, dynamic> response = await ApiService.instance.post(
      '/api/sync',
      body: syncRequestPayload,
      requiresAuth: true,
    );

    // 4. حفظ التوكن المجدد تلقائياً (Sliding Session Refresh) إن وُجد
    if (response['newToken'] != null && response['newToken'].toString().isNotEmpty) {
      await ApiService.instance.saveToken(response['newToken'].toString());
    }

    // 5. قراءة المحافظ والمعاملات القادمة من السيرفر (Downstream)
    final List<dynamic> rawWallets = (response['wallets'] as List<dynamic>?) ?? [];
    final List<dynamic> rawTransactions = (response['transactions'] as List<dynamic>?) ?? [];

    final List<WalletModel> serverWallets = rawWallets
        .map((w) => WalletModel.fromJson(w as Map<String, dynamic>))
        .toList();

    final List<TransactionModel> serverTransactions = rawTransactions
        .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    // 6. حفظ التعديلات في SQLite وتعليم البيانات المرفوعة كمتزامنة
    await DatabaseHelper.instance.applySyncResults(
      uploadedWalletIds: unsyncedWallets.map((w) => w.id).toList(),
      uploadedTransactionIds: unsyncedTransactions.map((t) => t.id).toList(),
      serverWallets: serverWallets,
      serverTransactions: serverTransactions,
    );

    // 7. تحديث وقت آخر مزامنة من توقيت السيرفر
    final String serverSyncTimeStr = response['syncTime']?.toString() ??
        DateTime.now().toLocal().toIso8601String().replaceAll('Z', '');
    await prefs.setString(_lastSyncKey, serverSyncTimeStr);

    return DateTime.tryParse(serverSyncTimeStr) ?? DateTime.now();
  }
}