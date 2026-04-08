# Bookpulse Raspberry Pi Backend Service

## Ne Yapar?

Raspberry Pi uzerinde surekli calisan bir Python servisi. Firebase Firestore'dan challenge, streak ve kullanici verilerini okur; zamanlama tabanli FCM push bildirimleri gonderir.

Flutter tarafindaki local notification sistemiyle **birlikte calisir** (ikisi birbirini tamamlar):
- **Flutter (local)**: Kullanici challenge'a katildiginda aninda planlanan bildirimler
- **Raspi (server)**: Tum kullanicilar icin merkezi zamanlamali bildirimler (uygulama kapali olsa bile)

---

## Mimari

```
raspiBackend.py
    |
    +-- Firebase Admin SDK (Firestore + FCM)
    |
    +-- schedule (Python cron-like library)
    |
    +-- Jobs:
        +-- 10:00 UTC  -> job_challenge_last_day_reminders
        +-- 10:00 UTC  -> job_challenge_midpoint_reminders
        +-- 20:00 UTC  -> job_streak_risk_reminders
        +-- Her 6 saat -> job_health_check
```

### Veri Akisi

```
Firestore                       raspiBackend.py               FCM               Kullanici
--------                        ---------------               ---               ---------
challenges/{id}  ------------->  Yarin biten challenge'lari   ---> push notif --> telefon
  + /participants/{uid}          filtrele, kullanicilarin
                                 FCM token'ini al
users/{uid}      ------------->  streakDays > 0 ve bugun
  .streakDays                    okumamis kullanicilari bul   ---> push notif --> telefon
  .lastReadDate
  .fcmToken
  .notificationPrefs  -------->  Bildirim tercihlerini kontrol et
                                 (enabled, challengeNotifications, streakReminder)
```

---

## Mevcut Job'lar

| Job | Zamanlama | Aciklama |
|-----|-----------|----------|
| `job_challenge_last_day_reminders` | Her gun 10:00 UTC | Yarin biten challenge'lar icin katilimcilara FCM gonderir |
| `job_challenge_midpoint_reminders` | Her gun 10:00 UTC | 7+ gunluk challenge'larin yari noktasinda bildirim gonderir |
| `job_streak_risk_reminders` | Her gun 20:00 UTC | Bugun okumamis streak'li kullanicilara uyari gonderir |
| `job_health_check` | Her 6 saat | Servisin calistigini loglar |

### Challenge Bildirim Mantigi

Her bildirim gondermeden once su kontroller yapilir:
1. Kullanicinin `fcmToken`'i var mi?
2. `notificationPrefs.enabled` true mi?
3. `notificationPrefs.challengeNotifications` (veya `streakReminder`) true mi?

Challenge tiplerine gore bildirim icerigi degisir:
- **pages / readAlong**: Sayfa hedefi iceren mesaj
- **sprint**: "Her dakika onemli" tarzi motive edici mesaj
- **genre**: Kitap bitirme odakli mesaj

---

## Kurulum

### 1. Gereksinimler

```bash
# Python 3.10+ gerekli
python3 --version

# Virtual environment olustur
cd /home/pi/bookpulse/admin
python3 -m venv venv
source venv/bin/activate

# Bagimliliklar
pip install firebase-admin schedule
```

### 2. Firebase Credential

`bookpulseapp-firebase-adminsdk-fbsvc-6c8ae79c7c.json` dosyasi `admin/` klasorunde olmali.
Alternatif olarak environment variable ile path verebilirsin:

```bash
export BOOKPULSE_FIREBASE_CRED="/path/to/credential.json"
```

### 3. Test Calistirma

```bash
cd /home/pi/bookpulse/admin
source venv/bin/activate
python3 raspiBackend.py
```

Ciktida su satirlari gormelisin:
```
Bookpulse Backend Service starting...
Schedule configured: 4 jobs
Health check OK
```

### 4. systemd Servisi (Surekli Calisma)

```bash
sudo nano /etc/systemd/system/bookpulse-backend.service
```

Icerik:
```ini
[Unit]
Description=Bookpulse Backend Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/bookpulse/admin
ExecStart=/home/pi/bookpulse/admin/venv/bin/python3 /home/pi/bookpulse/admin/raspiBackend.py
Restart=always
RestartSec=30
Environment=BOOKPULSE_LOG_LEVEL=INFO

# Guvenlik
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/home/pi/bookpulse/admin

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable bookpulse-backend
sudo systemctl start bookpulse-backend

# Durum kontrol
sudo systemctl status bookpulse-backend

# Loglar
journalctl -u bookpulse-backend -f
```

---

## Environment Variables

| Degisken | Varsayilan | Aciklama |
|----------|-----------|----------|
| `BOOKPULSE_FIREBASE_CRED` | `./bookpulseapp-firebase-adminsdk-*.json` | Firebase credential dosya yolu |
| `BOOKPULSE_LOG_LEVEL` | `INFO` | Log seviyesi: DEBUG, INFO, WARNING, ERROR |

---

## Yeni Job Ekleme Rehberi

Yeni bir zamanli gorev eklemek icin:

### 1. Job Fonksiyonu Yaz

```python
def job_yeni_gorev():
    """Aciklama."""
    logger.info("Running: yeni_gorev")
    try:
        # Firestore'dan veri oku
        # FCM gonder (send_fcm helper'ini kullan)
        # Bildirim tercihlerini kontrol et!
        pass
    except Exception as e:
        logger.error("yeni_gorev failed: %s", e)
```

### 2. Schedule'a Ekle

```python
def setup_schedule():
    # ... mevcut job'lar ...
    schedule.every().day.at("14:00").do(job_yeni_gorev)
```

### 3. Bildirim Tercihi Kontrolu (ZORUNLU)

Eger FCM gonderiyorsan, kullanicinin tercihlerini kontrol et:

```python
prefs = user_data.get("notificationPrefs", {})
if not prefs.get("enabled", True):
    continue
if not prefs.get("challengeNotifications", True):  # veya ilgili alan
    continue
```

### 4. Bu Dokumani Guncelle

Yeni job'u "Mevcut Job'lar" tablosuna ekle.

---

## Potansiyel Gelecek Job'lar

| Job Fikri | Aciklama | Oncelik |
|-----------|----------|---------|
| `job_weekly_report` | Pazar aksami haftalik okuma ozeti FCM | Dusuk |
| `job_league_results` | Haftalik lig sonuclari bildirimi | Orta |
| `job_inactive_user_nudge` | 3+ gun okumamis kullanicilara yumusak hatirlatma | Dusuk |
| `job_challenge_ranking_update` | Siralamada dusus oldugunda bildirim | Orta |
| `job_daily_goal_reminder` | Okuma saati gelmeden 10dk once FCM (server-side) | Yuksek |
| `job_cleanup_expired_challenges` | Bitmis challenge'lari arsivle | Dusuk |

---

## Troubleshooting

### Servis baslamiyor
```bash
journalctl -u bookpulse-backend -n 50 --no-pager
```
- Credential dosyasi dogru yolda mi?
- Python venv aktif mi? (systemd ExecStart yolunu kontrol et)
- Network erisimi var mi? (`ping google.com`)

### FCM gonderimiyor
- Kullanicinin `fcmToken`'i guncel mi? (Uygulama acildiginda guncellenir)
- `UnregisteredError` aliyorsan token expired — kullanici uygulamayi tekrar acmali
- Firebase proje ID dogru mu?

### Schedule calismasi beklenen saatte olmuyor
- Raspi'nin saat dilimi kontrol: `timedatectl`
- Job'lar UTC'ye gore calisir, yerel saat degil
- `schedule` kutuphanesi sistem saatine bagli

### Bellek/CPU endisesi
- `schedule` hafif bir kutuphane, 30 saniyelik sleep loop ile calisir
- Her job fire-and-forget, paralel calismaz
- Firestore stream'leri kullanildiktan sonra otomatik kapanir
