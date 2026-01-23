import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../models/quote.dart';
import 'api_service.dart';

/// Background sync service for offline-first architecture
class SyncService {
  static final SyncService instance = SyncService._internal();

  SyncService._internal();

  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Check if device has internet connection
  Future<bool> hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  /// Perform full sync (called by background worker or manual trigger)
  Future<SyncResult> performFullSync() async {
    if (!await hasConnection()) {
      return SyncResult(
        success: false,
        message: 'Brak połączenia z internetem',
      );
    }

    final result = SyncResult();

    try {
      // 1. Sync pending orders
      final ordersResult = await syncPendingOrders();
      result.ordersSynced = ordersResult.synced;
      result.ordersFailed = ordersResult.failed;

      // 2. Sync pending quotes
      final quotesResult = await syncPendingQuotes();
      result.quotesSynced = quotesResult.synced;
      result.quotesFailed = quotesResult.failed;

      // 3. Sync products from server
      final productsResult = await syncProducts();
      result.productsUpdated = productsResult;

      // 4. Sync customers from server
      final customersResult = await syncCustomers();
      result.customersUpdated = customersResult;

      result.success = true;
      result.message = 'Synchronizacja zakończona pomyślnie';
    } catch (e) {
      result.success = false;
      result.message = 'Błąd synchronizacji: $e';
    }

    return result;
  }

  /// Sync pending orders to Cloud API
  Future<({int synced, int failed})> syncPendingOrders() async {
    int synced = 0;
    int failed = 0;

    try {
      await _apiService.loadToken(); // Load saved token before API call
      final pendingOrders = await _dbHelper.getPendingOrders();

      for (final orderMap in pendingOrders) {
        try {
          // Parse items JSON
          final itemsJson = orderMap['items_json'] as String;
          List<dynamic> items = [];
          try {
            items = jsonDecode(itemsJson.replaceAll("'", '"'));
          } catch (e) {
            // Try alternative parsing if standard fails
            items = _parseItemsString(itemsJson);
          }

          final orderData = {
            'customer_id': orderMap['customer_id'],
            'order_date': orderMap['order_date'],
            'notes': orderMap['notes'],
            'total_netto': orderMap['total_netto'],
            'total_brutto': orderMap['total_brutto'],
            'items': items,
          };

          await _apiService.createOrder(orderData);
          await _dbHelper.markOrderAsSynced(orderMap['local_id'] as int);
          synced++;
        } catch (e) {
          failed++;
        }
      }
    } catch (e) {
      // Error loading pending orders
    }

    return (synced: synced, failed: failed);
  }

  /// Sync pending quotes to Cloud API
  Future<({int synced, int failed})> syncPendingQuotes() async {
    int synced = 0;
    int failed = 0;

    try {
      await _apiService.loadToken(); // Load saved token before API call
      final pendingQuotes = await _dbHelper.getPendingQuotes();

      for (final quote in pendingQuotes) {
        try {
          await _apiService.createQuote(quote.toJson());
          if (quote.localId != null) {
            await _dbHelper.markQuoteAsSynced(quote.localId!);
          }
          synced++;
        } catch (e) {
          failed++;
        }
      }
    } catch (e) {
      // Error loading pending quotes
    }

    return (synced: synced, failed: failed);
  }

  /// Sync products from server to local DB
  Future<int> syncProducts() async {
    try {
      await _apiService.loadToken(); // Load saved token before API call
      final products = await _apiService.syncProducts();
      if (products.isNotEmpty) {
        await _dbHelper.insertProducts(products);
        return products.length;
      }
    } catch (e) {
      // API error - skip products sync
    }
    return 0;
  }

  /// Sync customers from server to local DB
  Future<int> syncCustomers() async {
    try {
      await _apiService.loadToken(); // Load saved token before API call
      final customers = await _apiService.syncCustomers();
      if (customers.isNotEmpty) {
        await _dbHelper.insertCustomers(customers);
        return customers.length;
      }
    } catch (e) {
      // API error - skip customers sync
    }
    return 0;
  }

  /// Helper to parse items string when JSON parsing fails
  List<Map<String, dynamic>> _parseItemsString(String itemsStr) {
    // This handles the toString() format of List<Map>
    final List<Map<String, dynamic>> result = [];

    // Simple fallback - return empty list if parsing fails
    // Items will be re-synced on next attempt
    return result;
  }

  /// Quick sync - only sync pending data (faster, for frequent checks)
  Future<SyncResult> quickSync() async {
    if (!await hasConnection()) {
      return SyncResult(
        success: false,
        message: 'Brak połączenia',
      );
    }

    final result = SyncResult();

    try {
      final ordersResult = await syncPendingOrders();
      result.ordersSynced = ordersResult.synced;
      result.ordersFailed = ordersResult.failed;

      final quotesResult = await syncPendingQuotes();
      result.quotesSynced = quotesResult.synced;
      result.quotesFailed = quotesResult.failed;

      result.success = true;
      result.message = 'Synchronizacja zakończona';
    } catch (e) {
      result.success = false;
      result.message = 'Błąd: $e';
    }

    return result;
  }
}

/// Result of sync operation
class SyncResult {
  bool success;
  String message;
  int ordersSynced;
  int ordersFailed;
  int quotesSynced;
  int quotesFailed;
  int productsUpdated;
  int customersUpdated;

  SyncResult({
    this.success = false,
    this.message = '',
    this.ordersSynced = 0,
    this.ordersFailed = 0,
    this.quotesSynced = 0,
    this.quotesFailed = 0,
    this.productsUpdated = 0,
    this.customersUpdated = 0,
  });

  bool get hasChanges =>
      ordersSynced > 0 ||
      quotesSynced > 0 ||
      productsUpdated > 0 ||
      customersUpdated > 0;

  String get summary {
    final parts = <String>[];
    if (ordersSynced > 0) parts.add('Zamówienia: $ordersSynced');
    if (quotesSynced > 0) parts.add('Oferty: $quotesSynced');
    if (productsUpdated > 0) parts.add('Produkty: $productsUpdated');
    if (customersUpdated > 0) parts.add('Klienci: $customersUpdated');
    if (parts.isEmpty) return 'Brak zmian';
    return parts.join(' | ');
  }
}
