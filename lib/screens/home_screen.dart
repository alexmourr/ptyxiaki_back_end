import 'package:flutter/material.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'join_screen.dart';
import 'scores_screen.dart';
import 'profile_screen.dart';
import 'challenges_screen.dart';

class HomeScreen extends StatelessWidget {
  final String token;
  const HomeScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(token: token)),
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_outline_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: GradientBackground(
        colors: const [AppTheme.indigo, AppTheme.deepIndigo],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                const SizedBox(height: 16),
                Text(
                  'Welcome 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'ClassQuiz Dashboard',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 26),

                // Main actions
                Expanded(
                  child: ListView(
                    children: [
                      _HomeCard(
                        icon: Icons.play_circle_fill_rounded,
                        color: Colors.amber,
                        title: 'Join Live Quiz',
                        subtitle: 'Enter a session code to compete instantly.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => JoinScreen(token: token)),
                        ),
                      ),
                      _HomeCard(
                        icon: Icons.extension_rounded,
                        color: Colors.tealAccent.shade400,
                        title: 'Challenges',
                        subtitle: 'Complete assigned tests and earn rewards.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChallengesScreen(token: token)),
                        ),
                      ),
                      _HomeCard(
                        icon: Icons.emoji_events_rounded,
                        color: Colors.lightBlueAccent,
                        title: 'My Scores',
                        subtitle: 'Track your quiz history and performance.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ScoresScreen(token: token)),
                        ),
                      ),
                      _HomeCard(
                        icon: Icons.person_rounded,
                        color: Colors.pinkAccent,
                        title: 'Profile',
                        subtitle: 'Edit your name, email, and preferences.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(token: token)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable card for Home items
class _HomeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(.25),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
