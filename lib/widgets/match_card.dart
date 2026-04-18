import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../models/sport.dart';
import '../theme/app_theme.dart';
import 'odds_widget.dart';

class MatchCard extends StatefulWidget {
  final Match match;
  final VoidCallback? onTap;
  final bool selectable;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.selectable = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatKickoff(Match m) {
    final d = m.timeToKickoff;
    if (d.inHours < 24) {
      final h = d.inHours;
      final mm = d.inMinutes % 60;
      if (h > 0) return 'in ${h}h ${mm}m';
      return 'in ${d.inMinutes}m';
    }
    return DateFormat('MMM d, HH:mm').format(m.commenceTime);
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isLive = match.isLive;

    return Card(
      child: InkWell(
        onTap: widget.selectable
            ? widget.onSelectionToggle
            : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  if (widget.selectable)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: widget.isSelected,
                          onChanged: (_) => widget.onSelectionToggle?.call(),
                          activeColor: AppTheme.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  Text(match.sport.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    match.league,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isLive
                        ? Container(
                            key: const ValueKey('live'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            _formatKickoff(match),
                            key: const ValueKey('countdown'),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.home,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    'vs',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      match.away,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OddsWidget(odds: match.h2h, hasDraw: match.sport.hasDraw),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchCardSkeleton extends StatefulWidget {
  const MatchCardSkeleton({super.key});

  @override
  State<MatchCardSkeleton> createState() => _MatchCardSkeletonState();
}

class _MatchCardSkeletonState extends State<MatchCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final color = Colors.grey[800]!.withValues(alpha: _animation.value);
        Widget bar(double w, double h) => Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            );
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    bar(120, 14),
                    const Spacer(),
                    bar(60, 14),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Center(child: bar(80, 14))),
                    bar(20, 12),
                    Expanded(child: Center(child: bar(80, 14))),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: bar(double.infinity, 36)),
                    const SizedBox(width: 8),
                    Expanded(child: bar(double.infinity, 36)),
                    const SizedBox(width: 8),
                    Expanded(child: bar(double.infinity, 36)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
