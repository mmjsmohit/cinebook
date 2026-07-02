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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Do you want to confirm the booking for ${data['movieTitle']}? Total: \$${data['totalPrice']}',
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
          ChatBloc(apiClient: ctx.read<ApiClient>(), controller: _controller)..add(ChatFetchThreads()),
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
                  )
                ],
              ),
              drawer: Drawer(
                child: SafeArea(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Past Threads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      if (state.isLoadingThreads)
                        const CircularProgressIndicator(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.threads.length,
                          itemBuilder: (context, index) {
                            final thread = state.threads[index];
                            return ListTile(
                              title: Text('Thread ${thread['id'].toString().substring(0, 8)}'),
                              subtitle: Text(thread['createdAt'].toString().substring(0, 10)),
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
                  if (state.bookingContext.containsKey('holdToken') || state.bookingContext.containsKey('heldSeatIds'))
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.amber.shade100,
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have seats on hold. Please confirm booking before the hold expires.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
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
                      onSendMessage: (msg) => bloc.add(ChatSendMessage(msg.text)),
                      onCancelGenerating: () => bloc.add(ChatCancelMessage()),
                      loadingConfig: LoadingConfig(isLoading: state.isLoading),
                      enableMarkdownStreaming: true,
                      streamingWordByWord: true,
                      streamingDuration: const Duration(milliseconds: 30),
                      resultRenderers: {
                        'a2ui': (ctx, data) {
                          return A2UiForm(
                            data: data,
                            onSubmit: (values) {
                              bloc.add(ChatSendMessage(jsonEncode({
                                'event': 'booking_preferences_submitted',
                                'data': values,
                              })));
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
                                onPressed: () =>
                                    _showConfirmationDialog(context, bloc, data),
                                child: const Text('Confirm Booking'),
                              ),
                            ],
                          );
                        },
                        'paymentResult': (ctx, data) => _buildPaymentResult(data),
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
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[800],
                              child: const Icon(Icons.movie, color: Colors.white54),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, color: Colors.white54),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  movie['title'] ?? 'Unknown',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (data['posterUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  data['posterUrl'],
                  width: 60,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 90,
                    color: Colors.grey[800],
                    child: const Icon(Icons.movie, color: Colors.white54),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 90,
                color: Colors.grey[800],
                child: const Icon(Icons.movie, color: Colors.white54),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    final showtimes = data['showtimes'] as List<dynamic>? ?? [];
    if (showtimes.isEmpty) return const Text('No showtimes available.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: showtimes
          .map<Widget>(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InputChip(
                label: Text('${s['time']} - ${s['screenName'] ?? 'Screen'}'),
                onPressed: () {},
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSeatMapPreview(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seat Map Preview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.event_seat, size: 48, color: Colors.grey),
          Text('Available seats: ${data['availableSeats'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(Map<String, dynamic> data) {
    return Card(
      color: Colors.deepPurple.withOpacity(0.1),
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
            Text('Movie: ${data['movieTitle']}'),
            Text(
              'Seats: ${(data['seats'] as List<dynamic>? ?? []).join(', ')}',
            ),
            Text(
              'Total: \$${data['totalPrice']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (data['holdExpiresAt'] != null)
              Text(
                'Hold expires at: ${data['holdExpiresAt']}',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentResult(Map<String, dynamic> data) {
    final success = data['status'] == 'success';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: success ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
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
