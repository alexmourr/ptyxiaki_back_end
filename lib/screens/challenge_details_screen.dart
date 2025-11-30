// lib/screens/challenge_details_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'attempt_screen.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final String token;
  final int assignmentId;
  final String challengeTitle;

  const ChallengeDetailsScreen({
    super.key,
    required this.token,
    required this.assignmentId,
    required this.challengeTitle,
  });

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  final ApiService _api = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getAssignmentQuizzes(widget.assignmentId, widget.token);
  }

  int _safeInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  String _safeString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  Future<void> _start(int quizId) async {
    if (quizId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid quiz ID from server')),
      );
      return;
    }

    try {
      final res = await _api.startAttempt(
        widget.assignmentId,
        quizId,
        widget.token,
      );

      // attempt_id might be int, string, or missing
      final attemptId = _safeInt(res['attempt_id'], fallback: 0);

      if (attemptId <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start attempt (no ID)')),
        );
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttemptScreen(
            token: widget.token,
            assignmentId: widget.assignmentId,
            attemptId: attemptId,
            quizId: quizId,
            challengeTitle: widget.challengeTitle,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error starting attempt')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.indigo, AppTheme.deepIndigo],
        child: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Failed to load quizzes',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final items = snapshot.data ?? const <Map<String, dynamic>>[];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.challengeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text(
                                'No quizzes for this challenge yet.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final it = items[i];

                                final status = _safeString(
                                  it['status'],
                                  fallback: 'pending',
                                );
                                final title = _safeString(
                                  it['title'],
                                  fallback: 'Quiz',
                                );
                                final score = _safeInt(it['last_score']);
                                final quizId = _safeInt(
                                  it['quiz_id'],
                                  fallback: 0,
                                );
                                final pos = _safeInt(
                                  it['position'],
                                  fallback: i + 1,
                                );

                                final isCompleted = status == 'completed';
                                final subtitleText = isCompleted
                                    ? 'Completed • Score: $score'
                                    : (status == 'in_progress'
                                          ? 'In progress'
                                          : 'Pending');

                                return Card(
                                  color: Colors.white.withOpacity(.09),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.white10,
                                      child: Text(
                                        '$pos',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      subtitleText,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    trailing: Icon(
                                      isCompleted
                                          ? Icons.check_circle
                                          : Icons.play_circle_fill_rounded,
                                      color: isCompleted
                                          ? Colors.greenAccent
                                          : Colors.amberAccent,
                                    ),
                                    onTap: isCompleted
                                        ? null
                                        : () => _start(quizId),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
