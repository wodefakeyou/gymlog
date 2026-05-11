import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class RestTimer extends StatefulWidget {
  final int defaultSeconds;
  const RestTimer({super.key, this.defaultSeconds = 90});

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer>
    with SingleTickerProviderStateMixin {
  late int _total;
  int _remaining = 0;
  Timer? _timer;
  bool _running = false;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _total = widget.defaultSeconds;
    _remaining = _total;
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _running = false;
          t.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _total;
      _running = false;
    });
  }

  void _adjust(int delta) {
    setState(() {
      _total = (_total + delta).clamp(15, 600);
      if (!_running) _remaining = _total;
    });
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? _remaining / _total : 0.0;
    final finished = _remaining == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _running
              ? AppTheme.primary.withOpacity(0.4)
              : AppTheme.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('组间休息',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 0.8)),
              Row(
                children: [
                  _AdjBtn(label: '-15s', onTap: () => _adjust(-15)),
                  const SizedBox(width: 6),
                  _AdjBtn(label: '+15s', onTap: () => _adjust(15)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(
                    finished ? AppTheme.green : AppTheme.primary,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  return Text(
                    finished ? '完成！' : _fmt(_remaining),
                    style: TextStyle(
                      color: finished
                          ? AppTheme.green
                          : Color.lerp(AppTheme.textPrimary,
                              AppTheme.primary, _running ? _pulseCtrl.value * 0.3 : 0)!,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_running && !finished)
                _TimerBtn(
                  label: '开始',
                  icon: Icons.play_arrow_rounded,
                  color: AppTheme.primary,
                  onTap: _start,
                ),
              if (_running)
                _TimerBtn(
                  label: '暂停',
                  icon: Icons.pause_rounded,
                  color: AppTheme.amber,
                  onTap: _pause,
                ),
              const SizedBox(width: 12),
              _TimerBtn(
                label: '重置',
                icon: Icons.refresh_rounded,
                color: AppTheme.textSecondary,
                onTap: _reset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AdjBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _TimerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimerBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
