import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class QuizAttemptScreen extends StatefulWidget {
  final String token;
  final int assignmentId;
  final int quizId;
  final String quizTitle;
  final int quizIndex;

  const QuizAttemptScreen({
    super.key,
    required this.token,
    required this.assignmentId,
    required this.quizId,
    required this.quizTitle,
    required this.quizIndex,
  });

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  final _api = ApiService();

  int? _attemptId;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _currentQuestion;
  bool _submitting = false;
  bool _finished = false;

  int _totalAnswered = 0;
  int? _finalCorrect;
  int? _finalTotal;
  int? _finalPoints;

  int? _selectedIndex;
  final Set<int> _selectedMulti = {};

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

  @override
  void initState() {
    super.initState();
    _startAttempt();
  }

  Future<void> _startAttempt() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await _api.startAttempt(
        widget.assignmentId,
        widget.quizId,
        widget.token,
      );

      final attemptId = safeInt(resp['attempt_id'], fallback: 0);
      if (attemptId == 0) {
        setState(() {
          _error = 'Could not start quiz attempt.';
          _loading = false;
        });
        return;
      }

      _attemptId = attemptId;
      await _loadNextQuestion();
    } catch (e) {
      setState(() {
        _error = 'Could not start quiz attempt.';
        _loading = false;
      });
    }
  }

  Future<void> _loadNextQuestion() async {
    if (_attemptId == null) return;

    setState(() {
      _loading = true;
      _currentQuestion = null;
      _selectedIndex = null;
      _selectedMulti.clear();
    });

    try {
      final resp = await _api.getNextQuestion(_attemptId!, widget.token);

      if (resp['done'] == true) {
        setState(() {
          _finished = true;
          _loading = false;
        });
        await _finishAttempt();
        return;
      }

      setState(() {
        _currentQuestion = resp;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load next question.';
        _loading = false;
      });
    }
  }

  List<String> _options() {
    final raw = _currentQuestion?['options'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      // fallback
      return [raw];
    }
    return const <String>[];
  }

  Future<void> _submitAnswer() async {
    if (_attemptId == null || _currentQuestion == null) return;

    final qId = safeInt(_currentQuestion!['id'], fallback: 0);
    if (qId == 0) return;

    final options = _options();
    if (options.isEmpty) return;

    final correctType = (_currentQuestion!['correct_type'] ?? 'single')
        .toString();
    final isMulti = correctType == 'multiple';

    if (isMulti) {
      if (_selectedMulti.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select one or more answers')),
        );
        return;
      }
    } else {
      if (_selectedIndex == null ||
          _selectedIndex! < 0 ||
          _selectedIndex! >= options.length) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Select one answer')));
        return;
      }
    }

    setState(() {
      _submitting = true;
    });

    try {
      Map<String, dynamic> resp;

      if (isMulti) {
        final selectedAnswers = _selectedMulti
            .map((i) => options[i])
            .toList(growable: false);
        resp = await _api.submitAttemptAnswer(
          attemptId: _attemptId!,
          questionId: qId,
          selectedAnswers: selectedAnswers,
          token: widget.token,
        );
      } else {
        final selectedAnswer = options[_selectedIndex!];
        resp = await _api.submitAttemptAnswer(
          attemptId: _attemptId!,
          questionId: qId,
          selectedAnswer: selectedAnswer,
          token: widget.token,
        );
      }

      final correct = resp['correct'] == true;
      final points = safeInt(resp['points'], fallback: 0);

      setState(() {
        _totalAnswered++;
      });

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    correct ? Icons.check_circle : Icons.cancel,
                    color: correct ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    correct ? 'Correct!' : 'Incorrect',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: correct ? Colors.green : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '+$points pts',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Keep going, you\'re doing great!',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      await _loadNextQuestion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not submit answer')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _finishAttempt() async {
    if (_attemptId == null) return;
    try {
      final resp = await _api.finishAttempt(_attemptId!, widget.token);
      final result = resp['result'] as Map<String, dynamic>? ?? resp;
      setState(() {
        _finalCorrect = safeInt(result['correct'], fallback: 0);
        _finalTotal = safeInt(result['total'], fallback: _totalAnswered);
        _finalPoints = safeInt(result['points'], fallback: 0);
      });
    } catch (_) {
      // ignore, we'll just show "completed"
    }
  }

  Widget _buildQuestionContent() {
    final q = _currentQuestion;
    final options = _options();
    if (q == null) return const SizedBox.shrink();

    final content = (q['content'] ?? '').toString();
    final correctType = (q['correct_type'] ?? 'single').toString();
    final isMulti = correctType == 'multiple';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // quiz title + progress
        Row(
          children: [
            Expanded(
              child: Text(
                widget.quizTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Q${_totalAnswered + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Text(
            content.isEmpty ? 'No question text.' : content,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isMulti ? 'Select one or more answers:' : 'Select one answer:',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = isMulti
                    ? _selectedMulti.contains(index)
                    : _selectedIndex == index;

                return InkWell(
                  onTap: _submitting
                      ? null
                      : () {
                          setState(() {
                            if (isMulti) {
                              if (_selectedMulti.contains(index)) {
                                _selectedMulti.remove(index);
                              } else {
                                _selectedMulti.add(index);
                              }
                            } else {
                              _selectedIndex = index;
                            }
                          });
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.tealAccent.withOpacity(0.18)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.tealAccent : Colors.white12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isMulti
                              ? (isSelected
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded)
                              : (isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded),
                          color: isSelected
                              ? Colors.tealAccent
                              : Colors.white60,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _submitting ? 'Submitting…' : 'Submit answer',
          icon: Icons.send_rounded,
          onPressed: _submitting ? null : _submitAnswer,
        ),
      ],
    );
  }

  Widget _buildFinishedView() {
    final correct = _finalCorrect ?? 0;
    final total = _finalTotal ?? _totalAnswered;
    final points = _finalPoints ?? 0;

    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            const Text(
              'Quiz completed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You answered $correct out of $total correctly.',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Total points: $points',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Back to challenge',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.deepIndigo, AppTheme.purple],
        child: SafeArea(
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
                : _finished
                ? _buildFinishedView()
                : _buildQuestionContent(),
          ),
        ),
      ),
    );
  }
}
