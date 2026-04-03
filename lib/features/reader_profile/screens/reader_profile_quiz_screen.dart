import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/reader_profile_service.dart';
import '../../../core/services/reader_profile_repository.dart';
import '../../../core/services/google_books_service.dart';
import '../../../core/services/book_library_service.dart';
import '../../../core/models/reader_profile.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../core/widgets/speech_bubble.dart';
import '../cubit/reader_profile_cubit.dart';
import '../cubit/reader_profile_state.dart';

class ReaderProfileQuizScreen extends StatefulWidget {
  const ReaderProfileQuizScreen({super.key});

  @override
  State<ReaderProfileQuizScreen> createState() =>
      _ReaderProfileQuizScreenState();
}

class _ReaderProfileQuizScreenState extends State<ReaderProfileQuizScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final TextEditingController _textController;
  late final ConfettiController _confettiController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _textController = TextEditingController();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReaderProfileCubit(
        service: getIt<ReaderProfileService>(),
        repository: getIt<ReaderProfileRepository>(),
        googleBooksService: getIt<GoogleBooksService>(),
        bookLibraryService: getIt<BookLibraryService>(),
      )..prefillFromExistingProfile(),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Okuyucu Profili', // TODO: l10n
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<ReaderProfileCubit, ReaderProfileState>(
            listener: (context, state) {
              // Sync text controller when prefill loads previous Q1 answer
              if (state.status == ReaderProfileStatus.quizInProgress &&
                  state.q1Answer.isNotEmpty &&
                  _textController.text.isEmpty) {
                _textController.text = state.q1Answer;
              }

              if (state.status == ReaderProfileStatus.generating) {
                _goToPage(4);
              } else if (state.status == ReaderProfileStatus.generated) {
                _confettiController.play();
                _goToPage(5);
              } else if (state.status == ReaderProfileStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ??
                          'Something went wrong', // TODO: l10n
                    ),
                    action: SnackBarAction(
                      label: 'Retry', // TODO: l10n
                      onPressed: () {
                        context.read<ReaderProfileCubit>().retry();
                      },
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildQ1Page(context, state),
                        _buildQ2Page(context, state),
                        _buildQ4Page(context, state),
                        _buildQ5Page(context, state),
                        _buildLoadingPage(),
                        _buildResultPage(context, state),
                      ],
                    ),
                  ),
                  if (state.status != ReaderProfileStatus.generating &&
                      state.status != ReaderProfileStatus.generated)
                    _buildBottomButton(context, state),
                ],
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  // ─── Q1: Free text ─────────────────────────────────────────────

  Widget _buildQ1Page(BuildContext context, ReaderProfileState state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
          const MascotWidget(size: 100, showGlow: true),
          const SizedBox(height: 16),
          const SpeechBubble(
            // TODO: l10n
            text: 'Ne tarz kitapları seversin?',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            onChanged: (value) {
              context.read<ReaderProfileCubit>().setQ1(value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceDark,
              // TODO: l10n
              hintText: 'Tür, yazar veya favori kitap adı yaz...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
    );
  }

  // ─── Q2: Chip selection ────────────────────────────────────────

  Widget _buildQ2Page(BuildContext context, ReaderProfileState state) {
    final q2Data = _getQ2Data(state.q2Answers);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const MascotWidget(size: 100, showGlow: true),
          const SizedBox(height: 16),
          SpeechBubble(text: q2Data.question),
          const SizedBox(height: 6),
          Text(
            'Birden fazla seçebilirsin',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: q2Data.chips.map((chip) {
              final isSelected = state.q2Answers.contains(chip);
              return _buildChip(
                label: chip,
                isSelected: isSelected,
                onTap: () {
                  context.read<ReaderProfileCubit>().toggleQ2(chip);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Q4: Reading habits ───────────────────────────────────────

  Widget _buildQ4Page(BuildContext context, ReaderProfileState state) {
    const chips = [
      'Her gün düzenli okurum',
      'Haftada birkaç kez, uzun seanslar',
      'Nadiren ama başlayınca bırakamam',
      'Birden fazla kitabı aynı anda okurum',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const MascotWidget(size: 100, showGlow: true),
          const SizedBox(height: 16),
          // TODO: l10n
          const SpeechBubble(text: 'Okuma alışkanlığını en iyi hangisi tanımlar?'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: chips.map((chip) {
              final isSelected = state.q4Answer == chip;
              return _buildChip(
                label: chip,
                isSelected: isSelected,
                onTap: () => context.read<ReaderProfileCubit>().setQ4(chip),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Q5: Emotional preference ────────────────────────────────

  Widget _buildQ5Page(BuildContext context, ReaderProfileState state) {
    const chips = [
      'Düşündürsün, kafamda kalsın',
      'Duygusal olarak derinden etkileneyim',
      'Eğleneyim, kaçış yaşayayım',
      'Bilgi ve perspektif kazanayım',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const MascotWidget(size: 100, showGlow: true),
          const SizedBox(height: 16),
          // TODO: l10n
          const SpeechBubble(text: 'Bir kitabı bitirdiğinde nasıl hissetmek istersin?'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: chips.map((chip) {
              final isSelected = state.q5Answer == chip;
              return _buildChip(
                label: chip,
                isSelected: isSelected,
                onTap: () => context.read<ReaderProfileCubit>().setQ5(chip),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Loading page ──────────────────────────────────────────────

  Widget _buildLoadingPage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: const MascotWidget(size: 140, showGlow: true),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      AppColors.textSecondary,
                      AppColors.textPrimary,
                      AppColors.textSecondary,
                    ],
                    stops: [
                      _shimmerAnimation.value - 0.3,
                      _shimmerAnimation.value,
                      _shimmerAnimation.value + 0.3,
                    ].map((s) => s.clamp(0.0, 1.0)).toList(),
                  ).createShader(bounds);
                },
                child: const Text(
                  'Okuma ruhun analiz ediliyor...', // TODO: l10n
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Result page ───────────────────────────────────────────────

  Widget _buildResultPage(BuildContext context, ReaderProfileState state) {
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 20,
            gravity: 0.05,
            emissionFrequency: 0.05,
            colors: const [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.amber,
              AppColors.success,
            ],
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const MascotWidget(size: 80, showGlow: false),
              const SizedBox(height: 16),
              const Text(
                'Senin Okuyucu Arketipin', // TODO: l10n
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ).createShader(bounds),
                child: Text(
                  profile.archetypeName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.archetypeDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildReadingDnaSection(profile),
              const SizedBox(height: 32),
              _buildRecommendedBooksSection(profile),
              const SizedBox(height: 40),
              // "Tamam" button instead of "Hadi Başlayalım!"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Tamam', // TODO: l10n
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadingDnaSection(ReaderProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Okuma DNA'n", // TODO: l10n
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _buildProgressBar(
          'Karakter Odağı', // TODO: l10n
          profile.profileScore.characterFocus,
          AppColors.primary,
        ),
        const SizedBox(height: 16),
        _buildProgressBar(
          'Olay Örgüsü', // TODO: l10n
          profile.profileScore.plotFocus,
          AppColors.success,
        ),
        const SizedBox(height: 16),
        _buildProgressBar(
          'Atmosfer', // TODO: l10n
          profile.profileScore.atmosphereFocus,
          AppColors.amber,
        ),
        const SizedBox(height: 16),
        _buildProgressBar(
          'Tempo', // TODO: l10n
          profile.profileScore.paceSlow,
          const Color(0xFF06B6D4),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, int value, Color color) {
    final clampedValue = value.clamp(0, 100);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$clampedValue%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedValue / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedBooksSection(ReaderProfile profile) {
    if (profile.recommendedBooks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sana Önerilen Kitaplar', // TODO: l10n
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profile.recommendedBooks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = profile.recommendedBooks[index];
              return _buildBookCard(book);
            },
          ),
        ),
        const SizedBox(height: 16),
        // Hint: more recommendations on profile page
        Text(
          'Daha fazla kitap önerisi için profil sayfanı ziyaret edebilirsin',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.3),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(RecommendedBook book) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  book.reason,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom button ─────────────────────────────────────────────

  Widget _buildBottomButton(BuildContext context, ReaderProfileState state) {
    final bool isEnabled;
    switch (state.currentQuestion) {
      case 0:
        isEnabled = state.q1Answer.trim().length >= 3;
        break;
      case 1:
        isEnabled = state.q2Answers.isNotEmpty;
        break;
      case 2:
        isEnabled = state.q4Answer.isNotEmpty;
        break;
      case 3:
        isEnabled = state.q5Answer.isNotEmpty;
        break;
      default:
        isEnabled = false;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled
              ? () {
                  final cubit = context.read<ReaderProfileCubit>();
                  if (state.currentQuestion < 3) {
                    cubit.nextQuestion();
                    _goToPage(state.currentQuestion + 1);
                  } else {
                    cubit.generateProfile();
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isEnabled ? 8 : 0,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
          child: Text(
            state.currentQuestion < 3
                ? 'Devam Et' // TODO: l10n
                : 'Profilimi Oluştur', // TODO: l10n
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Chip builder ──────────────────────────────────────────────

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Q2/Q3 data ────────────────────────────────────────────────

  _QuestionData _getQ2Data(List<String> selected) {
    return _QuestionData(
      question: 'Bir kitapta seni en çok ne etkiler?',
      chips: [
        'Güçlü karakterler ve ilişkiler',
        'Sürükleyici olay örgüsü',
        'Düşündüren temalar ve fikirler',
        'Atmosfer ve yazım dili',
        'Duygusal derinlik',
        'Bilgi ve yeni bakış açıları',
        'Gerilim ve merak',
      ],
    );
  }

}

class _QuestionData {
  final String question;
  final List<String> chips;

  const _QuestionData({required this.question, required this.chips});
}
