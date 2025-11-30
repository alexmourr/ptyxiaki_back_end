// lib/screens/quiz_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'leaderboard_screen.dart';

class QuizScreen extends StatefulWidget {
  final String token;
  final int sessionId;
  final int participantId;
  final String nickname;
  final Map<String, dynamic> question;

  const QuizScreen({
    super.key,
    required this.token,
    required this.sessionId,
    required this.participantId,
    required this.nickname,
    required this.question,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _api = ApiService();
  late Timer _timer;
  late int _remaining;
  final Set<String> _selected = {};
  bool _isSubmitting = false;
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    _remaining = (widget.question['time_limit'] ?? 30) as int;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining > 0) {
        if (mounted) setState(() => _remaining--);
      } else {
        t.cancel();
        if (mounted) setState(() => _timeUp = true);
        _gotoLeaderboard();
      }
    });
  }

  List<String> _options() {
    final raw = widget.question['options'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        return List<String>.from(
          (jsonDecode(raw) as List).map((e) => e.toString()),
        );
      } catch (_) {
        return [raw.toString()];
      }
    }
    return const <String>[];
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    _timer.cancel();
    setState(() => _isSubmitting = true);

    // NOTE: This expects your ApiService to have submitAnswers (array).
    // If you still have submitAnswer (single), let me know and I’ll switch it back.
    final resp = await _api.submitAnswers(
      sessionId: widget.sessionId,
      participantId: widget.participantId,
      questionId: widget.question['id'] as int,
      selectedAnswers: _selected.toList(),
      token: widget.token,
    );

    if (!mounted) return;

    if (resp == null || resp['error'] != null) {
      setState(() {
        _isSubmitting = false;
        if (_remaining > 0) _startTimer();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp?['error'] ?? 'Submission failed')),
      );
      return;
    }

    final correct = resp['correct'] == true;
    final msg =
        (resp['message'] as String?) ?? (correct ? 'Great!' : 'Keep going!');
    final rationale = resp['rationale'] as String?;
    final fun = resp['fun_fact'] as String?;
    final pts = resp['points'] ?? 0;
    final streak = resp['streak'] ?? 0;

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
                  '+$pts pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(msg),
            if (rationale != null && rationale.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Why', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(rationale),
            ],
            if (fun != null && fun.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Fun fact',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(fun),
            ],
            const SizedBox(height: 12),
            Text('Streak: $streak'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    _gotoLeaderboard();
  }

  void _gotoLeaderboard() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(
          token: widget.token,
          sessionId: widget.sessionId,
          participantId: widget.participantId,
          nickname: widget.nickname,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (widget.question['time_limit'] ?? 30) as int;
    final options = _options();

    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.deepIndigo, AppTheme.amber],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header: timer + title
                Row(
                  children: [
                    TimerRing(remaining: _remaining, total: total),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Question #${widget.question['id']}',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Question text
                GlassCard(
                  child: Text(
                    widget.question['content'] ?? 'No content',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Options as full-width wrapping cards
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final opt = options[index];
                        final selected = _selected.contains(opt);

                        return InkWell(
                          onTap: (_timeUp || _isSubmitting)
                              ? null
                              : () {
                                  setState(() {
                                    selected
                                        ? _selected.remove(opt)
                                        : _selected.add(opt);
                                  });
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.amber.withOpacity(.22)
                                  : Colors.grey.withOpacity(.10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: selected
                                      ? Colors.amber.shade700
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                // ✅ This Text wraps across multiple lines (no fading)
                                Expanded(
                                  child: Text(
                                    opt,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    softWrap: true,
                                    maxLines: null,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.left,
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

                const SizedBox(height: 10),
                if (_timeUp)
                  const Text(
                    'Time is up!',
                    style: TextStyle(color: Colors.white),
                  ),

                const SizedBox(height: 6),
                PrimaryButton(
                  label: _isSubmitting ? 'Submitting…' : 'Submit',
                  icon: Icons.send_rounded,
                  onPressed: (_timeUp || _isSubmitting || _selected.isEmpty)
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
