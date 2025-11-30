import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../services/api_service.dart';
import '../ui/theme.dart';
// import '../ui/widgets.dart'; // Not using GradientBackground

// --- Data Model ---
// 1. Create a data model for a Score.
class Score {
  final String quizTitle;
  final int score;
  final DateTime dateTaken;

  Score({
    required this.quizTitle,
    required this.score,
    required this.dateTaken,
  });

  // Factory constructor to parse the Map from the API
  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      quizTitle: json['quiz_title'] ?? 'Unknown Quiz',
      score: json['score'] ?? 0,
      dateTaken: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// --- Widget ---
class ScoresScreen extends StatefulWidget {
  final String token;
  const ScoresScreen({super.key, required this.token});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  final ApiService _api = ApiService();

  // 2. Use a Future to manage the state.
  late Future<List<Score>> _scoresFuture;

  @override
  void initState() {
    super.initState();
    // 3. Initialize the future in initState.
    _scoresFuture = _loadScores();
  }

  // 4. Refactor _loadScores to return the typed list and handle errors.
  Future<List<Score>> _loadScores() async {
    try {
      final List<dynamic> data = await _api.getUserScores(widget.token);

      // Parse the dynamic list into a List<Score>
      final scores = data
          .map((json) => Score.fromJson(json as Map<String, dynamic>))
          .toList();

      // 5. Sort the list to show the most recent scores first
      scores.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));

      return scores;
    } catch (e) {
      debugPrint('Error loading scores: $e');
      throw Exception('Could not fetch scores. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 6. Use the consistent dark background
      backgroundColor: AppTheme.deepIndigo,
      body: FutureBuilder<List<Score>>(
        future: _scoresFuture,
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          // --- Error State ---
          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error);
          }

          // --- Data (Success) State ---
          final scores = snapshot.data!;

          // 7. Handle the empty state
          if (scores.isEmpty) {
            return _buildEmptyState(context);
          }

          // 8. Build the main UI
          return _buildScoreList(context, scores);
        },
      ),
    );
  }

  // --- UI Builder Widgets ---

  /// The main list view, built with a CustomScrollView
  Widget _buildScoreList(BuildContext context, List<Score> scores) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 9. The dynamic, collapsing app bar
        SliverAppBar(
          title: const Text('My Scores'),
          expandedHeight: 180.0,
          pinned: true,
          stretch: true,
          elevation: 0,
          backgroundColor: AppTheme.purple, // Gradient start color
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.purple, AppTheme.deepIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    bottom: -40,
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 160,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 10. A padded list of score cards
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          // Use SliverList.separated for a cleaner list
          sliver: SliverList.separated(
            itemCount: scores.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final score = scores[index];
              return _buildScoreCard(context, score);
            },
          ),
        ),
      ],
    );
  }

  /// The new, redesigned score card
  Widget _buildScoreCard(BuildContext context, Score score) {
    return Card(
      color: Colors.white.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.lightBlueAccent.withOpacity(0.15),
          child: const Icon(Icons.quiz_rounded, color: Colors.lightBlueAccent),
        ),
        title: Text(
          score.quizTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          // 11. Format the date for a clean look
          DateFormat.yMd().add_jm().format(score.dateTaken),
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          '${score.score} pts',
          style: const TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// A user-friendly widget for when the list is empty
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Scores Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a quiz to see your scores appear here!',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// A user-friendly error widget with a retry button
  Widget _buildErrorState(BuildContext context, Object? error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 60),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Scores',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry the API call
                setState(() {
                  _scoresFuture = _loadScores();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
