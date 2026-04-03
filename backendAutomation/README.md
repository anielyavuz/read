# BookPulse Backend Automation — Raspberry Pi Kurulum Rehberi

Bu klasor, BookPulse bildirim sistemini Raspberry Pi uzerinde calistirmak icin bagimsiz Node.js scriptlerini icerir. Firebase Cloud Functions yerine `firebase-admin` ve `node-cron` kullanir.

---

## Gereksinimler

- **Node.js 18+** (LTS surumu oneriliyor)
- **npm** (Node.js ile birlikte gelir)
- **Firebase projesi** ve service account JSON dosyasi

---

## Firebase Service Account JSON Indirme

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Projenizi secin (BookPulse)
3. Sol menuden **Proje Ayarlari** (dis simgesi) > **Hizmet hesaplari** sekmesine gidin
4. **"Yeni ozel anahtar olustur"** butonuna tiklayin
5. Indirilen JSON dosyasini `serviceAccountKey.json` olarak yeniden adlandirin
6. Bu dosyayi `backendAutomation/` klasorune kopyalayin

> **UYARI:** `serviceAccountKey.json` dosyasini ASLA git'e commit etmeyin! Bu dosya `.gitignore`'a eklenmistir.

---

## Kurulum

```bash
# Proje klasorune gidin
cd backendAutomation/

# Bagimliliklari yukleyin
npm install

# Service account dosyasini kopyalayin (yukarida indirdiginiz dosya)
cp /indirme/yolu/serviceAccountKey.json ./serviceAccountKey.json
```

---

## Calistirma

### Dogrudan calistirma (test icin)

```bash
node index.js
# veya
npm start
```

### pm2 ile arka planda calistirma (onerilen)

pm2, Node.js uygulamalarini arka planda calistirir, hata durumunda otomatik yeniden baslatir ve loglamayi yonetir.

```bash
# pm2'yi global olarak yukleyin
sudo npm install -g pm2

# Uygulamayi baslatin
pm2 start index.js --name "bookpulse-notifications"

# Durumu kontrol edin
pm2 status

# Loglari izleyin
pm2 logs bookpulse-notifications

# Durdurun
pm2 stop bookpulse-notifications

# Yeniden baslatin
pm2 restart bookpulse-notifications
```

### Sistem baslangicinda otomatik baslatma

Raspberry Pi yeniden basladiginda pm2'nin otomatik calismasini saglayin:

```bash
# pm2 startup scriptini olusturun
pm2 startup

# Yukaridaki komut bir sudo komutu verecek, onu kopyalayip calistirin
# Ornegin: sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u pi --hp /home/pi

# Mevcut pm2 sureclerini kaydedin
pm2 save
```

---

## Zamanlanmis Gorevler

| Gorev | Cron Ifadesi | Zamanlama | Aciklama |
|-------|-------------|-----------|----------|
| Daily Reading Reminder | `0 6-22 * * *` | Her saat, 06:00 - 22:00 arasi | Kullanicinin hafta ici/sonu okuma saatine gore 10 dk onceden bildirim gonderir |
| Streak Risk Check | `0 20 * * *` | Her gun 20:00 | Aktif streak'i olan ama bugun okumamis kullanicilara uyari gonderir |
| Weekly Report | `0 19 * * 0` | Her Pazar 19:00 | Haftalik ozet: XP, streak, tahmini sayfa sayisi |

> **Onemli:** Tum zamanlar sunucu yerel saatine (Raspberry Pi) goredir. Sunucunun saat dilimini dogru ayarlayin.

---

## Quiet Hours (Sessiz Saatler)

Bildirimler **23:00 - 07:00** arasi gonderilmez. Bu kural `dailyReminder.js` icerisinde uygulanir. Cron yalnizca 06:00-22:00 arasi calisir, ancak ek guvenlik olarak quiet hours kontrolu de kod icerisinde yapilir.

---

## Firestore Veri Yapisi: NotificationPreferences

Kullanici bildirim tercihleri Firestore'da `users/{userId}` dokumani icerisinde `notificationPrefs` alaninda saklanir:

```
users/{userId}
  notificationPrefs: {
    enabled: boolean          // Bildirimlerin tamamen acik/kapali olmasi
    weekdayTime: "21:00"      // Hafta ici okuma saati (HH:MM, sunucu yerel saati)
    weekendTime: "10:00"      // Hafta sonu okuma saati (HH:MM, sunucu yerel saati)
    readingDurationGoal: 30   // Dakika cinsinden okuma hedefi (15/30/45/60)
    streakReminder: boolean   // Streak risk uyarilari acik/kapali
    weeklyReport: boolean     // Haftalik ozet bildirimi acik/kapali
  }
  fcmToken: string            // FCM device token (bildirim gondermek icin gerekli)
  displayName: string         // Kullanici adi (bildirim mesajlarinda kullanilir)
  streakDays: number          // Mevcut streak gun sayisi
  lastReadDate: Timestamp     // Son okuma tarihi
  xpThisWeek: number          // Bu hafta kazanilan XP
  companionBreed: string      // Maskot irki (opsiyonel, ornegin: "golden_retriever")
  companionName: string       // Maskot adi (opsiyonel, ornegin: "Buddy")
```

### Bildirim Turleri ve Tetiklenme Kosullari

1. **Daily Reading Reminder** (`dailyReminder.js`)
   - `notificationPrefs.enabled == true` olmali
   - Hafta ici: `weekdayTime`'a gore, hafta sonu: `weekendTime`'a gore
   - Okuma saatinden 10 dk once gonderilir
   - Bugun zaten okumus kullanicilar atlanir
   - Quiet hours icerisinde gonderilmez

2. **Streak Risk Check** (`streakCheck.js`)
   - `notificationPrefs.enabled == true` VE `notificationPrefs.streakReminder == true` olmali
   - `streakDays > 0` VE `lastReadDate` bugun degil ise gonderilir
   - Her gun 20:00'da calisir

3. **Weekly Report** (`weeklyReport.js`)
   - `notificationPrefs.enabled == true` VE `notificationPrefs.weeklyReport == true` olmali
   - Her Pazar 19:00'da calisir
   - `xpThisWeek`, `streakDays` ve tahmini sayfa sayisi icerir
   - Bu hafta hic aktivitesi olmayan kullanicilar atlanir
   - **Not:** `xpThisWeek` sifirlanmasi ayri bir zamanlanmis gorev ile yapilmalidir (ornegin Pazartesi 00:00)

---

## Dosya Yapisi

```
backendAutomation/
├── index.js                          # Ana giris noktasi, cron zamanlayici
├── package.json                      # Bagimliliklar
├── .gitignore                        # node_modules ve serviceAccountKey.json
├── serviceAccountKey.json            # Firebase service account (GIT'E EKLEME!)
├── README.md                         # Bu dosya
└── notifications/
    ├── dailyReminder.js              # Gunluk okuma hatirlatma (hafta ici/sonu destegi)
    ├── streakCheck.js                # Streak risk kontrol mantigi
    ├── weeklyReport.js               # Haftalik ozet raporu
    ├── sendNotification.js           # FCM bildirim gonderme
    └── messageTemplates.js           # Irk bazli + genel bildirim sablonlari
```

---

## Log Dosyalari

### Dogrudan calistirmada
Loglar terminale yazilir. Dosyaya yonlendirmek icin:

```bash
node index.js >> /var/log/bookpulse-notifications.log 2>&1
```

### pm2 ile
pm2 loglari otomatik olarak yonetir:

```bash
# Tum loglari gorun
pm2 logs bookpulse-notifications

# Son 100 satir
pm2 logs bookpulse-notifications --lines 100

# Log dosyalarinin konumu
# ~/.pm2/logs/bookpulse-notifications-out.log  (stdout)
# ~/.pm2/logs/bookpulse-notifications-error.log (stderr)

# Loglari temizleyin
pm2 flush bookpulse-notifications
```

---

## Sorun Giderme

### "Error: Cannot find module './serviceAccountKey.json'"
`serviceAccountKey.json` dosyasini `backendAutomation/` klasorune kopyaladiginizdan emin olun.

### "Error: The default Firebase app does not exist"
`index.js` dosyasinin `firebase-admin`'i dogru sekilde baslattigini kontrol edin.

### Bildirimler gonderilmiyor
- Firestore'da kullanicilarin `fcmToken` alaninin dolu oldugunu kontrol edin
- Firestore'da `notificationPrefs` alaninin dogru ayarlandigini dogrulayin
- `notificationPrefs.enabled` alaninin `true` oldugunu kontrol edin
- pm2 loglarini kontrol edin: `pm2 logs bookpulse-notifications`

### Yanlis saatte bildirim geliyor
- Raspberry Pi'nin saat dilimini kontrol edin: `timedatectl`
- Tum zamanlar sunucu yerel saatine goredir
- Saat dilimini degistirmek icin: `sudo timedatectl set-timezone Europe/Istanbul`
