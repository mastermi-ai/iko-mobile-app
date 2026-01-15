import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/customer.dart';

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
      version: 1,
      onCreate: _createDB,
    );
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

  Future close() async {
    final db = await database;
    db.close();
  }
}
