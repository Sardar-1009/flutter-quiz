import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'viewmodels/quiz_viewmodel.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/quiz_screen.dart';
import 'views/screens/result_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => QuizViewModel(),
      child: const FlutterQuizApp(),
    ),
  );
}

class FlutterQuizApp extends StatelessWidget {
  const FlutterQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Quiz — Sardar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _RootNavigator(),
    );
  }
}

/// Root navigator that switches between screens based on ViewModel state.
/// No business logic here — pure state-to-widget mapping.
class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizViewModel>(
      builder: (context, vm, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildScreen(vm),
        );
      },
    );
  }

  Widget _buildScreen(QuizViewModel vm) {
    switch (vm.state) {
      case QuizState.inProgress:
        return const QuizScreen(key: ValueKey('quiz'));
      case QuizState.finished:
        return const ResultScreen(key: ValueKey('result'));
      case QuizState.loading:
        return const _LoadingScreen(key: ValueKey('loading'));
      case QuizState.error:
        return _ErrorScreen(
          key: const ValueKey('error'),
          message: vm.errorMessage,
          onRetry: () => vm.startQuiz(topic: vm.selectedTopic),
          onHome: vm.resetToHome,
        );
      default:
        return const HomeScreen(key: ValueKey('home'));
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 20),
            Text(
              'Загружаем вопросы...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const _ErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.error, size: 56),
              const SizedBox(height: 16),
              Text(
                'Что-то пошло не так',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Попробовать снова'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onHome,
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
