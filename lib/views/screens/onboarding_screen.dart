import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _pulseController;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            body: Stack(
              children: [
                // Background blobs
                _BackgroundDecoration(pulseController: _pulseController),
                // Content
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildProgressBar(vm),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _WelcomePage(
                              nameController: _nameController,
                              onChanged: vm.setName,
                            ),
                            _AgeSelectionPage(
                              selected: vm.ageRange,
                              onSelect: vm.setAgeRange,
                            ),
                            _EducationPage(
                              selected: vm.educationLevel,
                              onSelect: vm.setEducationLevel,
                            ),
                            _ExperiencePage(
                              selected: vm.programmingExperience,
                              onSelect: vm.setProgrammingExperience,
                            ),
                            _ReadyPage(name: vm.name),
                          ],
                        ),
                      ),
                      _buildBottomNav(vm),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(OnboardingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: List.generate(OnboardingViewModel.totalPages, (i) {
          final isActive = i <= vm.currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: isActive
                    ? const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      )
                    : null,
                color: isActive ? null : AppTheme.surfaceLight,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav(OnboardingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (vm.currentPage > 0)
            _NavButton(
              label: 'Назад',
              icon: Icons.arrow_back_rounded,
              isOutlined: true,
              onPressed: () {
                vm.previousPage();
                _animateToPage(vm.currentPage);
              },
            )
          else
            const SizedBox(width: 110),
          const Spacer(),
          _NavButton(
            label: vm.isLastPage ? 'Начать!' : 'Далее',
            icon: vm.isLastPage
                ? Icons.rocket_launch_rounded
                : Icons.arrow_forward_rounded,
            isOutlined: false,
            enabled: vm.canProceed,
            onPressed: () async {
              if (vm.isLastPage) {
                await vm.completeOnboarding();
                widget.onComplete();
              } else {
                vm.nextPage();
                _animateToPage(vm.currentPage);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Background decoration ─────────────────────────────────────────
class _BackgroundDecoration extends StatelessWidget {
  final AnimationController pulseController;
  const _BackgroundDecoration({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) {
        final v = pulseController.value;
        return Stack(
          children: [
            Positioned(
              top: -80 + v * 20,
              right: -60,
              child: _blob(280, AppTheme.primary, 0.18 + v * 0.07),
            ),
            Positioned(
              bottom: -60 + v * 15,
              left: -80,
              child: _blob(220, AppTheme.secondary, 0.15 + v * 0.05),
            ),
            Positioned(
              top: 300,
              left: 200,
              child: _blob(120, AppTheme.accent, 0.1 + v * 0.05),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Nav button ────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isOutlined;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.isOutlined,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppTheme.textSecondary),
        label: Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      );
    }
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: AppTheme.surfaceLight,
        ),
      ),
    );
  }
}

// ─── Reusable selection chip ───────────────────────────────────────
class _SelectionChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page header helper ────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _PageHeader({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                fontSize: 15,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// PAGE 1 — Welcome (name input)
// ══════════════════════════════════════════════════════════════════════
class _WelcomePage extends StatelessWidget {
  final TextEditingController nameController;
  final ValueChanged<String> onChanged;

  const _WelcomePage({required this.nameController, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const _PageHeader(
            emoji: '👋',
            title: 'Добро пожаловать!',
            subtitle: 'Давайте познакомимся поближе,\nчтобы настроить квиз под вас.',
          ),
          const SizedBox(height: 44),
          TextField(
            controller: nameController,
            onChanged: onChanged,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Ваше имя',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// PAGE 2 — Age range
// ══════════════════════════════════════════════════════════════════════
class _AgeSelectionPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _AgeSelectionPage({required this.selected, required this.onSelect});

  static const _options = [
    {'label': 'До 18 лет', 'emoji': '🧒', 'value': '<18'},
    {'label': '18 – 24 года', 'emoji': '🎓', 'value': '18-24'},
    {'label': '25 – 34 года', 'emoji': '💼', 'value': '25-34'},
    {'label': '35 – 44 года', 'emoji': '🏆', 'value': '35-44'},
    {'label': '45+ лет', 'emoji': '🌟', 'value': '45+'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const _PageHeader(
            emoji: '🎂',
            title: 'Сколько вам лет?',
            subtitle: 'Выберите вашу возрастную группу.',
          ),
          const SizedBox(height: 32),
          ..._options.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectionChip(
                  label: o['label']!,
                  emoji: o['emoji']!,
                  isSelected: selected == o['value'],
                  onTap: () => onSelect(o['value']!),
                ),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// PAGE 3 — Education level
// ══════════════════════════════════════════════════════════════════════
class _EducationPage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _EducationPage({required this.selected, required this.onSelect});

  static const _options = [
    {'label': 'Школьник / Студент', 'emoji': '📚', 'value': 'student'},
    {'label': 'Среднее специальное', 'emoji': '🎖️', 'value': 'college'},
    {'label': 'Бакалавриат', 'emoji': '🎓', 'value': 'bachelor'},
    {'label': 'Магистратура / PhD', 'emoji': '🔬', 'value': 'master'},
    {'label': 'Самоучка', 'emoji': '🚀', 'value': 'self-taught'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const _PageHeader(
            emoji: '🎓',
            title: 'Уровень образования',
            subtitle: 'Какой у вас уровень образования\nна данный момент?',
          ),
          const SizedBox(height: 32),
          ..._options.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectionChip(
                  label: o['label']!,
                  emoji: o['emoji']!,
                  isSelected: selected == o['value'],
                  onTap: () => onSelect(o['value']!),
                ),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// PAGE 4 — Programming experience
// ══════════════════════════════════════════════════════════════════════
class _ExperiencePage extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _ExperiencePage({required this.selected, required this.onSelect});

  static const _options = [
    {'label': 'Полный новичок', 'emoji': '🌱', 'value': 'beginner'},
    {'label': 'Немного знаю основы', 'emoji': '🌿', 'value': 'basic'},
    {'label': 'Есть пет-проекты', 'emoji': '🛠️', 'value': 'intermediate'},
    {'label': 'Работаю / работал(а)', 'emoji': '💻', 'value': 'professional'},
    {'label': 'Senior / Lead', 'emoji': '⭐', 'value': 'senior'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 50),
          const _PageHeader(
            emoji: '💻',
            title: 'Опыт в программировании',
            subtitle: 'Оцените свой уровень опыта\nв разработке.',
          ),
          const SizedBox(height: 32),
          ..._options.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectionChip(
                  label: o['label']!,
                  emoji: o['emoji']!,
                  isSelected: selected == o['value'],
                  onTap: () => onSelect(o['value']!),
                ),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// PAGE 5 — Ready to go
// ══════════════════════════════════════════════════════════════════════
class _ReadyPage extends StatelessWidget {
  final String name;
  const _ReadyPage({required this.name});

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : 'друг';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Всё готово,\n$displayName!',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Мы настроили квиз под вас.\nНажмите «Начать!», чтобы\nпроверить свои знания.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 15,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Feature highlights
          _FeatureItem(
            icon: Icons.quiz_rounded,
            color: AppTheme.primary,
            title: '20+ вопросов',
            subtitle: 'По Dart и Flutter',
          ),
          const SizedBox(height: 12),
          _FeatureItem(
            icon: Icons.category_rounded,
            color: AppTheme.secondary,
            title: '4 категории',
            subtitle: 'Widgets, архитектура и другие',
          ),
          const SizedBox(height: 12),
          _FeatureItem(
            icon: Icons.insights_rounded,
            color: AppTheme.accent,
            title: 'Подробные результаты',
            subtitle: 'Узнайте свой уровень знаний',
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
