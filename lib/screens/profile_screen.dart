import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../ui/theme.dart'; // Assuming AppTheme.deepIndigo and AppTheme.purple are here
import 'login_screen.dart';

// --- Data Model (From previous improvement) ---
class Profile {
  final String name;
  final String email;
  final DateTime joinedDate;
  final String role;
  final int totalPoints;
  final int completedQuizzes;
  final int completedChallenges;

  Profile({
    required this.name,
    required this.email,
    required this.joinedDate,
    required this.role,
    required this.totalPoints,
    required this.completedQuizzes,
    required this.completedChallenges,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] ?? 'Student',
      email: json['email'] ?? 'No Email',
      joinedDate: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      role: json['role'] ?? 'Student',
      totalPoints: json['total_points'] ?? 0,
      completedQuizzes: json['completed_quizzes'] ?? 0,
      completedChallenges: json['completed_challenges'] ?? 0,
    );
  }
}

// --- Widget ---
class ProfileScreen extends StatefulWidget {
  final String token;
  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Profile> _loadProfile() async {
    try {
      final data = await _api.getProfile(widget.token);
      if (data == null) {
        throw Exception('Failed to load profile data.');
      }
      return Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      throw Exception('Could not fetch profile. Please try again.');
    }
  }

  Future<void> _logout() async {
    try {
      await _api.logout(widget.token);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use a dark background color for the whole scaffold
    return Scaffold(
      backgroundColor:
          AppTheme.deepIndigo, // Or your app's main dark background
      body: FutureBuilder<Profile>(
        future: _profileFuture,
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
          final profile = snapshot.data!;
          return _buildProfileView(context, profile);
        },
      ),
    );
  }

  // --- UI Builder Widgets ---

  /// Main Profile UI (Sliver-based)
  Widget _buildProfileView(BuildContext context, Profile profile) {
    // This is the new layout.
    // CustomScrollView allows mixing scrolling app bars (Slivers)
    // with normal lists of widgets.
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // This is the new collapsing App Bar
        SliverAppBar(
          expandedHeight: 280.0,
          pinned: true,
          stretch: true,
          backgroundColor: AppTheme.deepIndigo, // Base color
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(context, profile),
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
          ),
        ),
        // This is the list of content *below* the app bar
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 24),
            _buildStatsCard(context, profile),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Account Details'),
            const SizedBox(height: 12),
            _buildDetailsCard(context, profile),
            const SizedBox(height: 30),
            _buildLogoutButton(context),
            const SizedBox(height: 40),
          ]),
        ),
      ],
    );
  }

  /// The content for the collapsing header
  Widget _buildHeader(BuildContext context, Profile profile) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.deepIndigo, AppTheme.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20), // Top padding for status bar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 55,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Card for Statistics (Points, Quizzes, Challenges)
  Widget _buildStatsCard(BuildContext context, Profile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      // If you have a custom GlassCard, you can use it here.
      // Otherwise, a styled Card works well.
      child: Card(
        color: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(
                icon: Icons.star_rounded,
                label: 'Points',
                value: '${profile.totalPoints}',
                color: Colors.amberAccent,
              ),
              _statItem(
                icon: Icons.quiz_rounded,
                label: 'Quizzes',
                value: '${profile.completedQuizzes}',
                color: Colors.lightBlueAccent,
              ),
              _statItem(
                icon: Icons.extension_rounded,
                label: 'Challenges',
                value: '${profile.completedChallenges}',
                color: Colors.pinkAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A simple text header for a section
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Card for user details (Email, Joined Date, Role)
  Widget _buildDetailsCard(BuildContext context, Profile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        // clipBehavior removes the inner ListTile's default margin
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _detailTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email',
              value: profile.email,
            ),
            const Divider(color: Colors.white12, height: 1),
            _detailTile(
              icon: Icons.calendar_today_outlined,
              title: 'Joined',
              value: DateFormat.yMMMMd().format(profile.joinedDate),
            ),
            const Divider(color: Colors.white12, height: 1),
            _detailTile(
              icon: Icons.verified_user_outlined,
              title: 'Role',
              value: profile.role,
            ),
          ],
        ),
      ),
    );
  }

  /// The final logout button
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.shade400.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.redAccent.shade100,
        ),
      ),
    );
  }

  /// Error state widget (with retry)
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
              'Failed to Load Profile',
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
                setState(() {
                  _profileFuture = _loadProfile();
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

  // --- Helper Widgets (Slightly restyled) ---

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30, // Made slightly larger
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 28), // Made slightly larger
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18, // Made slightly larger
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String title,
    required String? value,
  }) {
    return ListTile(
      // Use theme-aware colors for icons
      leading: Icon(icon, color: Colors.white.withOpacity(0.8)),
      title: Text(title),
      subtitle: Text(value ?? '—'),
      // Let the Card's theme handle the text styling
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      subtitleTextStyle: const TextStyle(color: Colors.white70, fontSize: 14),
    );
  }
}
