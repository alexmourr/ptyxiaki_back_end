import 'package:flutter/material.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class ResultScreen extends StatelessWidget {
  final List<dynamic> scores;
  const ResultScreen({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final sorted = [...scores];
    sorted.sort((a, b) {
      final sa = (a['score'] as num?) ?? 0;
      final sb = (b['score'] as num?) ?? 0;
      return sb.compareTo(sa);
    });
    final podium = sorted
        .take(3)
        .map<Map<String, dynamic>>(
          (p) => {'nickname': p['nickname'], 'score': p['score'] ?? 0},
        )
        .toList();

    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.purple, AppTheme.deepIndigo],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '🏆 Final Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (podium.isNotEmpty) Podium(top3: podium),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final p = sorted[index];
                      final rank = index + 1;
                      final score = p['score'] ?? 0;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: rank == 1
                                ? Colors.amber
                                : AppTheme.indigo,
                            child: Text(
                              '$rank',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            p['nickname'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Text(
                            'Score: $score',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Done'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
