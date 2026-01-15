import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/product.dart';
import '../../database/database_helper.dart';
import '../../services/api_service.dart';

// Events
abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {}

class SearchProducts extends ProductsEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class RefreshProducts extends ProductsEvent {}

// States
abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final bool isSearching;

  const ProductsLoaded(this.products, {this.isSearching = false});

  @override
  List<Object?> get props => [products, isSearching];
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductsRefreshing extends ProductsState {
  final List<Product> currentProducts;

  const ProductsRefreshing(this.currentProducts);

  @override
  List<Object?> get props => [currentProducts];
}

// BLoC
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;

  ProductsBloc({
    required DatabaseHelper databaseHelper,
    required ApiService apiService,
  })  : _databaseHelper = databaseHelper,
        _apiService = apiService,
        super(ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
    on<RefreshProducts>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await _databaseHelper.getProducts();
      
      if (products.isEmpty) {
        // Try to sync from API if local DB is empty
        await _syncProductsFromApi();
        final syncedProducts = await _databaseHelper.getProducts();
        emit(ProductsLoaded(syncedProducts));
      } else {
        emit(ProductsLoaded(products));
      }
    } catch (e) {
      emit(ProductsError('Nie udało się załadować produktów: ${e.toString()}'));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductsState> emit,
  ) async {
    if (event.query.isEmpty) {
      // Reload all products
      final products = await _databaseHelper.getProducts();
      emit(ProductsLoaded(products));
      return;
    }

    try {
      final products = await _databaseHelper.searchProducts(event.query);
      emit(ProductsLoaded(products, isSearching: true));
    } catch (e) {
      emit(ProductsError('Błąd wyszukiwania: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    // Keep current products while refreshing
    final currentState = state;
    if (currentState is ProductsLoaded) {
      emit(ProductsRefreshing(currentState.products));
    }

    try {
      await _syncProductsFromApi();
      final products = await _databaseHelper.getProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      // Revert to previous state on error
      if (currentState is ProductsLoaded) {
        emit(currentState);
      }
      emit(ProductsError('Błąd synchronizacji: ${e.toString()}'));
    }
  }

  Future<void> _syncProductsFromApi() async {
    try {
      final products = await _apiService.syncProducts();
      await _databaseHelper.deleteAllProducts();
      await _databaseHelper.insertProducts(products);
    } catch (e) {
      throw Exception('Failed to sync products: $e');
    }
  }
}
