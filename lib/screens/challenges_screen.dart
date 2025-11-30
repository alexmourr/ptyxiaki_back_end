import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'assignment_quizzes_screen.dart';

class ChallengesScreen extends StatefulWidget {
  final String token;
  const ChallengesScreen({super.key, required this.token});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadChallenges();
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

  Future<void> _loadChallenges() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getAssignedChallenges(widget.token);
      setState(() {
        _challenges = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load challenges.';
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'in_progress':
        return Colors.orangeAccent;
      default:
        return Colors.blueGrey.shade200;
    }
  }

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        backgroundColor: AppTheme.deepIndigo,
        elevation: 0,
      ),
      body: GradientBackground(
        colors: const [AppTheme.indigo, AppTheme.deepIndigo],
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadChallenges,
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
                  : _challenges.isEmpty
                  ? const Center(
                      child: Text(
                        'No challenges assigned yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _challenges.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final ch = _challenges[index];

                        final assignmentId = safeInt(ch['assignment_id']);
                        if (assignmentId == 0) {
                          // Skip malformed rows safely
                          debugPrint(
                            'Challenge row with invalid assignment_id: $ch',
                          );
                          return const SizedBox.shrink();
                        }

                        final title = (ch['title'] ?? 'Untitled challenge')
                            .toString();
                        final desc = (ch['description'] ?? '').toString();
                        final status = (ch['status'] ?? 'pending').toString();
                        final completedAt = ch['completed_at']?.toString();

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AssignmentQuizzesScreen(
                                  token: widget.token,
                                  assignmentId: assignmentId,
                                  challengeTitle: title,
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
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            if (desc.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                desc,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            status,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(status),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (completedAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Completed at: $completedAt',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
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
