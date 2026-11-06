# FrogPop: Bubble Quest - Final Rapor (Türkçe)

Paket `com.poyraz.frogpop` - Poyraz Yazılım - Godot 4.7.2 (GDScript, Mobile renderer, dikey 1080x1920) - 6 Kas 2026

## Tamamlananlar (PHASE 1-9 + §5-§8)
- **Oyun:** Saf GDScript simülasyon çekirdeği (sabit 1/120 s): yay-uzunluğu tabanlı zincir, itici ön / boşlukta duran ön parça, mıknatıs geri çekilme + zincir reaksiyonu, sürekli ışın çarpışması (tünelleme yok), 7 güçlendirici, taş/bomba/altın balon, skor-combo-perfect-last-second-streak kuralları, sonsuz dalgalar (hız 62→152, uzunluk 28→82, renk 4→8, her 10. dalga boss), 9 parametrik rota ailesi (doğrulamalı: eğrilik, çakışma, kurbağa mesafesi, erişilebilirlik), 4 mod (Klasik, Zamana Karşı, Zen, Günlük).
- **Görsel/ses:** Özgün katmanlı kurbağa maskotu (12 animasyon, göz takibi, 5 kostüm + klasik), parlak balon sanatı (renk körü sembolleri), havuzlu parçacıklar, patlama/şok dalgası/ekran sarsıntısı/zoom, 10 dünya x 3 arka plan (JSON veri + prosedürel katmanlar + ortam parçacıkları + dünya geçişi), sentezlenmiş özgün SFX ve 10 dünya müziği, shader'lar (balon, gökkuşağı, gradyan gökyüzü, vinyet).
- **İlerleme/UI:** Menü, mod seçimi, mağaza (kostüm/dünya/güç), PRO ekranı, günlük ödül (saat geri alma koruması), günlük+haftalık görev, 20 başarım, istatistik, ayarlar (ses/titreşim/kalite/dil/sembol), duraklatma, game over (rekor, devam=ödüllü reklam, çift tık tuzağı yok). TR/EN (CSV), güvenli alan + her en-boy oranı.
- **Kayıt:** JSON + sağlama toplamı + atomik yazma + yedekten kurtarma + doğrulama/kırpma; bozuk dosyada varsayılana düşer.
- **Para kazanma:** Ads/Purchase servis katmanı (eklenti algılama, kurallar: oyun ortasında asla, ilk 3 oyun yok, sıklık/oturum sınırı, PRO'da yok); eklenti yoksa "kullanılamıyor" (sahte satın alma yok; "TEST REKLAMI" yalnız debug).
- **Yayın hazırlığı:** README, LICENSE (tescilli), PRIVACY_POLICY (TR+EN), TERMS_OF_SERVICE, THIRD_PARTY_NOTICES, docs/{MONETIZATION,DATA_SAFETY,APP_PRIVACY,RELEASE,STORE_LISTING,BLOCKERS,ARCHITECTURE}.md, `site/` (tanıtım + gizlilik + şartlar, göreli linkler, CNAME.example) ve `.github/workflows/pages.yml`. **Yayınlanmadı** (push/Pages/YouTube yok).
- **Mağaza varlıkları:** logo, ikon (1024/512, Android adaptive, iOS ikon seti), splash, feature graphic 1024x500, mascot; 6 gerçek oyun ekran görüntüsü x TR/EN (`store/screenshots/`).
- **Videolar** (`store/video/`, oyunun kendisinden): `frogpop_trailer_16x9_{tr,en}.mp4` 1920x1080 60fps 70,5 sn; `frogpop_short_9x16_{tr,en}.mp4` 1080x1920 60fps 36,7 sn (döngüsel son); 2 küçük resim 1280x720; `youtube_metadata.md` (TR/EN başlık, açıklama, etiket, bölümler). QC: ffprobe, blackdetect (0 siyah), -14.7/-15.0 LUFS, kareler gözle kontrol edildi.

## Test sonuçları
- `tests/test_runner.tscn`: **7238 kontrol geçti, 0 başarısız** (~29 sn): rota tipleri/süreklilik/geçerlilik (9 tip x çok tohum, yedek rotaya düşmeme), zincir fiziği (ekleme, patlama, boşluk, mıknatıs, taş, bomba), tüm oyun kuralları + 7 güçlendirici, zorluk eğrisi monoton+sınırlı (2000 dalga), 1000 dalga rota/parametre + bot stres (invariant ihlali yok), dünya sırası (art arda aynı yok), kayıt/yedek/bozuk/oynanmış dosya, günlük ödül + saat geri alma, PRO, reklam kuralları, sahte satın alma yok, yerelleştirme eksiksizliği (TR+EN, yer tutucular), ses dosyaları, her ekran 4 en-boy oranında taşma yok, her mod bot ile otomatik oynanıp bitiyor, 6 kostümde 12 animasyon, performans (ort. 0,37 ms/kare script), bellek/pool sınırı.
- Denge (greedy bot, beceri 0,92, 10 tohum): dalga 1: 10/10, 10: 9/10, 30: 8/10, 60: 8/10, 100: 9/10, 150: 9/10, 300: 10/10, 1000: 9/10 - kazanılabilir/adil.

## Platform durumu
- **Android:** İmzalı release APK + AAB (CN=Poyraz Yazilim, C=TR; apksigner v2/v3 + jarsigner doğrulandı) ve debug APK `build/android/`. Anahtarlar `~/Documents/frogpop-keys/` (repo dışı). Emülatörde (geçici gl_compat APK) açıldı, oynandı, kayıt kalıcılığı doğrulandı: `store/emulator_*.png`.
- **iOS:** Export denendi -> `build/ios/FrogPop.xcodeproj` üretildi; imzasız cihaz derlemesi (xcodebuild iphoneos) BAŞARILI. IPA imzası için Apple Team ID gerekli (placeholder).
- **AdMob / IAP:** Servis katmanı + kurallar + yapılandırma hazır, Google TEST id'leri `data/config/monetization.json`; yerel eklentiler dahil DEĞİL (kurulum `docs/MONETIZATION.md`). Eklentisiz derlemede reklam/satın alma "kullanılamıyor".

## Bilinen eksikler
- Gerçek reklam/satın alma ve sunucu doğrulaması yok (bilinçli; sahte yok). Çevrim içi liderlik tablosu yok.
- Mobile (Vulkan) renderer gerçek cihazda denenmedi; emülatör gl_compat ile test edildi.
- Seslendirme/Gemini/Flow kullanılmadı (video: oyun görüntüsü + özgün müzik).
- Android'de debug/release APK'lar 35-37 MB (şablon dahil).

## Sahipten gerekenler
1. `gh auth login` -> repo `frogpop-bubble-quest` oluştur + push, Pages kaynağı "GitHub Actions" (docs/RELEASE.md); gizlilik URL'si: https://omer-poyraz.github.io/frogpop-bubble-quest/privacy-policy/ (yayın doğrulanmadan "yayında" denmemeli).
2. AdMob hesabı + eklenti + gerçek id'ler; Play/App Store ürünleri (`frogpop_pro_monthly/yearly/lifetime`, `frogpop_remove_ads`).
3. Apple Developer Team ID; Play Console listeleme (metinler `docs/STORE_LISTING.md`), keystore yedeği.
4. Videoları YouTube'a yükleme (`store/video/`).
