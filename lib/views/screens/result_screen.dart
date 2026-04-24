import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/quiz_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'dart:math' as math;

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _circleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );
    _progressAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    );
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _circleController.forward();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizViewModel>(
      builder: (context, vm, _) {
        final result = vm.result;
        if (result == null) return const SizedBox.shrink();

        return Scaffold(
          body: Stack(
            children: [
              _buildBackground(result.percentage),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildTitle(context),
                        const SizedBox(height: 40),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildScoreCircle(
                              context, result.percentage, result.correctAnswers,
                              result.totalQuestions),
                        ),
                        const SizedBox(height: 32),
                        _buildResultCard(context, result.interpretation,
                            result.interpretationDetail),
                        const SizedBox(height: 28),
                        _buildDetailStats(context, result.correctAnswers,
                            result.totalQuestions, result.percentage),
                        const Spacer(),
                        _buildButtons(context, vm),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(double percentage) {
    Color glowColor;
    if (percentage >= 90) {
      glowColor = AppTheme.success;
    } else if (percentage >= 70) {
      glowColor = AppTheme.secondary;
    } else if (percentage >= 50) {
      glowColor = AppTheme.primary;
    } else {
      glowColor = AppTheme.accent;
    }

    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glowColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events_rounded,
            color: AppTheme.accent, size: 26),
        const SizedBox(width: 10),
        Text(
          'Результаты теста',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildScoreCircle(
      BuildContext context, double percentage, int correct, int total) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animatedPercent = _progressAnimation.value * percentage / 100;
        return SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _CircleProgressPainter(
              progress: animatedPercent,
              percentage: percentage,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percentage),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    builder: (context, val, _) => Text(
                      '${val.toInt()}%',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: _getScoreColor(percentage),
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Text(
                    '$correct / $total',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard(
      BuildContext context, String interpretation, String detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            interpretation,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStats(
      BuildContext context, int correct, int total, double percentage) {
    return Row(
      children: [
        _MiniStatCard(
          label: 'Правильных',
          value: correct.toString(),
          color: AppTheme.success,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 12),
        _MiniStatCard(
          label: 'Неверных',
          value: (total - correct).toString(),
          color: AppTheme.error,
          icon: Icons.cancel_rounded,
        ),
        const SizedBox(width: 12),
        _MiniStatCard(
          label: 'Всего',
          value: total.toString(),
          color: AppTheme.primary,
          icon: Icons.quiz_rounded,
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, QuizViewModel vm) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => vm.startQuiz(topic: vm.selectedTopic),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay_rounded, size: 20),
                SizedBox(width: 8),
                Text('Пройти ещё раз'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => vm.resetToHome(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_rounded, size: 20),
                SizedBox(width: 8),
                Text('На главную'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return AppTheme.success;
    if (percentage >= 70) return AppTheme.secondary;
    if (percentage >= 50) return AppTheme.primary;
    return AppTheme.accent;
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final double percentage;

  _CircleProgressPainter({required this.progress, required this.percentage});

  Color get _color {
    if (percentage >= 90) return AppTheme.success;
    if (percentage >= 70) return AppTheme.secondary;
    if (percentage >= 50) return AppTheme.primary;
    return AppTheme.accent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.surfaceLight
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = _color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = _color.withOpacity(0.3)
      ..strokeWidth = strokeWidth + 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress || old.percentage != percentage;
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
