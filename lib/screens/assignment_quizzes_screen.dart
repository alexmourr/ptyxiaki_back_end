import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'quiz_attempt_screen.dart';

class AssignmentQuizzesScreen extends StatefulWidget {
  final String token;
  final int assignmentId;
  final String challengeTitle;

  const AssignmentQuizzesScreen({
    super.key,
    required this.token,
    required this.assignmentId,
    required this.challengeTitle,
  });

  @override
  State<AssignmentQuizzesScreen> createState() =>
      _AssignmentQuizzesScreenState();
}

class _AssignmentQuizzesScreenState extends State<AssignmentQuizzesScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  int safeInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final n = int.tryParse(v.trim());
      if (n != null) return n;
    }
    return fallback;
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getAssignmentQuizzes(
        widget.assignmentId,
        widget.token,
      );
      setState(() {
        _quizzes = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load quizzes.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challengeTitle),
        backgroundColor: AppTheme.deepIndigo,
        elevation: 0,
      ),
      body: GradientBackground(
        colors: const [AppTheme.indigo, AppTheme.deepIndigo],
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadQuizzes,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _quizzes.isEmpty
                  ? const Center(
                      child: Text(
                        'No quizzes linked to this challenge yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _quizzes.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final q = _quizzes[index];

                        final quizId = safeInt(q['id']);
                        if (quizId == 0) {
                          debugPrint('Quiz row with invalid id: $q');
                          return const SizedBox.shrink();
                        }

                        final title = (q['title'] ?? 'Untitled quiz')
                            .toString();
                        final position = safeInt(q['position'] ?? (index + 1));

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizAttemptScreen(
                                  token: widget.token,
                                  assignmentId: widget.assignmentId,
                                  quizId: quizId,
                                  quizTitle: title,
                                  quizIndex: position,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white10,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.purpleAccent
                                        .withOpacity(0.25),
                                    child: Text(
                                      '#$position',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tap to start this quiz',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white60,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
