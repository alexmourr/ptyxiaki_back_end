import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'quiz_screen.dart';
import 'result_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final String token;
  final int sessionId;
  final int participantId;
  final String nickname;

  const LeaderboardScreen({
    super.key,
    required this.token,
    required this.sessionId,
    required this.participantId,
    required this.nickname,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _api = ApiService();
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  bool _isLoading = true;
  List<dynamic> _scores = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPusher();
    _fetch();
  }

  Future<void> _initPusher() async {
    try {
      await pusher.init(
        apiKey: '1792ebe2b3506a9784ec',
        cluster: 'eu',
        onEvent: _onEvent,
        onError: (m, c, e) => {},
        onConnectionStateChange: (cur, prev) => {},
      );
      await pusher.connect();
      await pusher.subscribe(channelName: 'session.quiz.${widget.sessionId}');
    } catch (_) {}
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final s = await _api.getLeaderboard(widget.sessionId, widget.token);
      if (!mounted) return;
      setState(() {
        _scores = s;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not fetch scores.';
        _isLoading = false;
      });
    }
  }

  void _onEvent(PusherEvent e) {
    if (!mounted) return;
    if (e.eventName == 'QuestionPushed') {
      final data = jsonDecode(e.data) as Map<String, dynamic>;
      final question = data['question'];
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
    } else if (e.eventName == 'QuizEnded') {
      final data = jsonDecode(e.data) as Map<String, dynamic>;
      final scores = data['scores'] as List<dynamic>;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(scores: scores)),
        (route) => false,
      );
    } else if (e.eventName == 'ScoreUpdated') {
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final podium = _scores
        .take(3)
        .map<Map<String, dynamic>>(
          (p) => {
            'nickname': p['nickname'],
            'score': p['score'] ?? p['correct_answers'] ?? 0,
          },
        )
        .toList();

    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.teal, AppTheme.indigo],
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Live Leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (_scores.length >= 2) Podium(top3: podium),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _scores.length,
                        itemBuilder: (context, i) {
                          final p = _scores[i];
                          final rank = i + 1;
                          final isMe = (p['nickname'] == widget.nickname);
                          final score = p['score'] ?? p['correct_answers'] ?? 0;
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: isMe
                                ? Colors.white
                                : Colors.white.withOpacity(.95),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: rank == 1
                                    ? Colors.amber
                                    : AppTheme.deepIndigo,
                                child: Text(
                                  '$rank',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                p['nickname'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: Text(
                                'Score: $score',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Waiting for the next question…',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
