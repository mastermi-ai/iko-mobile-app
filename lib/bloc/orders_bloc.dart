import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/order.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {}

class RefreshOrders extends OrdersEvent {}

// States
abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Map<String, dynamic>> pendingOrders;
  final List<Map<String, dynamic>> syncedOrders;

  const OrdersLoaded({
    required this.pendingOrders,
    required this.syncedOrders,
  });

  int get totalOrders => pendingOrders.length + syncedOrders.length;

  @override
  List<Object?> get props => [pendingOrders, syncedOrders];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrdersRefreshing extends OrdersState {
  final List<Map<String, dynamic>> currentPendingOrders;
  final List<Map<String, dynamic>> currentSyncedOrders;

  const OrdersRefreshing({
    required this.currentPendingOrders,
    required this.currentSyncedOrders,
  });

  @override
  List<Object?> get props => [currentPendingOrders, currentSyncedOrders];
}

// BLoC
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;

  OrdersBloc({
    required DatabaseHelper databaseHelper,
    required ApiService apiService,
  })  : _databaseHelper = databaseHelper,
        _apiService = apiService,
        super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<RefreshOrders>(_onRefreshOrders);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      // Load pending orders from local DB
      final pendingOrders = await _databaseHelper.getPendingOrders();

      // Load synced orders from API
      List<Map<String, dynamic>> syncedOrders = [];
      try {
        final response = await _apiService.getOrders();
        syncedOrders = List<Map<String, dynamic>>.from(response);
      } catch (e) {
        // API unavailable - just show pending orders
      }

      emit(OrdersLoaded(
        pendingOrders: pendingOrders,
        syncedOrders: syncedOrders,
      ));
    } catch (e) {
      emit(OrdersError('Nie udało się załadować zamówień: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrdersLoaded) {
      emit(OrdersRefreshing(
        currentPendingOrders: currentState.pendingOrders,
        currentSyncedOrders: currentState.syncedOrders,
      ));
    }

    try {
      // Reload pending orders
      final pendingOrders = await _databaseHelper.getPendingOrders();

      // Reload synced orders from API
      final syncedOrders = List<Map<String, dynamic>>.from(
        await _apiService.getOrders(),
      );

      emit(OrdersLoaded(
        pendingOrders: pendingOrders,
        syncedOrders: syncedOrders,
      ));
    } catch (e) {
      if (currentState is OrdersLoaded) {
        emit(currentState);
      }
      emit(OrdersError('Błąd synchronizacji: ${e.toString()}'));
    }
  }
}
