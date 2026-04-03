import '../models/reader_profile.dart';
import 'ai_chat_service.dart';

class ReaderProfileService {
  final AiChatService _aiChatService;

  ReaderProfileService({required AiChatService aiChatService})
      : _aiChatService = aiChatService;

  Future<ReaderProfile> generateProfile({
    required String q1Answer,
    required String q2Answer,
    required String q3Answer,
    String q4Answer = '',
    String q5Answer = '',
    List<String> userFinishedBooks = const [],
    int totalPagesRead = 0,
    int totalFocusMinutes = 0,
  }) async {
    // Build library context section
    final librarySection = StringBuffer();
    if (userFinishedBooks.isNotEmpty) {
      librarySection.writeln('\nKullanıcının okuduğu kitaplar (kütüphanesinden):');
      for (final book in userFinishedBooks.take(20)) {
        librarySection.writeln('  - $book');
      }
    }
    if (totalPagesRead > 0 || totalFocusMinutes > 0) {
      librarySection.writeln('\nOkuma istatistikleri:');
      if (totalPagesRead > 0) librarySection.writeln('  - Toplam okunan sayfa: $totalPagesRead');
      if (totalFocusMinutes > 0) librarySection.writeln('  - Toplam odak süresi: $totalFocusMinutes dakika');
    }

    final prompt = '''
Sen bir kitap uzmanı ve okuyucu psikologusun.
Kullanıcının cevaplarına ve okuma geçmişine bakarak detaylı ve kişiselleştirilmiş bir okuyucu profili oluştur.

Kullanıcı cevapları:
- Etkilendiği kitap: $q1Answer
- Okurken neye odaklanır: $q2Answer
- Detay tercihi: $q3Answer
${q4Answer.isNotEmpty ? '- Okuma alışkanlığı: $q4Answer' : ''}
${q5Answer.isNotEmpty ? '- Duygusal tercih: $q5Answer' : ''}
$librarySection
Önemli kurallar:
- Kullanıcının tüm cevaplarını birlikte değerlendir, tek bir cevaba takılma.
- Arketip adı yaratıcı ve özgün olsun (örn: "Karanlık Derinliklerin Kaşifi", "Sessiz Fırtına Okuyucusu").
- archetypeDescription en az 3 cümle olsun ve kullanıcının okuma kişiliğini derinlemesine anlatsın.
- profileScore değerleri birbirinden belirgin şekilde farklı olsun (hepsi 50-60 aralığında olmasın).
- Kitap önerileri kullanıcının kütüphanesinde olmayan, farklı ama uygun kitaplar olsun.

Türkçe olarak yanıt ver. Sadece aşağıdaki JSON formatında dön, başka hiçbir şey yazma:

{
  "archetypeName": "...",
  "archetypeDescription": "...",
  "preferredGenres": [...],
  "preferredTone": "...",
  "avoidGenres": [...],
  "recommendedBooks": [
    { "title": "...", "author": "...", "reason": "..." },
    { "title": "...", "author": "...", "reason": "..." },
    { "title": "...", "author": "...", "reason": "..." }
  ],
  "readingSpeedMinutes": 30,
  "profileScore": {
    "characterFocus": 0-100,
    "plotFocus": 0-100,
    "atmosfereFocus": 0-100,
    "paceSlow": 0-100
  }
}
''';

    final json = await _aiChatService.generateJson(prompt: prompt);

    final now = DateTime.now();
    return ReaderProfile(
      archetypeName: json['archetypeName'] ?? '',
      archetypeDescription: json['archetypeDescription'] ?? '',
      preferredGenres: List<String>.from(json['preferredGenres'] ?? []),
      preferredTone: json['preferredTone'] ?? '',
      avoidGenres: List<String>.from(json['avoidGenres'] ?? []),
      recommendedBooks: (json['recommendedBooks'] as List?)
              ?.map(
                  (e) => RecommendedBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      readingSpeedMinutes: json['readingSpeedMinutes'] ?? 30,
      profileScore: json['profileScore'] != null
          ? ProfileScore.fromJson(
              json['profileScore'] as Map<String, dynamic>)
          : const ProfileScore(),
      quizAnswers: QuizAnswers(
        q1: q1Answer,
        q2: q2Answer,
        q3: q3Answer,
        q4: q4Answer,
        q5: q5Answer,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<RecommendedBook>> generateMoreRecommendations({
    required ReaderProfile profile,
    required List<String> previouslyRecommendedTitles,
    List<String> dislikedTitles = const [],
    int count = 3,
  }) async {
    final excludeList = previouslyRecommendedTitles.join(', ');
    final dislikedSection = dislikedTitles.isNotEmpty
        ? '\nKullanıcının beğenmediği / ilgisini çekmeyen kitaplar (benzerlerini de önerme): ${dislikedTitles.join(', ')}\n'
        : '';

    final prompt = '''
Sen bir kitap uzmanı ve okuyucu psikologusun.
Kullanıcının okuyucu profiline bakarak $count yeni kitap öner.

Okuyucu Profili:
- Arketip: ${profile.archetypeName}
- Açıklama: ${profile.archetypeDescription}
- Tercih edilen türler: ${profile.preferredGenres.join(', ')}
- Okuma tonu: ${profile.preferredTone}
- Kaçınılan türler: ${profile.avoidGenres.join(', ')}
- Profil Skorları: Karakter Odağı ${profile.profileScore.characterFocus}%, Olay Örgüsü ${profile.profileScore.plotFocus}%, Atmosfer ${profile.profileScore.atmosphereFocus}%, Tempo ${profile.profileScore.paceSlow}%

Daha önce önerilen kitaplar (bunları ÖNERMEYİN): $excludeList
$dislikedSection
Türkçe olarak yanıt ver. Tam olarak $count kitap öner. Sadece aşağıdaki JSON formatında dön:

{
  "recommendedBooks": [
    { "title": "...", "author": "...", "reason": "..." }
  ]
}
''';

    final json = await _aiChatService.generateJson(prompt: prompt);

    return (json['recommendedBooks'] as List?)
            ?.map((e) => RecommendedBook.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }
}
