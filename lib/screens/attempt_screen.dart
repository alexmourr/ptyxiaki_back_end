// lib/screens/attempt_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class AttemptScreen extends StatefulWidget {
  final String token;
  final int assignmentId;
  final int attemptId;
  final int quizId;
  final String challengeTitle;

  const AttemptScreen({
    super.key,
    required this.token,
    required this.assignmentId,
    required this.attemptId,
    required this.quizId,
    required this.challengeTitle,
  });

  @override
  State<AttemptScreen> createState() => _AttemptScreenState();
}

class _AttemptScreenState extends State<AttemptScreen> {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _question;
  int _remaining = 0;
  int _total = 0;
  Timer? _timer;
  bool _submitting = false;
  final Set<String> _selected = {};

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

  bool _safeBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    if (v is num) return v != 0;
    return fallback;
  }

  String _safeString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNext() async {
    _timer?.cancel();
    setState(() {
      _question = null;
      _selected.clear();
    });

    try {
      final res = await _api.getNextQuestion(widget.attemptId, widget.token);
      if (!mounted) return;

      // Handle both shapes:
      // 1) { finished: true, ... }
      // 2) { question: {...}, finished: false }
      // 3) directly a question object
      if (_safeBool(res['finished']) || _safeBool(res['done'])) {
        final fin = await _api.finishAttempt(widget.attemptId, widget.token);
        if (!mounted) return;
        await _showSummary(fin);
        return;
      }

      Map<String, dynamic>? q;
      if (res['question'] is Map<String, dynamic>) {
        q = res['question'] as Map<String, dynamic>;
      } else {
        q = res.cast<String, dynamic>();
      }

      // If still null → no question, consider finished
      if (q == null || q.isEmpty) {
        final fin = await _api.finishAttempt(widget.attemptId, widget.token);
        if (!mounted) return;
        await _showSummary(fin);
        return;
      }

      final tl = _safeInt(q['time_limit'], fallback: 30);
      setState(() {
        _question = q;
        _total = tl > 0 ? tl : 30;
        _remaining = _total;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (!mounted) return;
        if (_remaining > 0) {
          setState(() => _remaining--);
        } else {
          t.cancel();
          await _autoSubmitTimeout();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not load question')));
    }
  }

  List<String> _options(Map<String, dynamic> q) {
    final raw = q['options'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return const <String>[];
  }

  Future<void> _autoSubmitTimeout() async {
    if (_submitting) return;
    await _submit(inTimeout: true);
  }

  Future<void> _submit({bool inTimeout = false}) async {
    if (_question == null || _submitting) return;

    final q = _question!;
    final questionId = _safeInt(q['id'], fallback: 0);
    if (questionId <= 0) return;

    final opts = _options(q);
    final isMulti = _safeBool(q['is_multi']);

    final elapsedMs = ((_total - _remaining).clamp(0, _total)) * 1000;

    setState(() => _submitting = true);
    _timer?.cancel();

    try {
      final selectedSingle = !isMulti && _selected.isNotEmpty
          ? _selected.first
          : null;
      final selectedMulti = isMulti ? _selected.toList() : null;

      final res = await _api.submitAttemptAnswer(
        attemptId: widget.attemptId,
        questionId: questionId,
        selectedAnswer: selectedSingle,
        selectedAnswers: selectedMulti,
        answerTimeMs: elapsedMs,
        token: widget.token,
      );

      final correct = _safeBool(res['is_correct']) || _safeBool(res['correct']);
      final pts = _safeInt(res['points']);

      if (!mounted) return;

      if (!inTimeout) {
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
      }

      await _loadNext();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not submit answer')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _toggle(String opt, bool isMulti) {
    if (_submitting) return;
    setState(() {
      if (isMulti) {
        _selected.contains(opt) ? _selected.remove(opt) : _selected.add(opt);
      } else {
        _selected
          ..clear()
          ..add(opt);
      }
    });
  }

  Future<void> _showSummary(Map<String, dynamic> fin) async {
    final totalPts = _safeInt(fin['total_points'] ?? fin['points']);
    final correct = _safeInt(fin['correct_count'] ?? fin['correct']);
    final totalQ = _safeInt(fin['total_questions'] ?? fin['total']);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Challenge Quiz Completed'),
        content: Text('Score: $totalPts\nCorrect: $correct / $totalQ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context); // back to details
  }

  @override
  Widget build(BuildContext context) {
    final q = _question;
    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.deepIndigo, AppTheme.amber],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: q == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _buildQuestion(context, q),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, Map<String, dynamic> q) {
    final theme = Theme.of(context);
    final isMulti = _safeBool(q['is_multi']);
    final opts = _options(q);
    final content = _safeString(q['content'], fallback: 'No content');

    return Column(
      children: [
        // Header: timer + title
        Row(
          children: [
            TimerRing(remaining: _remaining, total: _total == 0 ? 1 : _total),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.challengeTitle} • Q#${_safeInt(q['id'], fallback: 0)}',
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
            content,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Options
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: ListView.separated(
              itemCount: opts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = opts[i];
                final selected = _selected.contains(o);
                return InkWell(
                  onTap: _submitting ? null : () => _toggle(o, isMulti),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
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
                        color: selected ? Colors.amber : Colors.grey.shade300,
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
                          color: selected ? Colors.amber.shade700 : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            o,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            softWrap: true,
                            maxLines: null,
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
          label: _submitting ? 'Submitting…' : 'Submit',
          icon: Icons.send_rounded,
          onPressed: _submitting || _selected.isEmpty ? null : () => _submit(),
        ),
      ],
    );
  }
}
