import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'waiting_room_screen.dart';

class JoinScreen extends StatefulWidget {
  final String token;
  const JoinScreen({super.key, required this.token});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final ApiService _api = ApiService();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _join() async {
    FocusScope.of(context).unfocus();
    if (codeController.text.isEmpty || nameController.text.isEmpty) {
      setState(() => _error = 'Name and Join Code cannot be empty.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final data = await _api.joinSession(
      code: codeController.text.trim().toUpperCase(),
      nickname: nameController.text.trim(),
      token: widget.token,
    );

    if (!mounted) return;
    if (data != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            token: widget.token,
            sessionId: data['session_id'],
            participantId: data['participant_id'],
            nickname: nameController.text.trim(),
          ),
        ),
      );
    } else {
      setState(() {
        _error = 'Invalid join code or error joining session.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GradientBackground(
        colors: const [AppTheme.purple, AppTheme.indigo],
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '🚀 Join a Live Quiz',
                      style: theme.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ask your teacher for the code',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Your Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Join Code',
                        suffixIcon: Icon(Icons.qr_code_2_rounded),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _loading ? 'Joining…' : 'Join Now',
                      icon: Icons.play_circle_fill_rounded,
                      onPressed: _loading ? null : _join,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
