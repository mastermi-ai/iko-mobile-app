import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/customer.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.data}');
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
}
