import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _uuid = Uuid();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    final now = DateTime.now().toLocal().toIso8601String().replaceAll('Z', '');
    final defaultWalletId = _uuid.v4();

    // 1. إنشاء جدول المحافظ
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        userId TEXT,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. إنشاء جدول المعاملات
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        isIncome INTEGER NOT NULL,
        walletId TEXT NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. إنشاء الفهارس لتسريع الفلترة والبحث والمزامنة
    await db.execute('CREATE INDEX idx_tx_wallet_deleted ON transactions(walletId, isDeleted, date DESC)');
    await db.execute('CREATE INDEX idx_tx_synced ON transactions(isSynced)');
    await db.execute('CREATE INDEX idx_wallet_deleted ON wallets(isDeleted)');

    // 4. إدراج محفظة افتراضية أولية ليعمل التطبيق فوراً
    await db.insert('wallets', {
      'id': defaultWalletId,
      'name': 'المحفظة الشخصية',
      'userId': null,
      'isDeleted': 0,
      'createdAt': now,
      'updatedAt': now,
      'isSynced': 0,
    });
  }

  // ترقية قاعدة البيانات من الإصدار 1 إلى 2 دون فقدان البيانات القديمة للمستخدم
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final now = DateTime.now().toLocal().toIso8601String().replaceAll('Z', '');
      final defaultWalletId = _uuid.v4();

      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallets (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          userId TEXT,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          isSynced INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.insert('wallets', {
        'id': defaultWalletId,
        'name': 'المحفظة الشخصية',
        'userId': null,
        'isDeleted': 0,
        'createdAt': now,
        'updatedAt': now,
        'isSynced': 0,
      });

      // إضافة الأعمدة الجديدة لجدول المعاملات القديم وربطه بالمحفظة الشخصية
      await db.execute("ALTER TABLE transactions ADD COLUMN walletId TEXT NOT NULL DEFAULT '$defaultWalletId'");
      await db.execute('ALTER TABLE transactions ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0');
      await db.execute("ALTER TABLE transactions ADD COLUMN createdAt TEXT NOT NULL DEFAULT '$now'");
      await db.execute("ALTER TABLE transactions ADD COLUMN updatedAt TEXT NOT NULL DEFAULT '$now'");
      await db.execute('ALTER TABLE transactions ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_tx_wallet_deleted ON transactions(walletId, isDeleted, date DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tx_synced ON transactions(isSynced)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wallet_deleted ON wallets(isDeleted)');
    }
  }

  // ==================== عمليات المحافظ (Wallets CRUD) ====================

  Future<List<WalletModel>> getAllWallets() async {
    final db = await instance.database;
    final result = await db.query(
      'wallets',
      where: 'isDeleted = 0',
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => WalletModel.fromMap(map)).toList();
  }

  Future<void> insertWallet(WalletModel wallet) async {
    final db = await instance.database;
    await db.insert(
      'wallets',
      wallet.copyWith(isSynced: false, updatedAt: DateTime.now()).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateWallet(WalletModel wallet) async {
    final db = await instance.database;
    final updated = wallet.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    return await db.update(
      'wallets',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> softDeleteWallet(String walletId) async {
    final db = await instance.database;
    final now = DateTime.now().toLocal().toIso8601String().replaceAll('Z', '');

    await db.transaction((txn) async {
      // 1. حذف جميع معاملات المحفظة ناعماً
      await txn.update(
        'transactions',
        {'isDeleted': 1, 'updatedAt': now, 'isSynced': 0},
        where: 'walletId = ?',
        whereArgs: [walletId],
      );
      // 2. حذف المحفظة ناعماً
      await txn.update(
        'wallets',
        {'isDeleted': 1, 'updatedAt': now, 'isSynced': 0},
        where: 'id = ?',
        whereArgs: [walletId],
      );
    });
  }

  // ==================== عمليات المعاملات (Transactions CRUD) ====================

  Future<List<TransactionModel>> getTransactionsByWallet(String walletId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'walletId = ? AND isDeleted = 0',
      whereArgs: [walletId],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    final toSave = transaction.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    await db.insert(
      'transactions',
      toSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    final toUpdate = transaction.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    return await db.update(
      'transactions',
      toUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // الحذف الناعم لمعاملة واحدة (لضمان مزامنة الحذف مع السيرفر)
  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    final now = DateTime.now().toLocal().toIso8601String().replaceAll('Z', '');
    return await db.update(
      'transactions',
      {'isDeleted': 1, 'updatedAt': now, 'isSynced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // الحذف الناعم المتعدد (Batch Delete) لتحديد وحذف أكثر من معاملة في وقت واحد
  Future<int> deleteTransactionsInBatch(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final db = await instance.database;
    final now = DateTime.now().toLocal().toIso8601String().replaceAll('Z', '');
    final placeholders = List.filled(ids.length, '?').join(',');

    return await db.rawUpdate(
      'UPDATE transactions SET isDeleted = 1, updatedAt = ?, isSynced = 0 WHERE id IN ($placeholders)',
      [now, ...ids],
    );
  }

  // البحث النصي والفلترة بين تاريخين داخل المحفظة
  Future<List<TransactionModel>> searchAndFilterTransactions({
    required String walletId,
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;
    final List<String> whereClauses = ['walletId = ?', 'isDeleted = 0'];
    final List<dynamic> whereArgs = [walletId];

    if (keyword != null && keyword.trim().isNotEmpty) {
      whereClauses.add('(LOWER(category) LIKE ? OR LOWER( IFNULL(note, "") ) LIKE ?)');
      final pattern = '%${keyword.trim().toLowerCase()}%';
      whereArgs.addAll([pattern, pattern]);
    }

    if (startDate != null) {
      final startIso = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0)
          .toIso8601String()
          .replaceAll('Z', '');
      whereClauses.add('date >= ?');
      whereArgs.add(startIso);
    }

    if (endDate != null) {
      final endIso = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          .toIso8601String()
          .replaceAll('Z', '');
      whereClauses.add('date <= ?');
      whereArgs.add(endIso);
    }

    final result = await db.query(
      'transactions',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // ==================== دوال محرك المزامنة (Sync Engine Helpers) ====================

  Future<List<WalletModel>> getUnsyncedWallets() async {
    final db = await instance.database;
    final result = await db.query('wallets', where: 'isSynced = 0');
    return result.map((map) => WalletModel.fromMap(map)).toList();
  }

  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'isSynced = 0');
    return result.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // تعليم جميع البيانات المحلية كغير متزامنة عند تسجيل دخول مستخدم جديد لرفعها لحسابه السحابي
  Future<void> markAllDataForSync(String userId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update('wallets', {'userId': userId, 'isSynced': 0});
      await txn.update('transactions', {'isSynced': 0});
    });
  }

  // تطبيق نتائج المزامنة القادمة من سيرفر Spring Boot في حزمة واحدة سريعة
  Future<void> applySyncResults({
    required List<String> uploadedWalletIds,
    required List<String> uploadedTransactionIds,
    required List<WalletModel> serverWallets,
    required List<TransactionModel> serverTransactions,
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      // 1. تعليم العناصر التي تم رفعها بنجاح بأنها متزامنة (isSynced = 1)
      for (final id in uploadedWalletIds) {
        batch.update('wallets', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
      }
      for (final id in uploadedTransactionIds) {
        batch.update('transactions', {'isSynced': 1}, where: 'id = ?', whereArgs: [id]);
      }

      // 2. إدراج أو تحديث المحافظ القادمة من السيرفر (Downstream)
      for (final sWallet in serverWallets) {
        batch.insert(
          'wallets',
          sWallet.copyWith(isSynced: true).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 3. إدراج أو تحديث المعاملات القادمة من السيرفر (Downstream)
      for (final sTx in serverTransactions) {
        batch.insert(
          'transactions',
          sTx.copyWith(isSynced: true).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }
}