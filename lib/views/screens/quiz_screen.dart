import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/quiz_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../widgets/animated_option_button.dart';
import '../widgets/progress_header.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<QuizViewModel>(
        builder: (context, vm, _) {
          final question = vm.currentQuestion;
          if (question == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          return Stack(
            children: [
              // Subtle background glow
              Positioned(
                top: -60,
                left: -60,
                child: Container(
                  width: 200,
                  height: 200,
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTopBar(context, vm),
                      const SizedBox(height: 24),
                      ProgressHeader(
                        current: vm.currentIndex,
                        total: vm.totalQuestions,
                        topic: question.topicLabel,
                      ),
                      const SizedBox(height: 32),
                      _buildQuestion(context, question.text),
                      const SizedBox(height: 28),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...List.generate(
                                question.options.length,
                                (i) => AnimatedOptionButton(
                                  key: ValueKey('${vm.currentIndex}_$i'),
                                  text: question.options[i],
                                  index: i,
                                  isSelected: vm.isOptionSelected(i),
                                  isCorrect: vm.isOptionCorrect(i),
                                  isWrong: vm.isOptionWrong(i),
                                  isEnabled: !vm.answerConfirmed,
                                  onTap: () => vm.selectOption(i),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBottomButton(context, vm),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, QuizViewModel vm) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showExitDialog(context, vm),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.quiz_rounded, color: AppTheme.primary, size: 16),
              SizedBox(width: 6),
              Text(
                'Flutter Quiz',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w500,
              fontSize: 17,
            ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, QuizViewModel vm) {
    if (!vm.answerConfirmed) {
      // Show "Confirm" button when an option is selected
      return AnimatedOpacity(
        opacity: vm.selectedOptionIndex != null ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
                vm.selectedOptionIndex != null ? () => vm.confirmAnswer() : null,
            child: const Text('Подтвердить ответ'),
          ),
        ),
      );
    }

    // Show "Next" or "Results" after confirming
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => vm.nextQuestion(),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              vm.isLastQuestion ? AppTheme.secondary : AppTheme.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.isLastQuestion ? 'Результаты' : 'Следующий вопрос'),
            const SizedBox(width: 8),
            Icon(
              vm.isLastQuestion
                  ? Icons.emoji_events_rounded
                  : Icons.arrow_forward_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, QuizViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выйти из теста?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Прогресс будет потерян.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.resetToHome();
            },
            child: const Text('Выйти',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
