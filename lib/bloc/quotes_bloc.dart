import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/quote.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';

abstract class QuotesEvent extends Equatable {
  const QuotesEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuotes extends QuotesEvent {}

class RefreshQuotes extends QuotesEvent {}

class CreateQuote extends QuotesEvent {
  final Quote quote;

  const CreateQuote(this.quote);

  @override
  List<Object?> get props => [quote];
}

class UpdateQuoteStatus extends QuotesEvent {
  final int localId;
  final String newStatus;

  const UpdateQuoteStatus({required this.localId, required this.newStatus});

  @override
  List<Object?> get props => [localId, newStatus];
}

class DeleteQuote extends QuotesEvent {
  final int localId;

  const DeleteQuote(this.localId);

  @override
  List<Object?> get props => [localId];
}

class ConvertQuoteToOrder extends QuotesEvent {
  final int localId;

  const ConvertQuoteToOrder(this.localId);

  @override
  List<Object?> get props => [localId];
}

abstract class QuotesState extends Equatable {
  const QuotesState();

  @override
  List<Object?> get props => [];
}

class QuotesInitial extends QuotesState {}

class QuotesLoading extends QuotesState {}

class QuotesLoaded extends QuotesState {
  final List<Quote> localQuotes;
  final List<Quote> syncedQuotes;

  const QuotesLoaded({
    required this.localQuotes,
    required this.syncedQuotes,
  });

  List<Quote> get allQuotes => [...localQuotes, ...syncedQuotes];

  List<Quote> get draftQuotes =>
      localQuotes.where((q) => q.status == 'draft').toList();

  List<Quote> get sentQuotes =>
      [...localQuotes, ...syncedQuotes]
          .where((q) => q.status == 'sent')
          .toList();

  List<Quote> get acceptedQuotes =>
      [...localQuotes, ...syncedQuotes]
          .where((q) => q.status == 'accepted')
          .toList();

  int get totalQuotes => localQuotes.length + syncedQuotes.length;

  @override
  List<Object?> get props => [localQuotes, syncedQuotes];
}

class QuotesError extends QuotesState {
  final String message;

  const QuotesError(this.message);

  @override
  List<Object?> get props => [message];
}

class QuotesRefreshing extends QuotesState {
  final List<Quote> currentLocalQuotes;
  final List<Quote> currentSyncedQuotes;

  const QuotesRefreshing({
    required this.currentLocalQuotes,
    required this.currentSyncedQuotes,
  });

  @override
  List<Object?> get props => [currentLocalQuotes, currentSyncedQuotes];
}

class QuoteCreated extends QuotesState {
  final Quote quote;

  const QuoteCreated(this.quote);

  @override
  List<Object?> get props => [quote];
}

class QuoteConverted extends QuotesState {
  final Quote quote;

  const QuoteConverted(this.quote);

  @override
  List<Object?> get props => [quote];
}

class QuotesBloc extends Bloc<QuotesEvent, QuotesState> {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;

  QuotesBloc({
    required DatabaseHelper databaseHelper,
    required ApiService apiService,
  })  : _databaseHelper = databaseHelper,
        _apiService = apiService,
        super(QuotesInitial()) {
    on<LoadQuotes>(_onLoadQuotes);
    on<RefreshQuotes>(_onRefreshQuotes);
    on<CreateQuote>(_onCreateQuote);
    on<UpdateQuoteStatus>(_onUpdateQuoteStatus);
    on<DeleteQuote>(_onDeleteQuote);
    on<ConvertQuoteToOrder>(_onConvertQuoteToOrder);
  }

  Future<void> _onLoadQuotes(
    LoadQuotes event,
    Emitter<QuotesState> emit,
  ) async {
    emit(QuotesLoading());
    try {
      final localQuotes = await _databaseHelper.getAllLocalQuotes();

      List<Quote> syncedQuotes = [];
      try {
        final response = await _apiService.getQuotes();
        syncedQuotes = response;
      } catch (e) {
        // API unavailable - show local quotes only
      }

      emit(QuotesLoaded(
        localQuotes: localQuotes,
        syncedQuotes: syncedQuotes,
      ));
    } catch (e) {
      emit(QuotesError('Nie udało się załadować ofert: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshQuotes(
    RefreshQuotes event,
    Emitter<QuotesState> emit,
  ) async {
    final currentState = state;
    if (currentState is QuotesLoaded) {
      emit(QuotesRefreshing(
        currentLocalQuotes: currentState.localQuotes,
        currentSyncedQuotes: currentState.syncedQuotes,
      ));
    }

    try {
      final localQuotes = await _databaseHelper.getAllLocalQuotes();

      List<Quote> syncedQuotes = [];
      try {
        syncedQuotes = await _apiService.getQuotes();
      } catch (e) {
        // API unavailable
      }

      emit(QuotesLoaded(
        localQuotes: localQuotes,
        syncedQuotes: syncedQuotes,
      ));
    } catch (e) {
      if (currentState is QuotesLoaded) {
        emit(currentState);
      }
      emit(QuotesError('Błąd odświeżania: ${e.toString()}'));
    }
  }

  Future<void> _onCreateQuote(
    CreateQuote event,
    Emitter<QuotesState> emit,
  ) async {
    try {
      final localId = await _databaseHelper.insertQuote(event.quote);

      bool synced = false;
      try {
        await _apiService.createQuote(event.quote.toJson());
        await _databaseHelper.markQuoteAsSynced(localId);
        synced = true;
      } catch (e) {
        // API sync failed - will sync later
      }

      final savedQuote = event.quote.copyWith(
        localId: localId,
        synced: synced,
      );

      emit(QuoteCreated(savedQuote));
      add(LoadQuotes());
    } catch (e) {
      emit(QuotesError('Nie udało się utworzyć oferty: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateQuoteStatus(
    UpdateQuoteStatus event,
    Emitter<QuotesState> emit,
  ) async {
    try {
      await _databaseHelper.updateQuoteStatus(event.localId, event.newStatus);
      add(LoadQuotes());
    } catch (e) {
      emit(QuotesError('Nie udało się zaktualizować statusu: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteQuote(
    DeleteQuote event,
    Emitter<QuotesState> emit,
  ) async {
    try {
      await _databaseHelper.deleteQuote(event.localId);
      add(LoadQuotes());
    } catch (e) {
      emit(QuotesError('Nie udało się usunąć oferty: ${e.toString()}'));
    }
  }

  Future<void> _onConvertQuoteToOrder(
    ConvertQuoteToOrder event,
    Emitter<QuotesState> emit,
  ) async {
    try {
      final quote = await _databaseHelper.getQuoteByLocalId(event.localId);
      if (quote == null) {
        emit(const QuotesError('Nie znaleziono oferty'));
        return;
      }

      await _databaseHelper.updateQuoteStatus(event.localId, 'converted');
      emit(QuoteConverted(quote));
    } catch (e) {
      emit(QuotesError('Nie udało się przekonwertować oferty: ${e.toString()}'));
    }
  }
}
