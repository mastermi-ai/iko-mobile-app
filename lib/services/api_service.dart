import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/quote.dart';

class ApiService {
  // Cloud API URL - serwer klienta (stały adres)
  static const String baseUrl = 'https://iko-grabos.com';

  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        // Required header for localtunnel to bypass warning page
        'bypass-tunnel-reminder': 'true',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        // Always add bypass header for localtunnel
        options.headers['bypass-tunnel-reminder'] = 'true';
        return handler.next(options);
      },
      onError: (error, handler) {
        // TODO: Add proper logging in production
        // print('API Error: ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Authentication
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final token = response.data['access_token'] as String;
      await saveToken(token);

      return response.data;
    } on DioException catch (e) {
      throw Exception('Login failed: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // Sync Customers
  Future<List<Customer>> syncCustomers({String? since}) async {
    try {
      final queryParams = since != null ? {'since': since} : null;
      final response = await _dio.get('/sync/customers', queryParameters: queryParams);

      final data = response.data['data'] as List;
      return data.map((json) => Customer.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to sync customers: ${e.message}');
    }
  }

  // Sync Products
  Future<List<Product>> syncProducts({String? since}) async {
    try {
      final queryParams = since != null ? {'since': since} : null;
      final response = await _dio.get('/sync/products', queryParameters: queryParams);

      final data = response.data['data'] as List;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to sync products: ${e.message}');
    }
  }

  // Create Order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post('/orders', data: orderData);
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to create order: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // Get Orders
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await _dio.get('/orders');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get orders: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> quoteData) async {
    try {
      final response = await _dio.post('/quotes', data: quoteData);
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to create quote: ${e.response?.data['message'] ?? e.message}');
    }
  }

  // Get Quotes
  Future<List<Quote>> getQuotes() async {
    try {
      final response = await _dio.get('/quotes');
      final data = response.data as List;
      return data.map((json) => Quote.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to get quotes: ${e.message}');
    }
  }

  // Get Quote by ID
  Future<Quote> getQuote(int id) async {
    try {
      final response = await _dio.get('/quotes/$id');
      return Quote.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get quote: ${e.message}');
    }
  }

  // Update Quote Status
  Future<Quote> updateQuoteStatus(int id, String status) async {
    try {
      final response = await _dio.patch('/quotes/$id/status', data: {
        'status': status,
      });
      return Quote.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to update quote status: ${e.message}');
    }
  }

  // Convert Quote to Order
  Future<Map<String, dynamic>> convertQuoteToOrder(int quoteId) async {
    try {
      final response = await _dio.post('/quotes/$quoteId/convert');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to convert quote: ${e.response?.data['message'] ?? e.message}');
    }
  }
}
