import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/customer.dart';
import '../../database/database_helper.dart';
import '../../services/api_service.dart';

// Events
abstract class CustomersEvent extends Equatable {
  const CustomersEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomersEvent {}

class SearchCustomers extends CustomersEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object?> get props => [query];
}

class RefreshCustomers extends CustomersEvent {}

// States
abstract class CustomersState extends Equatable {
  const CustomersState();

  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState {}

class CustomersLoading extends CustomersState {}

class CustomersLoaded extends CustomersState {
  final List<Customer> customers;
  final bool isSearching;

  const CustomersLoaded(this.customers, {this.isSearching = false});

  @override
  List<Object?> get props => [customers, isSearching];
}

class CustomersError extends CustomersState {
  final String message;

  const CustomersError(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomersRefreshing extends CustomersState {
  final List<Customer> currentCustomers;

  const CustomersRefreshing(this.currentCustomers);

  @override
  List<Object?> get props => [currentCustomers];
}

// BLoC
class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;

  CustomersBloc({
    required DatabaseHelper databaseHelper,
    required ApiService apiService,
  })  : _databaseHelper = databaseHelper,
        _apiService = apiService,
        super(CustomersInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<RefreshCustomers>(_onRefreshCustomers);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomersState> emit,
  ) async {
    emit(CustomersLoading());
    try {
      final customers = await _databaseHelper.getCustomers();
      
      if (customers.isEmpty) {
        // Try to sync from API if local DB is empty
        await _syncCustomersFromApi();
        final syncedCustomers = await _databaseHelper.getCustomers();
        emit(CustomersLoaded(syncedCustomers));
      } else {
        emit(CustomersLoaded(customers));
      }
    } catch (e) {
      emit(CustomersError('Nie udało się załadować klientów: ${e.toString()}'));
    }
  }

  Future<void> _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomersState> emit,
  ) async {
    if (event.query.isEmpty) {
      // Reload all customers
      final customers = await _databaseHelper.getCustomers();
      emit(CustomersLoaded(customers));
      return;
    }

    try {
      final customers = await _databaseHelper.searchCustomers(event.query);
      emit(CustomersLoaded(customers, isSearching: true));
    } catch (e) {
      emit(CustomersError('Błąd wyszukiwania: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshCustomers(
    RefreshCustomers event,
    Emitter<CustomersState> emit,
  ) async {
    // Keep current customers while refreshing
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(CustomersRefreshing(currentState.customers));
    }

    try {
      await _syncCustomersFromApi();
      final customers = await _databaseHelper.getCustomers();
      emit(CustomersLoaded(customers));
    } catch (e) {
      // Revert to previous state on error
      if (currentState is CustomersLoaded) {
        emit(currentState);
      }
      emit(CustomersError('Błąd synchronizacji: ${e.toString()}'));
    }
  }

  Future<void> _syncCustomersFromApi() async {
    try {
      final customers = await _apiService.syncCustomers();
      await _databaseHelper.deleteAllCustomers();
      await _databaseHelper.insertCustomers(customers);
    } catch (e) {
      throw Exception('Failed to sync customers: $e');
    }
  }
}
