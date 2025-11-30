import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme.dart';

/// gradient backgrounds differ per screen
class GradientBackground extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  const GradientBackground({
    super.key,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

/// glass-like card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double blur;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// large CTA button with icon
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      onPressed: onPressed,
      label: Text(label),
    );
  }
}

/// circular timer ring
class TimerRing extends StatelessWidget {
  final int remaining;
  final int total;
  const TimerRing({super.key, required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final p = (remaining / total).clamp(0, 1).toDouble();
    return SizedBox(
      height: 70,
      width: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: p,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(.3),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.amber),
          ),
          Text(
            '$remaining',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// podium for top 3
class Podium extends StatelessWidget {
  final List<Map<String, dynamic>> top3; // [{nickname, score}]
  const Podium({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(top3.length, (i) {
        final p = top3[i];
        final h = 90 - (i * 12);
        return Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors[i],
              child: Text('${i + 1}'),
            ),
            const SizedBox(height: 6),
            Text(
              p['nickname'] ?? '—',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              height: h.toDouble(),
              width: 46,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: colors[i].withOpacity(.25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${p['score'] ?? 0}'),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// playful divider
class DotsDivider extends StatelessWidget {
  const DotsDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(40, (i) {
        return Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: i.isEven ? Colors.white24 : Colors.white10,
          ),
        );
      }),
    );
  }
}
