import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:cinebook_core/cinebook_core.dart';
import '../blocs/chat/chat_bloc.dart';
import '../blocs/chat/chat_event.dart';
import '../blocs/chat/chat_state.dart';
import '../widgets/a2ui_form.dart';
import 'dart:convert';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  late final ChatMessagesController _controller;
  late final ChatUser _currentUser;
  late final ChatUser _aiUser;

  @override
  void initState() {
    super.initState();
    _controller = ChatMessagesController();
    _currentUser = ChatUser(id: 'user', firstName: 'You');
    _aiUser = ChatUser(id: 'ai', firstName: 'CineBot');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showConfirmationDialog(
    BuildContext context,
    ChatBloc bloc,
    Map<String, dynamic> data,
  ) {
    final movieTitle = data['movieTitle'] ?? data['summary']?['movieTitle'] ?? data['booking']?['show']?['movie']?['title'] ?? 'Movie';
    final totalCost = data['totalCost'] ?? data['summary']?['totalCost'] ?? 0;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Do you want to confirm the booking for $movieTitle? Total: ₹$totalCost',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(ChatSendMessage('No, cancel booking.'));
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(ChatSendMessage('Yes, confirm and pay.'));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          ChatBloc(apiClient: ctx.read<ApiClient>(), controller: _controller)
            ..add(ChatFetchThreads()),
      child: BlocListener<ChatBloc, ChatState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final bloc = context.read<ChatBloc>();

            return Scaffold(
              appBar: AppBar(
                title: const Text('CineBot'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      bloc.add(ChatClearHistory());
                    },
                  ),
                ],
              ),
              drawer: Drawer(
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Past Threads',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: CinemaColors.warmAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (state.isLoadingThreads)
                        const CircularProgressIndicator(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.threads.length,
                          itemBuilder: (context, index) {
                            final thread = state.threads[index];
                            return ListTile(
                              title: Text(
                                'Thread ${thread['id'].toString().substring(0, 8)}',
                              ),
                              subtitle: Text(
                                thread['createdAt'].toString().substring(0, 10),
                              ),
                              onTap: () {
                                Navigator.pop(context); // close drawer
                                bloc.add(ChatSwitchThread(thread['id']));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body: Column(
                children: [
                  if (state.bookingContext.containsKey('holdToken') ||
                      state.bookingContext.containsKey('heldSeatIds'))
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: CinemaColors.warmAmber.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: CinemaColors.warmAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have seats on hold. Please confirm booking before the hold expires.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: CinemaColors.warmAmber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: AiChatWidget(
                      key: ValueKey(state.threadId ?? 'new'),
                      currentUser: _currentUser,
                      aiUser: _aiUser,
                      controller: _controller,
                      onSendMessage: (msg) =>
                          bloc.add(ChatSendMessage(msg.text)),
                      onCancelGenerating: () => bloc.add(ChatCancelMessage()),
                      loadingConfig: LoadingConfig(isLoading: state.isLoading),
                      enableMarkdownStreaming: true,
                      streamingWordByWord: false,
                      streamingDuration: const Duration(milliseconds: 30),
                      resultRenderers: {
                        'a2ui': (ctx, data) {
                          return A2UiForm(
                            data: data,
                            onSubmit: (values) {
                              bloc.add(
                                ChatSendMessage(
                                  jsonEncode({
                                    'event': 'booking_preferences_submitted',
                                    'data': values,
                                  }),
                                ),
                              );
                            },
                          );
                        },
                        'movieList': (ctx, data) => _buildMovieList(data),
                        'movieCard': (ctx, data) => _buildMovieCard(data),
                        'showtimes': (ctx, data) => _buildShowtimes(data),
                        'seatMap': (ctx, data) => _buildSeatMapPreview(data),
                        'bookingSummary': (ctx, data) {
                          // When we get a booking summary, we might want to prompt for confirmation
                          // We'll show the summary and add a confirm button
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBookingSummary(data),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () => _showConfirmationDialog(
                                  context,
                                  bloc,
                                  data,
                                ),
                                child: const Text('Confirm Booking'),
                              ),
                            ],
                          );
                        },
                        'paymentResult': (ctx, data) =>
                            _buildPaymentResult(data),
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMovieList(Map<String, dynamic> data) {
    final movies = data['movies'] as List<dynamic>? ?? [];
    if (movies.isEmpty) return const Text('No movies found.');

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (ctx, i) {
          final movie = movies[i];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: movie['posterUrl'] != null
                        ? Image.network(
                            movie['posterUrl'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: CinemaColors.inkCharcoal,
                                  child: const Icon(
                                    Icons.movie,
                                    color: CinemaColors.steelGray,
                                  ),
                                ),
                          )
                        : Container(
                            color: CinemaColors.inkCharcoal,
                            child: const Icon(
                              Icons.movie,
                              color: CinemaColors.steelGray,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  movie['title'] ?? 'Unknown',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> data) {
    final movie = data['movie'] ?? data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (movie['posterUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  movie['posterUrl'],
                  width: 60,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 90,
                    color: CinemaColors.inkCharcoal,
                    child: const Icon(Icons.movie, color: CinemaColors.steelGray),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 90,
                color: CinemaColors.inkCharcoal,
                child: const Icon(Icons.movie, color: CinemaColors.steelGray),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['title'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: CinemaColors.steelGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowtimes(Map<String, dynamic> data) {
    final shows = data['shows'] as List<dynamic>? ?? [];
    if (shows.isEmpty) return const Text('No showtimes available.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shows
          .map<Widget>(
            (s) {
              String timeStr = s['time'] ?? '';
              if (s['startTime'] != null) {
                try {
                  timeStr = DateTime.parse(s['startTime']).toLocal().toString().substring(11, 16);
                } catch (_) {}
              }
              final screenName = s['screen']?['theatre']?['name'] ?? s['screenName'] ?? 'Screen';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InputChip(
                  label: Text('$timeStr - $screenName'),
                  onPressed: () {},
                ),
              );
            },
          )
          .toList(),
    );
  }

  Widget _buildSeatMapPreview(Map<String, dynamic> data) {
    final seatsList = data['seats'] as List<dynamic>? ?? [];
    final availableSeats = seatsList.isNotEmpty 
        ? seatsList.where((s) => s['state'] == 'free').length 
        : (data['availableSeats'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: CinemaColors.steelGray),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seat Map Preview',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.event_seat, size: 48, color: CinemaColors.steelGray),
          Text('Available seats: $availableSeats'),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(Map<String, dynamic> data) {
    final movieTitle = data['movieTitle'] ?? data['summary']?['movieTitle'] ?? data['booking']?['show']?['movie']?['title'] ?? 'Movie';
    final seats = data['seats'] ?? data['heldSeatIds'] ?? data['summary']?['heldSeatIds'] ?? [];
    final totalCost = data['totalCost'] ?? data['summary']?['totalCost'] ?? 0;

    return Card(
      color: CinemaColors.deepCharcoal.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Text('Movie: $movieTitle'),
            Text(
              'Seats: ${(seats as List<dynamic>).join(', ')}',
            ),
            Text(
              'Total: ₹$totalCost',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (data['holdExpiresAt'] != null || data['expiresAt'] != null)
              Text(
                'Hold expires at: ${data['holdExpiresAt'] ?? data['expiresAt']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: CinemaColors.warmAmber),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentResult(Map<String, dynamic> data) {
    final success = data['paymentId'] != null || data['status'] == 'success';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success
            ? CinemaColors.successGreen.withValues(alpha: 0.1)
            : CinemaColors.neonRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: success ? CinemaColors.successGreen : CinemaColors.neonRed),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? CinemaColors.successGreen : CinemaColors.neonRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data['message'] ??
                  (success ? 'Payment successful' : 'Payment failed'),
            ),
          ),
        ],
      ),
    );
  }
}
