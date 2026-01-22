import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/quote.dart';
import '../models/saved_cart.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iko_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add pending_quotes table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_quotes (
          local_id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER,
          customer_name TEXT,
          quote_date TEXT NOT NULL,
          valid_until TEXT,
          status TEXT DEFAULT 'draft',
          notes TEXT,
          total_netto REAL NOT NULL,
          total_brutto REAL,
          items_json TEXT NOT NULL,
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add saved_carts table (schowki)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saved_carts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          customer_id INTEGER,
          customer_name TEXT,
          items_json TEXT NOT NULL,
          total_netto REAL NOT NULL,
          total_brutto REAL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const integerType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const realTypeNullable = 'REAL';

    await db.execute('''
      CREATE TABLE products (
        id $integerType,
        client_id $integerType,
        nexo_id $textTypeNullable,
        code $textType,
        name $textType,
        description $textTypeNullable,
        image_url $textTypeNullable,
        price_netto $realType,
        price_brutto $realTypeNullable,
        vat_rate $realTypeNullable,
        unit $textType,
        ean $textTypeNullable,
        active $integerType,
        synced_at $textTypeNullable,
        PRIMARY KEY (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id $integerType,
        client_id $integerType,
        nexo_id $textTypeNullable,
        name $textType,
        short_name $textTypeNullable,
        address $textTypeNullable,
        postal_code $textTypeNullable,
        city $textTypeNullable,
        phone1 $textTypeNullable,
        phone2 $textTypeNullable,
        email $textTypeNullable,
        nip $textTypeNullable,
        regon $textTypeNullable,
        voivodeship $textTypeNullable,
        synced_at $textTypeNullable,
        PRIMARY KEY (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_orders (
        local_id $idType,
        customer_id INTEGER,
        order_date $textType,
        notes $textTypeNullable,
        total_netto $realType,
        total_brutto $realTypeNullable,
        items_json $textType,
        created_at $textType,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_quotes (
        local_id $idType,
        customer_id INTEGER,
        customer_name $textTypeNullable,
        quote_date $textType,
        valid_until $textTypeNullable,
        status $textType DEFAULT 'draft',
        notes $textTypeNullable,
        total_netto $realType,
        total_brutto $realTypeNullable,
        items_json $textType,
        created_at $textType,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_carts (
        id $idType,
        name $textType,
        customer_id INTEGER,
        customer_name $textTypeNullable,
        items_json $textType,
        total_netto $realType,
        total_brutto $realTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');
  }

  // Products
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (var product in products) {
      batch.insert('products', product.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return products.length;
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final result = await db.query('products', where: 'active = ?', whereArgs: [1]);
    return result.map((json) => Product.fromDatabase(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'active = ? AND (name LIKE ? OR code LIKE ?)',
      whereArgs: [1, '%$query%', '%$query%'],
    );
    return result.map((json) => Product.fromDatabase(json)).toList();
  }

  /// Wyszukaj produkt po kodzie EAN (dla skanera)
  /// Wymaganie klienta: skanowanie kodów kreskowych
  Future<Product?> getProductByEan(String ean) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'active = ? AND ean = ?',
      whereArgs: [1, ean],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Product.fromDatabase(result.first);
  }

  /// Wyszukaj produkt po kodzie produktu
  Future<Product?> getProductByCode(String code) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'active = ? AND code = ?',
      whereArgs: [1, code],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Product.fromDatabase(result.first);
  }

  Future<int> deleteAllProducts() async {
    final db = await database;
    return await db.delete('products');
  }

  // Customers
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertCustomers(List<Customer> customers) async {
    final db = await database;
    final batch = db.batch();
    for (var customer in customers) {
      batch.insert('customers', customer.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return customers.length;
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final result = await db.query('customers');
    return result.map((json) => Customer.fromDatabase(json)).toList();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'name LIKE ? OR city LIKE ? OR nip LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((json) => Customer.fromDatabase(json)).toList();
  }

  Future<int> deleteAllCustomers() async {
    final db = await database;
    return await db.delete('customers');
  }

  // Pending Orders (offline queue)
  Future<int> insertPendingOrder(dynamic order) async {
    final db = await database;

    // Convert Order object to database map
    final orderData = {
      'customer_id': order.customerId,
      'order_date': order.orderDate.toIso8601String(),
      'notes': order.notes,
      'total_netto': order.totalNetto,
      'total_brutto': order.totalBrutto,
      'items_json': order.toJson()['items'].toString(),
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };

    return await db.insert('pending_orders', orderData);
  }

  Future<int> savePendingOrder(Map<String, dynamic> orderData) async {
    final db = await database;
    return await db.insert('pending_orders', orderData);
  }

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await database;
    return await db.query('pending_orders', where: 'synced = ?', whereArgs: [0]);
  }

  Future<int> markOrderAsSynced(int localId) async {
    final db = await database;
    return await db.update(
      'pending_orders',
      {'synced': 1},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  // ============================================
  // QUOTES (Oferty)
  // ============================================

  /// Insert a new quote to local database
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return await db.insert('pending_quotes', quote.toDatabase());
  }

  /// Get all pending (not synced) quotes
  Future<List<Quote>> getPendingQuotes() async {
    final db = await database;
    final result = await db.query(
      'pending_quotes',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Quote.fromDatabase(map)).toList();
  }

  /// Get all quotes (both synced and pending)
  Future<List<Quote>> getAllLocalQuotes() async {
    final db = await database;
    final result = await db.query(
      'pending_quotes',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Quote.fromDatabase(map)).toList();
  }

  /// Get quote by local ID
  Future<Quote?> getQuoteByLocalId(int localId) async {
    final db = await database;
    final result = await db.query(
      'pending_quotes',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Quote.fromDatabase(result.first);
  }

  /// Update quote status
  Future<int> updateQuoteStatus(int localId, String status) async {
    final db = await database;
    return await db.update(
      'pending_quotes',
      {'status': status},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Mark quote as synced
  Future<int> markQuoteAsSynced(int localId) async {
    final db = await database;
    return await db.update(
      'pending_quotes',
      {'synced': 1},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Delete quote by local ID
  Future<int> deleteQuote(int localId) async {
    final db = await database;
    return await db.delete(
      'pending_quotes',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Delete all synced quotes (cleanup)
  Future<int> deleteSyncedQuotes() async {
    final db = await database;
    return await db.delete(
      'pending_quotes',
      where: 'synced = ?',
      whereArgs: [1],
    );
  }

  // ============================================
  // SAVED CARTS (Schowki)
  // ============================================

  /// Save current cart as a "schowek"
  Future<int> saveCart(SavedCart cart) async {
    final db = await database;
    return await db.insert('saved_carts', cart.toDatabase());
  }

  /// Get all saved carts
  Future<List<SavedCart>> getSavedCarts() async {
    final db = await database;
    final result = await db.query(
      'saved_carts',
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => SavedCart.fromDatabase(map)).toList();
  }

  /// Get saved cart by ID
  Future<SavedCart?> getSavedCartById(int id) async {
    final db = await database;
    final result = await db.query(
      'saved_carts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return SavedCart.fromDatabase(result.first);
  }

  /// Update saved cart
  Future<int> updateSavedCart(int id, SavedCart cart) async {
    final db = await database;
    final data = cart.toDatabase();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'saved_carts',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Rename saved cart
  Future<int> renameSavedCart(int id, String newName) async {
    final db = await database;
    return await db.update(
      'saved_carts',
      {
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete saved cart
  Future<int> deleteSavedCart(int id) async {
    final db = await database;
    return await db.delete(
      'saved_carts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search saved carts by name
  Future<List<SavedCart>> searchSavedCarts(String query) async {
    final db = await database;
    final result = await db.query(
      'saved_carts',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => SavedCart.fromDatabase(map)).toList();
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
