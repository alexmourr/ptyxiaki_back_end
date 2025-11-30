import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'quiz_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String token;
  final int sessionId;
  final int participantId;
  final String nickname;

  const WaitingRoomScreen({
    super.key,
    required this.token,
    required this.sessionId,
    required this.participantId,
    required this.nickname,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final pusher = PusherChannelsFlutter.getInstance();
  String _status = 'Connecting…';

  @override
  void initState() {
    super.initState();
    _initPusher();
  }

  Future<void> _initPusher() async {
    try {
      await pusher.init(
        apiKey: '1792ebe2b3506a9784ec',
        cluster: 'eu',
        onEvent: _onEvent,
        onError: (m, c, e) => setState(() => _status = 'Connection error'),
        onConnectionStateChange: (cur, prev) =>
            setState(() => _status = 'Status: $cur'),
        onSubscriptionSucceeded: (ch, data) =>
            setState(() => _status = 'Waiting for teacher…'),
      );
      await pusher.connect();
      await pusher.subscribe(channelName: 'session.quiz.${widget.sessionId}');
    } catch (_) {
      setState(() => _status = 'Failed to initialize.');
    }
  }

  void _onEvent(PusherEvent event) {
    if (event.eventName == 'QuestionPushed') {
      final data = jsonDecode(event.data) as Map<String, dynamic>;
      final question = data['question'];
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            token: widget.token,
            sessionId: widget.sessionId,
            participantId: widget.participantId,
            nickname: widget.nickname,
            question: question,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.indigo, AppTheme.teal],
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: GlassCard(
                child: Column(
                  children: [
                    Text(
                      '👋 Hi ${widget.nickname}',
                      style: theme.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You are in the lobby',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const DotsDivider(),
                    const SizedBox(height: 12),
                    Text(_status, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Session #${widget.sessionId}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
