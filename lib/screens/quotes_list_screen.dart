import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/quotes_bloc.dart';
import '../models/quote.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import 'quote_detail_screen.dart';

class QuotesListScreen extends StatelessWidget {
  const QuotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuotesBloc(
        databaseHelper: DatabaseHelper.instance,
        apiService: ApiService(),
      )..add(LoadQuotes()),
      child: const _QuotesListView(),
    );
  }
}

class _QuotesListView extends StatelessWidget {
  const _QuotesListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oferty'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<QuotesBloc>().add(RefreshQuotes());
            },
          ),
        ],
      ),
      body: BlocConsumer<QuotesBloc, QuotesState>(
        listener: (context, state) {
          if (state is QuotesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is QuotesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QuotesLoaded || state is QuotesRefreshing) {
            final localQuotes = state is QuotesLoaded
                ? state.localQuotes
                : (state as QuotesRefreshing).currentLocalQuotes;
            final syncedQuotes = state is QuotesLoaded
                ? state.syncedQuotes
                : (state as QuotesRefreshing).currentSyncedQuotes;

            if (localQuotes.isEmpty && syncedQuotes.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<QuotesBloc>().add(RefreshQuotes());
              },
              child: _buildQuotesList(context, localQuotes, syncedQuotes),
            );
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Brak ofert',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utwórz ofertę z koszyka',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Przejdź do koszyka'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesList(
    BuildContext context,
    List<Quote> localQuotes,
    List<Quote> syncedQuotes,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.orange[700],
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_note, size: 20),
                      const SizedBox(width: 8),
                      Text('Lokalne (${localQuotes.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_done, size: 20),
                      const SizedBox(width: 8),
                      Text('Zsynchronizowane (${syncedQuotes.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildQuotesListView(context, localQuotes, isLocal: true),
                _buildQuotesListView(context, syncedQuotes, isLocal: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesListView(
    BuildContext context,
    List<Quote> quotes, {
    required bool isLocal,
  }) {
    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocal ? Icons.drafts_outlined : Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isLocal ? 'Brak lokalnych ofert' : 'Brak zsynchronizowanych ofert',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return _QuoteCard(quote: quote, isLocal: isLocal);
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final bool isLocal;

  const _QuoteCard({
    required this.quote,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuoteDetailScreen(
                quote: quote,
                isLocal: isLocal,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status badge
                  _StatusBadge(status: quote.status),
                  const Spacer(),
                  // Sync indicator
                  if (isLocal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: quote.synced
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            quote.synced ? Icons.cloud_done : Icons.cloud_off,
                            size: 14,
                            color: quote.synced
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quote.synced ? 'Zsync.' : 'Lokalnie',
                            style: TextStyle(
                              fontSize: 11,
                              color: quote.synced
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer name
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quote.customerName ?? 'Klient #${quote.customerId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date row
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(quote.quoteDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (quote.validUntil != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: quote.isValid ? Colors.grey : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ważna do: ${DateFormat('dd.MM.yyyy').format(quote.validUntil!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: quote.isValid ? Colors.grey[600] : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Items count and total
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${quote.items.length} pozycji',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${quote.totalNetto.toStringAsFixed(2)} zł netto',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (quote.totalBrutto != null)
                        Text(
                          '${quote.totalBrutto!.toStringAsFixed(2)} zł brutto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'draft':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        icon = Icons.edit;
        label = 'Szkic';
        break;
      case 'sent':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        icon = Icons.send;
        label = 'Wysłana';
        break;
      case 'accepted':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        label = 'Zaakceptowana';
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        label = 'Odrzucona';
        break;
      case 'expired':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        icon = Icons.timer_off;
        label = 'Wygasła';
        break;
      case 'converted':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[700]!;
        icon = Icons.transform;
        label = 'Przekonwertowana';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
