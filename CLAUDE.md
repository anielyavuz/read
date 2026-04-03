# CLAUDE.md — Bookpulse

Bu dosya Claude Code'un projeyi anlaması için hazırlanmıştır.
Her oturumda otomatik okunur. Güncel tut.

---

## Git Branching Kuralları (KESİN KURAL)

**Repo:** https://github.com/anielyavuz/read.git

### main Branch Koruması

> **YASAK: `main` branch'ine doğrudan commit veya push YAPILMAZ.**
> Bu kural tüm Claude Code instance'ları için geçerlidir — mobil, masaüstü, web fark etmez.

### Workflow

1. **Her değişiklik yeni bir branch'te yapılır.**
   - Branch adı formatı: `feature/kisa-aciklama` veya `fix/kisa-aciklama`
   - Örnekler: `feature/focus-mode-timer`, `fix/streak-calculation-bug`
2. **Değişiklik tamamlandığında PR (Pull Request) oluşturulur.**
   - PR açıklaması ne yapıldığını ve neden yapıldığını içermelidir.
   - PR hedefi her zaman `main` branch'idir.
3. **PR, Anıl tarafından PC'den test edilir ve onaylanırsa `main`'e merge edilir.**
   - Claude Code asla kendi PR'ını merge etmez.
   - Claude Code asla `main`'e push etmez.
4. **Yasaklı komutlar (her durumda):**
   ```
   git push origin main
   git push --force origin main
   git merge ... && git push origin main
   gh pr merge ...
   ```
5. **İzin verilen akış:**
   ```
   git checkout -b feature/xyz
   # ... değişiklikler ...
   git add ... && git commit ...
   git push -u origin feature/xyz
   gh pr create --base main ...
   ```

### Mobil Claude Code İçin Ek Kurallar
- Mobil Claude Code sadece branch oluşturur, commit yapar, push eder ve PR açar.
- main'e merge etme, main'e push etme, force push yapma YETKİSİ YOKTUR.
- PR açtıktan sonra kullanıcıya PR linkini verir ve durur.

---

## Proje Kimliği

**Uygulama:** Bookpulse
**Konsept:** Duolingo tarzı gamification ile kitap okuma takibi ve rekabet platformu
**Hedef Pazar:** BookTok topluluğu (US / UK / AU) — 18-35 yaş, İngilizce
**Model:** Subscription SaaS — 14 günlük trial → hard paywall
**Fiyat:** Reader $4.99/ay · Bookworm $8.99/ay · Yıllık %35 indirim

---

## Tech Stack

| Katman | Teknoloji |
|--------|-----------|
| Mobile | Flutter (iOS + Android) |
| Auth | Firebase Auth |
| Database | Firebase Firestore |
| Storage | Firebase Storage |
| Functions | Firebase Cloud Functions (Node.js) |
| Push | Firebase Cloud Messaging (FCM) |
| Hosting | Firebase Hosting |
| Subscription | RevenueCat |
| AI / Quiz | Gemini 2.5 Flash (`gemini-2.5-flash`) |
| Book API | Google Books API |
| Analytics | Firebase Analytics + Crashlytics |
| CI/CD | GitHub Actions |

> **Önemli:** AI modelini her zaman `gemini-2.5-flash` kullan. `gemini-2.0-flash` veya
> eski modeller kullanma. Pahalı işlemler için `gemini-2.5-pro` değerlendir.

---

## Proje Yapısı

```
bookpulse/
├── lib/
│   ├── core/
│   │   ├── constants/          # app_colors.dart, app_strings.dart
│   │   ├── models/             # User, Book, League, XP, Quiz modelleri
│   │   ├── services/           # Firebase, RevenueCat, Gemini servisleri
│   │   └── utils/              # helpers, formatters
│   ├── features/
│   │   ├── auth/               # login, signup, onboarding
│   │   ├── tracking/           # kitap ekleme, sayfa/süre takibi, timer
│   │   ├── focus/              # Focus Mode ekranı, puppy diary
│   │   ├── gamification/       # XP, streak, badge, level sistemi
│   │   ├── companion/          # Paige puppy maskot, ırk seçimi, evrim, kişilik
│   │   ├── league/             # haftalık ligler, liderboard, sıralama
│   │   ├── discover/            # challenge keşfet, challenge detay, challenge kartları
│   │   ├── reader_profile/     # Gemini AI okuyucu profili, quiz, arketip
│   │   ├── quiz/               # ReadBrain AI quiz modülü
│   │   ├── social/             # arkadaşlar, aktivite akışı, paylaşım
│   │   ├── subscription/       # RevenueCat paywall, plan seçimi
│   │   ├── notifications/      # okuma saati, akıllı bildirimler
│   │   └── profile/            # istatistikler, rozetler, ayarlar
│   └── main.dart
├── functions/                  # Firebase Cloud Functions
│   ├── src/
│   │   ├── league/             # haftalık lig hesaplama, terfi/düşüş
│   │   ├── challenges/         # challenge oluşturma, sonuç hesaplama
│   │   ├── notifications/      # streak hatırlatma, lig sonucu, akıllı bildirim FCM
│   │   └── quiz/               # Gemini API çağrısı, soru üretimi
│   └── index.ts
├── assets/
│   ├── images/                 # uygulama görselleri (maskot vb.)
│   └── dogs/                   # köpek ırk görselleri (ırk başına klasör)
│       ├── golden_retriever/   # default.jpg + gelecekte animasyonlar
│       ├── corgi/
│       ├── shiba_inu/
│       └── ...                 # 11 ırk toplam
├── animations/                 # kaynak animasyon dosyaları (design reference)
├── firestore.rules
├── firestore.indexes.json
└── CLAUDE.md                   # bu dosya
```

---

## Temel Veri Modelleri (Firestore)

```
users/{userId}
  - displayName, email, avatarUrl
  - xpTotal, xpThisWeek
  - streakDays, lastReadDate
  - currentLeague: "bronze" | "silver" | "gold" | "platinum" | "diamond"
  - subscriptionTier: "free" | "reader" | "bookworm"
  - booksRead: number, pagesRead: number
  - companionLevel: number             # Paige puppy seviyesi (1-50)
  - companionName: string              # kullanıcının verdiği isim
  - companionBreed: string             # köpek ırkı (golden_retriever, corgi, shiba_inu, vb.)
  - companionMood: "happy" | "playful" | "sulky" | "sleeping" | "excited"
  - companionLastFed: timestamp        # son okuma aktivitesi (bakım durumu için)
  - readingSchedule: { weekday: "21:00", weekend: "10:00", duration: 30 }
  - focusMinutesTotal: number           # toplam Focus Mode süresi

books/{bookId}                   # Google Books'tan cache
  - title, author, coverUrl, pageCount, isbn

userBooks/{userId}/library/{bookId}
  - status: "reading" | "finished" | "tbr"
  - currentPage, startDate, finishDate
  - totalReadingMinutes
  - quizScore: number | null

leagues/{weekId}/participants/{userId}
  - xpEarned, rank, promoted, relegated

challenges/{challengeId}
  - type: "read_along" | "sprint" | "genre" | "pages"
  - title, description
  - creatorId, bookId (optional)
  - startDate, endDate
  - targetPages | targetBooks | targetMinutes
  - maxParticipants: number (default 30)
  - isPublic: boolean

challenges/{challengeId}/participants/{userId}
  - progress: number
  - rank: number
  - joinedAt, lastUpdateAt

focusSessions/{userId}/{sessionId}
  - startTime, endTime, durationMinutes
  - bookId, pagesRead
  - puppyCareReward: string           # kazanilan puppy odul (snack/walk/play/feast)

quizResults/{userId}/{bookId}
  - questions[], answers[], score, completedAt

activityLog/{userId}/entries/{entryId}
  - type: "focusSession" | "pageProgress" | "bookFinished" | "badgeEarned" | "streakMilestone" | "challengeCompleted" | "levelUp"
  - timestamp: Timestamp
  - xpEarned: number
  - durationMinutes?: number           # focusSession
  - bookTitle?: string                 # focusSession, pageProgress, bookFinished
  - pagesRead?: number                 # focusSession, pageProgress
  - badgeId?: string                   # badgeEarned
  - streakDays?: number                # streakMilestone
  - challengeTitle?: string            # challengeCompleted
  - newLevel?: number                  # levelUp
```

---

## Gamification Kuralları

### XP Sistemi (Tek Para Birimi — Karmaşık gem/coin sistemi YOK)
```
Temel:
  +10 XP   — her sayfa okunduğunda (timer aktifken)
  +50 XP   — günlük okuma hedefi tamamlandı (min 20 dakika)
  +200 XP  — kitap bitirildi
  +100 XP  — ReadBrain quiz tamamlandı (%70+ puan)
  +25 XP   — yeni gün streak korundu

Focus Mode:
  +15 XP   — 15 dk focus seans
  +30 XP   — 30 dk focus seans
  +50 XP   — 60 dk+ focus seans
  x2 XP    — Co-Reading seansı bonusu

Challenge:
  +50 XP   — challenge'a katılma
  +150 XP  — challenge tamamlama
  +300 XP  — Top 3 bitirme

Çarpanlar:
  x1.5 XP  — 7+ günlük streak bonusu
  x2.0 XP  — Double XP Day (sürpriz — haftada rastgele 1 gün)
```

### Rozet Sistemi (Paylaşılabilir — BookTok-ready PNG kartları)
```
Okuma Rozetleri:
  - First Page      → ilk sayfa okundu
  - Bookworm        → 10 kitap bitirildi
  - Century Club    → 100 kitap bitirildi
  - Speed Reader    → 3 günden kısa sürede kitap bitirildi
  - Genre Explorer  → 5 farklı türde kitap okundu
  - Night Owl       → gece yarısından sonra 10 kez okundu
  - Early Bird      → sabah 7'den önce 10 kez okundu

Streak Rozetleri:
  - On Fire (7 gün) · Unstoppable (30 gün) · Legend (100 gün) · Immortal (365 gün)

Challenge Rozetleri:
  - Challenger       → ilk challenge tamamlandı
  - Champion         → 5 challenge'da Top 3
  - Undefeated       → 3 challenge art arda 1. olma

Özel:
  - ReadBrain Certified → quiz %70+ puan
  - Diamond League      → Diamond lig'e ulaşma
  - Puppy Caretaker     → 50 focus seans puppy bakimi tamamlama
  - Paige's Best Friend → puppy'yi Lv 25'e ulaştırma
  - Top Dog             → puppy'yi Lv 50 Majestic Dog'a ulaştırma

Her rozet BookTok/Instagram Story formatında paylaşılabilir PNG kartı üretir.
```

### Streak Kuralları
- Her gün en az 1 sayfa okunmalı veya 5 dakika timer çalışmalı
- UTC gece yarısı sıfırlanır
- "Streak Freeze" item'ı: Bookworm plan kullanıcılarına haftada 1
- Streak 0 olduğunda: "Serini başlat!" prompt mesajı gösterilir
  (l10n: streakStartPrompt), "0 günlük seri" yazılmaz

### League Sistemi (Duolingo modeli)
```
Bronze   → Silver  → Gold  → Platinum  → Diamond
  30 kişilik gruplara random atanır (aynı ligden)
  Hafta pazartesi başlar, pazar sona erer
  Top 10 → terfi · Bottom 5 → düşüş · Ara → kalır
  Diamond'da düşüş yok
```

### Challenge Sistemi
```
Kullanıcılar challenge oluşturabilir veya mevcut olanlara katılabilir.
Her challenge max 30 kişi, herkes sıralamayı görür.

Challenge Türleri:
  - Read-Along    → aynı kitabı birlikte okuma (belirli sürede)
  - Sprint        → "Bu hafta en çok sayfa kim okur?"
  - Genre         → "Bu ay 3 bilim kurgu kitabı bitir"
  - Pages Goal    → "30 günde 1000 sayfa oku"

XP Ödülleri:
  +50 XP   → challenge'a katılma
  +150 XP  → challenge tamamlama
  +300 XP  → challenge'da Top 3 bitirme

Kurallar:
  - Free kullanıcılar: aynı anda max 1 challenge
  - Reader: max 3 aktif challenge
  - Bookworm: sınırsız + challenge oluşturma hakkı

Akıllı Challenge Bildirimleri:
  Kullanıcı bir challenge'a katıldığında, challenge'ın türüne ve süresine göre
  otomatik olarak yerel bildirimler planlanır (flutter_local_notifications + timezone).

  Bildirim Zamanlaması:
    - Son gün hatırlatma: endDate - 1 gün, saat 10:00
      Tüm challenge türleri için aktif (daysLeft >= 1)
    - Yarı yol hatırlatma: toplam sürenin ortasında, saat 10:00
      Sadece 7 günden uzun challenge'lar için aktif

  Bildirim İçeriği (challenge türüne göre):
    - Pages / ReadAlong → "Challenge yarın bitiyor. X sayfa hedefin kaldı!"
    - Sprint            → "Challenge yarın bitiyor. Her dakika önemli — odak seansı başlat!"
    - Genre             → "Challenge yarın bitiyor. Bir kitap bitir!"
    - Mid-point         → "Challenge yarısında! Hedef: X sayfa/dakika/kitap"

  Otomatik İptal:
    - Kullanıcı challenge'dan ayrılırsa → bildirimler iptal edilir
    - Kullanıcı challenge hedefini tamamlarsa → bildirimler iptal edilir
      (FocusCubit, BookDetailCubit içinde updateMyProgress sonrası kontrol)

  Teknik Detaylar:
    - Servis: lib/core/services/challenge_notification_service.dart
    - Notification ID: FNV-1a deterministik hash (challengeId + slot)
      String.hashCode Dart'ta her çalıştırmada farklı değer üretir,
      bu yüzden FNV-1a kullanılır (app restart sonrası iptal edebilmek için)
    - Channel: 'challenge_reminders'
    - DateTime aritmetiği: `endDate.subtract(Duration(days: 1))` kullan,
      `endDate.day - 1` kullanma (ay başlarında geçersiz tarih üretir)
    - L10n key'ler: challengeLastDayTitle, challengeLastDay*Body,
      challengeMidPointTitle, challengeMidPoint*Body
    - Yeni challenge türü eklendiğinde:
      1. l10n ARB'lere tür-spesifik body string ekle
      2. ChallengeDetailCubit._scheduleChallengeNotifications'a yeni case ekle
      3. Gerekirse ChallengeNotificationService.scheduleForChallenge'da
         zamanlama mantığını güncelle

  Challenge Service Teknik Kararları:
    - joinChallenge/leaveChallenge: Firestore transaction ile atomik
      (race condition önleme — maxParticipants aşımı engellenir)
    - getChallengeParticipants: progress'e göre descending sıralanır,
      rank client-side hesaplanır (1-indexed), Firestore'da rank saklanmaz
    - getMyActiveChallengeCount/getMyChallenges: Future.wait ile paralel
      lookup (N+1 query optimizasyonu)
    - Tier limitleri: free=1, reader=3, bookworm=sınırsız

  Challenge Tür Renkleri (tüm ekranlarda tutarlı):
    - readAlong → 0xFF22C55E (yeşil)
    - sprint    → 0xFFF59E0B (amber)
    - genre     → 0xFF8B5CF6 (mor)
    - pages     → 0xFF06B6D4 (cyan)

  Gün Kalan Hesaplama (tüm challenge ekranlarında):
    - DateTime.now() yerine date-only karşılaştırma kullan:
      DateTime(year, month, day) — saat bileşenini kaldır
    - Biten challenge'lar: "Ended" / "Bitti" göster (l10n: challengeDetailEnded)
```

---

## Focus Mode (Puppy Care)

Paige puppy ile entegre odaklanma modu.
Timer başlatılır, okuma süresince puppy eşlik eder.
Seans tamamlandığında süreye göre puppy bakım ödülü kazanılır.

```
Modlar:
  - Pomodoro    → 25 dk okuma + 5 dk mola (tekrarlı)
  - Free Timer  → serbest süre (stopwatch)
  - Hedefli     → "X sayfa okuyana kadar" modu

Puppy Bakım Ödülleri (süreye göre):
  - 15 dk altı  → Snack (atıştırmalık)
  - 15-29 dk    → Walk (yürüyüş)
  - 30-59 dk    → Play (oyun)
  - 60 dk+      → Feast (ziyafet)
  - Puppy Diary: Haftalık 7 günlük grid görünümü (bakım geçmişi)
  - Arkadaşlarla "Co-Reading" seansı (Flora modeli)
    Tüm katılımcılar odaklanmalı, biri çıkarsa seans iptal

XP Ödülleri:
  +15 XP  → 15 dk focus seans tamamlama
  +30 XP  → 30 dk focus seans tamamlama
  +50 XP  → 60 dk+ focus seans tamamlama
  x2 XP   → Co-Reading seansı bonusu
```

---

## Paige — Okuma Maskotu (Puppy)

Finch uygulamasından ilham alan pozitif pekiştirmeli maskot sistemi.
"Paige" (sayfa kelimesinden türetilmiş) sevimli bir köpek yavrusu (puppy).
Kullanıcı onboarding'de 11 ırktan birini seçer ve isim verir.
Her ırkın kendine özgü bir trait'i (özelliği) var — oyun mekaniğiyle bağlantılı.
Seçilen ırk, okuma hedefi varsayılanını belirler.

```
Irk Seçenekleri (11 farklı — her birinin trait + varsayılan günlük hedefi var):

  Irk                  Trait             Hedef  Açıklama
  ─────────────────────────────────────────────────────────────────────
  1. Golden Retriever  Streak Lover      20pg   Seriyi asla bozmaz! Her gün okuma ister.
  2. Corgi             Sprint Champion   15pg   Kısa ve hızlı! Sprint okuma seanslarını sever.
  3. Shiba Inu         Lone Wolf         25pg   Kendi hızında okur. Derin & odaklı seanslar.
  4. Poodle            Quiz Master       20pg   Beyin gücü! Her kitaptan sonra quiz ister.
  5. Dalmatian         Challenger        30pg   Rekabet için doğmuş! Challenge'lar için yaşar.
  6. Siberian Husky    Drama Queen       20pg   Her şeye aşırı tepki verir!
  7. German Shepherd   Disciplined       25pg   Sıkı rutin. Mazeret yok, tatil yok.
  8. Rottweiler        Endurance         30pg   Maraton okuyucu. Uzun focus seansları.
  9. Border Collie     Goal Crusher      25pg   Haftalık hedeflere takılmış. Asla kaçırmaz.
  10. Kangal           League Warrior    20pg   Liderlik tablosunu tırmanır. Top 10 ya da hiç!
  11. Saint Bernard    Zen Reader        15pg   Acele yok, stres yok. Yolculuğun tadını çıkarır.

  Trait → Mekanik Bağlantısı:
  - Streak Lover     → streak XP bonusu vurgulanır, streak kırılınca ekstra üzgün
  - Sprint Champion  → kısa challenge'larda bonus, sprint modu önerilir
  - Lone Wolf        → uzun solo focus seanslarında bonus
  - Quiz Master      → ReadBrain quiz hatırlatması daha sık, quiz XP bonusu
  - Challenger       → challenge katılma teşviki, challenge XP bonusu
  - Drama Queen      → aşırı dramatik animasyonlar (sevinç/üzüntü)
  - Disciplined      → sabit okuma saati hatırlatması daha güçlü
  - Endurance        → uzun focus seans bonusu (60dk+)
  - Goal Crusher     → haftalık hedef tracking vurgulanır
  - League Warrior   → lig sıralama bildirimleri daha sık
  - Zen Reader       → focus mode ambient sesler vurgulanır, yumuşak hatırlatmalar

  Asset Yapısı:
  assets/dogs/{breed_id}/default.jpg   — varsayılan görsel (mevcut)
  assets/dogs/{breed_id}/happy.json    — Lottie animasyonu (gelecek)
  assets/dogs/{breed_id}/sad.json      — Lottie animasyonu (gelecek)
  Her ırk için ayrı klasör — yeni görseller/animasyonlar kolayca eklenebilir

Büyüme Seviyeleri (YAVAŞ büyüme — haftalar/aylar sürer):
  Lv 1-5    → Tiny Pup (minik, tombul, uyuşuk — yeni doğmuş yavru)
  Lv 6-15   → Playful Pup (oyuncu, kulakları büyük, hareketli)
  Lv 16-30  → Growing Dog (gençleşen, daha bakımlı, parlak tüyler)
  Lv 31-45  → Handsome Dog (yakışıklı/güzel, fit, parlayan tüyler)
  Lv 46-50  → Majestic Dog (muhteşem, taç/aura, şampiyon köpek görünümü)

  Büyüme Hızı:
  - Her 500 XP = 1 seviye (yavaş ve tatmin edici)
  - Max seviyeye ulaşmak ~6 ay düzenli okuma gerektirir
  - Seviye atladıkça köpek görsel olarak büyür ve güzelleşir:
    tüyler parlar, duruş değişir, göz ifadesi olgunlaşır

Bakım Durumu (okuma aktivitesine göre):
  Düzenli okuma (her gün):
    - Tüyler parlak ve bakımlı
    - Kuyruk sallar, zıplar, mutlu animasyonlar
    - Minik kalpler/yıldızlar çıkar

  1-2 gün okumama:
    - Hafif küskün bakış, kulaklar düşük
    - "I miss our reading time..." baloncuğu
    - Hâlâ sevimli ama biraz üzgün

  3-4 gün okumama:
    - Trip atar! Sırtını döner, yan bakış yapar
    - "Hmph! You forgot about me..." baloncuğu
    - Tüyler hafif kabarık/dağınık

  5+ gün okumama:
    - Dramatik küsme: battaniyeye sarılıp uyur
    - "Wake me up when you start reading again..."
    - Ama geri dönünce SÜPER mutlu karşılama animasyonu!
    - (Asla cezalandırma YOK — sadece duygusal motivasyon)

Geri Dönüş Sevinçleri:
  - 1 gün ara sonrası: kuyruk sallama + zıplama
  - 3+ gün ara sonrası: delicesine koşma + yüze atlama animasyonu
  - 7+ gün ara sonrası: gözyaşı + "YOU'RE BACK!" + havai fişek

Kişilik Özellikleri (okunan türlere göre):
  - Romantik kitap çok okuyorsa: dramatik iç çeker, kalp gözler yapar
  - Gerilim/polisiye okuyorsa: dedektif şapka takar, ipucu koklama animasyonu
  - Bilim kurgu okuyorsa: uzay gözlüğü takar, fütüristik tepkiler
  - Fantastik okuyorsa: büyücü şapka, sihirli kuyruk sallama
  - Non-fiction okuyorsa: gözlük takar, "akıllı köpek" pozu

Etkileşimler:
  - Uygulama açılışında selamlama (günün saatine göre — sabah esner, akşam uyuşuk)
  - Streak korunduğunda kutlama animasyonu (kemik yakalar, dönerek zıplar)
  - Kitap bitirildiğinde: kitapla oynama animasyonu + kısa yorum
  - Seviye atlayınca: özel evrim animasyonu (büyüme efekti)
  - BookTok paylaşım kartlarında Paige görünür

Kıyafet & Aksesuar:
  - XP ile açılan aksesuarlar (tasma, bandana, gözlük, şapka, pelerin)
  - Irka özel aksesuarlar (Corgi taç, Husky kış atkısı vb.)
  - Sezonluk özel kostümler (Noel kazağı, Halloween kostümü, yaz şapkası)
  - Bookworm plan: premium kostümler + özel ırk varyasyonları (rare renkler)
```

---

## Akıllı Bildirimler & Okuma Saati

```
Okuma Saati:
  - Kullanıcı hafta içi ve hafta sonu için ayrı saat belirler
  - Örnek: Hafta içi 21:00, Hafta sonu 10:00
  - Süre hedefi: 15 / 30 / 45 / 60 dakika seçenekleri
  - Belirlenen saatten 10 dk önce bildirim gönderilir

Bildirim Türleri:
  1. Okuma Saati Hatırlatma
     "Hey! Okuma saatin 10 dakika sonra başlıyor. Paige seni bekliyor!"

  2. Streak Risk Uyarısı (gece 20:00)
     "14 günlük streak'in risk altında! Bugün sadece 5 dk yeterli."

  3. İlerleme Bazlı (akıllı)
     "Atomic Habits'te sadece 23 sayfa kaldı! Bu akşam bitirebilirsin."

  4. Challenge Güncellemesi
     "Sprint Challenge'da 2. sıraya düştün! 15 sayfa fark var."

  5. Sosyal
     "Arkadaşın @ece seni dürtükledi! Bugün okudin mi?"

  6. Haftalık Özet (Pazar akşamı)
     "Bu hafta: 142 sayfa, 3 saat 20 dk, streak 14 gün. Harika!"

Akıllı Zamanlama:
  - 2 hafta sonra: gerçek kullanım verisine göre saat önerisi
    "Genelde 22:00'da okuyorsun. Saatini güncellemek ister misin?"
  - Sessiz saatler: 23:00 - 07:00 arası bildirim gönderilmez
  - Günde max 2 bildirim (spam önleme)

Teknik:
  - FCM topic-based + user-specific scheduling
  - Cloud Function: her gece 00:00 UTC streak kontrol + bildirim kuyruğu
  - Kullanıcı bildirim tercihlerini Firestore'da sakla
```

---

## AI / ReadBrain Quiz

```typescript
// Cloud Function — quiz sorusu üretimi
const model = "gemini-2.5-flash";
const prompt = `
  Kitap: "${bookTitle}" - ${authorName}
  Bölüm/Konu: ${topic}
  
  Bu kitap hakkında 5 adet çoktan seçmeli anlama sorusu üret.
  Her soru için 4 seçenek, 1 doğru cevap ve kısa açıklama ekle.
  Zorluk: ${difficulty} (easy | medium | hard)
  Dil: English
  
  JSON formatında döndür:
  { questions: [{ q, options: [A,B,C,D], answer, explanation }] }
`;
```

- İlk aşamada top 500 kitap için curated soru havuzu (statik JSON)
- Havuzda olmayan kitaplar için Gemini ile dinamik üretim
- Skor %70+ ise "ReadBrain Certified" rozeti
- Maks 3 deneme hakkı, sonra 24 saat bekleme

---

## RevenueCat Entegrasyonu

```dart
// Entitlement ID'leri — değiştirme
const String ENTITLEMENT_READER   = "reader_access";
const String ENTITLEMENT_BOOKWORM = "bookworm_access";

// Product ID'ler (App Store Connect / Play Console'da tanımla)
// reader_monthly, reader_yearly
// bookworm_monthly, bookworm_yearly
```

- Trial: 14 gün (sadece ilk kez, restore'da aktif olmaz)
- Hard paywall: trial biter bitmez tüm premium özellikler kilitlenir
- Free kullanıcılar: max 3 kitap takibi, streak yok, lig yok

---

## Geliştirme Kuralları

### Kod Standartları
- Flutter: `flutter_bloc` (Cubit pattern) state management
- Firestore okumalarını her zaman `try/catch` içine al
- Offline-first: local cache önce, Firestore senkronize
- Tüm string'ler l10n ARB dosyalarından — hardcode etme (EN + TR zorunlu)
- String kullanımı: `AppLocalizations.of(context)!.keyName`
- Dark mode zorunlu, light mode opsiyonel (sonraki faz)

### Güvenlik
- Firestore rules: kullanıcı sadece kendi verisini okur/yazar
- Quiz cevap doğrulama SADECE Cloud Function'da yapılır (client'ta değil)
- RevenueCat webhook'larını Cloud Function'da doğrula

### Test
- Her feature için en az 1 widget test yaz
- Gamification logic (XP, streak, league) için unit test zorunlu
- Integration test: ödeme akışı (RevenueCat mock)

---

## Environment & Secrets

```
# .env (git'e commit etme — .gitignore'a ekle)
GEMINI_API_KEY=...
GOOGLE_BOOKS_API_KEY=...
REVENUECAT_API_KEY_IOS=...
REVENUECAT_API_KEY_ANDROID=...
```

Firebase config dosyaları: `google-services.json` (Android), `GoogleService-Info.plist` (iOS)
Her ikisi de `.gitignore`'da olmalı.

---

## Sık Kullanılan Komutlar

```bash
# Flutter
flutter run                          # development
flutter build ios --release          # App Store build
flutter build appbundle --release    # Play Store build
flutter test                         # tüm testler

# Firebase
firebase deploy --only functions     # sadece Cloud Functions
firebase deploy --only firestore     # sadece rules + indexes
firebase emulators:start             # local emulator

# Cloud Functions
cd functions && npm run build        # TypeScript derleme
cd functions && npm run lint         # lint kontrolü
```

---

## Reading Journey (Okuma Yolculuğu)

Ana sayfada (Home Tab) en altta Duolingo tarzı winding path görünümü.
Kullanıcının tüm okuma aktivitelerini kronolojik sırayla gösterir.

```
Veri Kaynakları (merge edilir, de-duplicate):
  1. activityLog subcollection  — yeni explicit kayıtlar
  2. focusSessions subcollection — tamamlanmış eski oturumlar
  3. badges subcollection — kazanılmış rozetler

Node Türleri:
  - focusSession    → Timer ikonu, süre + kitap adı
  - pageProgress    → Kitap ikonu, sayfa sayısı + kitap adı
  - bookFinished    → Trophy ikonu, kitap adı
  - badgeEarned     → Madalya ikonu, rozet adı (l10n)
  - streakMilestone → Ateş ikonu, streak günü
  - challengeCompleted → Bayrak ikonu, challenge adı
  - levelUp         → Pati ikonu, yeni seviye

UI:
  - Zigzag path: center → right → center → left (4'lü döngü)
  - CustomPainter ile dashed bezier curve bağlantı çizgileri
  - En son aktivite en üstte, glow efekti ile vurgulanır
  - Altta "Yolculuğa Devam Et" butonu → Focus Tab'a yönlendirir

Dosyalar:
  - Model: lib/core/models/activity_entry.dart
  - Service: lib/core/services/activity_service.dart
  - Widget: lib/features/home/widgets/reading_journey_path.dart
  - Loglama: FocusCubit + BookDetailCubit içinde _activityService.log()
```

---

## Faz Durumu

Roadmap detayı için `roadmap.txt` dosyasına bak.
Aktif faz ve tamamlanan görevler orada takip edilir.

---

## Remote Logging (Grafana / Loki)

Tüm kullanıcı aksiyonları `RemoteLoggerService` üzerinden Grafana Loki'ye loglanır.
Fire-and-forget mimari — servis kapalıysa uygulama etkilenmez.

```
Dosya: lib/core/services/remote_logger_service.dart
App Label: reado
Endpoint: https://logs.heymenu.org/loki/api/v1/push
Bağımlılık: http (pubspec.yaml'da zaten mevcut)
```

### Kullanım Kuralları

1. **Her yeni özelliğe loglama ekle** — Cubit'te kullanıcı aksiyonu gerçekleştiğinde logla
2. **Fire-and-forget** — `await` etme, hata yakala ve sessizce geç
3. **Hassas veri gönderme** — şifre, token, kişisel bilgi LOGLANMAZ
4. **Yüksek frekanslı loglardan kaçın** — döngü, scroll, timer tick loglanmaz
5. **Context otomatik** — Auth login'de `setUserContext`, logout'ta `clearContext` çağrılır

### Mevcut Log Metodları

```dart
// Genel
RemoteLoggerService.info(msg, screen: 'x');
RemoteLoggerService.error(msg, screen: 'x', error: e);
RemoteLoggerService.warning(msg, screen: 'x');
RemoteLoggerService.userAction(action, screen: 'x', details: {...});

// Domain-spesifik
RemoteLoggerService.auth(event, method: 'email|google|apple', errorMsg: '...');
RemoteLoggerService.book(event, bookId: '...', bookTitle: '...', screen: '...', details: {...});
RemoteLoggerService.focus(event, bookTitle: '...', durationMinutes: N, pagesRead: N, xpEarned: N);
RemoteLoggerService.challenge(event, challengeId: '...', challengeTitle: '...', challengeType: '...');
RemoteLoggerService.social(event, details: {...});
RemoteLoggerService.profile(event, details: {...});
```

### Yeni Özellik Eklerken

1. Cubit'e `import '../../../core/services/remote_logger_service.dart';` ekle
2. Kullanıcı aksiyonu başarılı olduktan sonra ilgili log metodunu çağır
3. Hata durumlarında `RemoteLoggerService.error()` ile logla
4. Yeni domain kategorisi gerekiyorsa `remote_logger_service.dart`'a yeni statik metod ekle

### Grafana Sorgu Örnekleri

```logql
{app="reado"}                              # Tüm loglar
{app="reado", level="error"}               # Sadece hatalar
{app="reado"} |= "Book added"             # Kitap ekleme logları
{app="reado", user_id="abc123"}            # Belirli kullanıcı
```

### Loglanan Aksiyonlar

| Kategori | Aksiyonlar |
|----------|-----------|
| Auth | register, sign_in (email/google/apple), sign_out, register_failed, sign_in_failed |
| Book | search, add_to_library, manual_add, cover_scan, page_update, mark_finished, mark_reading, remove, total_pages_update |
| Focus | session_start, session_pause, session_resume, session_complete |
| Challenge | join, leave, create |
| Social | friend_request_sent, friend_request_accepted, friend_removed |
| Profile | daily_goal_update, calm_mode_enable, calm_mode_disable |
| Reader Profile | profile_generated |
| App | app_started |

> Son güncelleme: 17 Mart 2026

---

## Brain MCP — Obsidian Cache Sistemi

Session'lar arası bilgi kaybını önlemek için Obsidian vault'u kalıcı cache olarak kullanılır.
Brain MCP (mcp__brain__*) araçlarıyla erişilir.

```
Vault Konumu: Obsidian → knowledge/reado/
Proje Tag'i: project: reado
```

### Kurallar

0. **Her İşlem Sonrası Checkpoint** — Her görev/işlem tamamlandığında (bug fix, feature,
   refactor vb.) otomatik olarak Brain MCP'ye checkpoint kaydet. Kullanıcının hatırlatmasını
   bekleme. Bu kural her zaman geçerlidir.

1. **Session Sonu Catchup** — Her session sonunda (veya büyük bir iş tamamlandığında)
   yapılan işlerin özetini `knowledge/reado/sessions/` altına kaydet:
   - Dosya adı: `YYYY-MM-DD-kisa-baslik.md`
   - İçerik: ne yapıldı, hangi dosyalar değişti, kalan işler, kararlar
   - Tags: `[session, catchup]`

2. **Mimari Kararlar** — Önemli teknik kararları `knowledge/reado/decisions/` altına kaydet:
   - Neden bu yaklaşım seçildi, alternatifler neydi
   - Tags: `[decision, architecture]`

3. **Pattern & Snippet** — Tekrar kullanılan pattern'leri `knowledge/reado/patterns/` altına kaydet:
   - Tags: `[pattern, flutter]` veya `[pattern, firebase]`

4. **Bug & Fix** — Karşılaşılan önemli bugları `knowledge/reado/bugs/` altına kaydet:
   - Semptom, root cause, çözüm
   - Tags: `[bug, fix]`

### Klasör Yapısı

```
knowledge/reado/
├── sessions/          # session catchup notları
├── decisions/         # mimari kararlar
├── patterns/          # tekrar kullanılan pattern'ler
└── bugs/              # karşılaşılan bug ve çözümler
```

### Kullanım

```
# Session başında — önceki session'ları oku
mcp__brain__list_notes(folder: "knowledge/reado/sessions")
mcp__brain__search_notes(query: "...", project: "reado")

# Session sonunda — catchup kaydet
mcp__brain__create_note(
  path: "knowledge/reado/sessions/2026-03-18-feature-xyz.md",
  title: "Session: Feature XYZ",
  content: "...",
  tags: ["session", "catchup"],
  project: "reado",
  source: "session"
)
```

### Session Başlangıç Protokolü

Her yeni session'da:
1. `mcp__brain__list_notes(folder: "knowledge/reado/sessions")` ile son session'ları kontrol et
2. İlgili notları oku, context'i yakala
3. CLAUDE.md ile Obsidian notları arasında tutarsızlık varsa CLAUDE.md'yi güncelle

### CLAUDE.md ↔ Obsidian Senkronizasyonu

- CLAUDE.md: Kurallar, yapı, standartlar (her session otomatik okunur)
- Obsidian: Detaylı session geçmişi, kararlar, pattern'ler (ihtiyaç halinde okunur)
- İkisi birbirini tamamlar — CLAUDE.md özet, Obsidian detay
- Büyük bir karar veya yapısal değişiklik olduğunda her ikisi de güncellenir