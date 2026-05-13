import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/quiz_viewmodel.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/onboarding_screen.dart';
import 'views/screens/quiz_screen.dart';
import 'views/screens/register_screen.dart';
import 'views/screens/result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Инициализация локальных уведомлений
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => QuizViewModel()),
      ],
      child: const FlutterQuizApp(),
    ),
  );
}

class FlutterQuizApp extends StatelessWidget {
  const FlutterQuizApp({super.key});

  // Single shared AnalyticsService used for the navigator observer.
  static final _analyticsService = AnalyticsService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Quiz — Sardar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Automatically logs screen_view events on every navigation change.
      navigatorObservers: [_analyticsService.observer],
      home: const _AppBootstrap(),
    );
  }
}

/// Top-level bootstrap: checks auth → onboarding → home.
class _AppBootstrap extends StatelessWidget {
  const _AppBootstrap();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, _) {
        // Still initializing
        if (auth.state == AuthState.idle) {
          return const _SplashScreen();
        }
        // Not authenticated → show auth screens
        if (auth.state != AuthState.authenticated) {
          return const _AuthNavigator();
        }
        // Authenticated — new user goes to onboarding, returning user to home
        if (auth.isNewUser) {
          return _OnboardingGate(
            onComplete: () => auth.clearNewUserFlag(),
          );
        }
        return const _RootNavigator();
      },
    );
  }
}

/// Splash screen while app initializes.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

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
              'Загрузка...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Switches between login and register screens.
class _AuthNavigator extends StatefulWidget {
  const _AuthNavigator();

  @override
  State<_AuthNavigator> createState() => _AuthNavigatorState();
}

class _AuthNavigatorState extends State<_AuthNavigator> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
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
      child: _showLogin
          ? LoginScreen(
              key: const ValueKey('login'),
              onSwitchToRegister: () => setState(() => _showLogin = false),
            )
          : RegisterScreen(
              key: const ValueKey('register'),
              onSwitchToLogin: () => setState(() => _showLogin = true),
            ),
    );
  }
}

/// Shows onboarding for new users, then transitions to home.
class _OnboardingGate extends StatefulWidget {
  final VoidCallback onComplete;
  const _OnboardingGate({required this.onComplete});

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final service = OnboardingService();
    final done = await service.isOnboardingComplete();
    if (done && mounted) {
      // Already completed onboarding before — skip
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone) {
      return const _RootNavigator();
    }
    return OnboardingScreen(
      onComplete: () {
        setState(() => _onboardingDone = true);
        widget.onComplete();
      },
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
          onHome: () => vm.resetToHome(), // async — must wrap in lambda
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
