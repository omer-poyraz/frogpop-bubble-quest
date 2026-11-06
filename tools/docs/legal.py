#!/usr/bin/env python3
"""Generates PRIVACY_POLICY.md, TERMS_OF_SERVICE.md and the site/ legal pages from one source."""
import os, html
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
DATE = "2026-11-06"
CONTACT = "Poyraz Yazılım - omerr.poyrazz@gmail.com"
URL = "https://omer-poyraz.github.io/frogpop-bubble-quest/"

PRIVACY = {
"en": ("Privacy Policy", f"Effective date: {DATE}", [
 ("1. Who we are", ["FrogPop: Bubble Quest (\"the game\", package com.poyraz.frogpop) is published by Poyraz Yazılım (\"we\"). Contact: omerr.poyrazz@gmail.com."]),
 ("2. Short version", ["The game works fully offline. We run no servers, no accounts and no analytics. Your progress stays on your device. The only third-party data processing happens through the advertising and billing services of Google/Apple described below, and only in builds that include them."]),
 ("3. Data stored on your device", ["The game stores a small save file in the app's private storage: high score, total score, games played, play time, coins, unlocked costumes and worlds, achievements, daily-reward dates, settings (volume, vibration, quality, language), power-up counts and PRO status.", "This file never leaves your device through our code. We cannot see it. It is removed when you use Settings > Delete my progress or uninstall the game. A rolling local backup copy is kept next to it for crash recovery."]),
 ("4. Advertising (Google AdMob)", ["Free players may see ads served by Google AdMob (interstitial ads between games and optional rewarded ads). AdMob is operated by Google LLC and may collect and process, as a separate controller/processor under Google's own terms: the advertising ID, IP address, device and OS information, app and ad interaction data and approximate location derived from the IP address, in order to serve and measure ads, prevent fraud and (where permitted) personalize ads.", "In the European Economic Area, the United Kingdom and similar regions the game shows Google's consent message before personalised ads. You can reset your advertising ID or opt out of ad personalisation in your device settings (Android: Settings > Privacy > Ads; iOS: Settings > Privacy & Security > Tracking / Apple Advertising).", "More information: https://policies.google.com/technologies/ads and https://support.google.com/admob/answer/6128543.", "Note about builds: the open project files do not bundle the AdMob SDK. In a build without the SDK no ad is shown and no advertising data is processed. PRO users and users who removed ads see no ads."]),
 ("5. Purchases (PRO, remove ads)", ["Purchases and subscriptions are processed by Google Play or the Apple App Store. We never receive your payment card or account details. The game only stores locally whether PRO / ad-free is active. Because the game has no server, purchases are not verified by a server of ours. Subscriptions are managed and cancelled in your store account settings; restoring purchases is done through the store."]),
 ("6. Children", ["The game is aimed at a general audience of players aged 13 and older and is not directed to children. We do not knowingly collect personal information from children. Ad requests are configured with child-directed tags disabled because the game is not child-directed; if you believe a child under 13 has used the game, contact us and use your device's parental controls or ad-personalisation settings."]),
 ("7. Third-party services", ["Google AdMob (ads) - Google LLC. Google Play Billing (Android purchases) - Google LLC. App Store In-App Purchase (iOS purchases) - Apple Inc. The game engine (Godot, MIT license) does not transmit data. No other third-party SDKs are used."]),
 ("8. Data deletion and your rights", ["Because we hold no personal data about you on any server, there is nothing for us to export or erase remotely. You can delete all local data at any time: Settings > Delete my progress, or uninstall the game. To manage data held by Google or Apple (advertising ID, purchase history), use their privacy controls. Residents of the EEA/UK (GDPR) and Türkiye (KVKK) may contact us with any question or request at the address below and we will answer within 30 days."]),
 ("9. Security", ["The save file is stored in the app sandbox, protected by the operating system, with an integrity checksum against corruption. No transmission of this file occurs."]),
 ("10. Changes", ["If the way the game processes data changes (for example when an SDK is added), we will update this page and the effective date before releasing that version."]),
 ("11. Contact", [CONTACT]),
]),
"tr": ("Gizlilik Politikası", f"Yürürlük tarihi: {DATE}", [
 ("1. Biz kimiz", ["FrogPop: Bubble Quest (\"oyun\", paket adı com.poyraz.frogpop) Poyraz Yazılım (\"biz\") tarafından yayımlanır. İletişim: omerr.poyrazz@gmail.com."]),
 ("2. Kısa özet", ["Oyun tamamen çevrim dışı çalışır. Sunucu, hesap ve analitik kullanmayız. İlerlemen cihazında kalır. Üçüncü taraf veri işleme yalnızca aşağıda anlatılan Google/Apple reklam ve ödeme hizmetleri üzerinden ve yalnızca bunları içeren sürümlerde gerçekleşir."]),
 ("3. Cihazında saklanan veriler", ["Oyun, uygulamanın özel depolama alanında küçük bir kayıt dosyası tutar: rekor, toplam puan, oynanan oyun sayısı, oyun süresi, altın, açılan kostüm ve dünyalar, başarımlar, günlük ödül tarihleri, ayarlar (ses, titreşim, kalite, dil), güçlendirici adetleri ve PRO durumu.", "Bu dosya bizim kodumuz aracılığıyla cihazından hiçbir zaman çıkmaz; biz göremeyiz. Ayarlar > İlerlememi sil seçeneğiyle veya oyunu kaldırarak silinir. Çökme durumunda kurtarma için yanında yerel bir yedek kopya tutulur."]),
 ("4. Reklamlar (Google AdMob)", ["Ücretsiz oyuncular Google AdMob tarafından sunulan reklamlar görebilir (oyunlar arası geçiş reklamları ve isteğe bağlı ödüllü reklamlar). AdMob, Google LLC tarafından işletilir ve Google'ın kendi şartları kapsamında ayrı bir veri sorumlusu/işleyicisi olarak şunları toplayıp işleyebilir: reklam kimliği, IP adresi, cihaz ve işletim sistemi bilgisi, uygulama ve reklam etkileşim verileri ve IP'den türetilen yaklaşık konum. Amaç reklam sunmak, ölçmek, kötüye kullanımı önlemek ve (izin verilen yerlerde) reklamları kişiselleştirmektir.", "Avrupa Ekonomik Alanı, Birleşik Krallık ve benzeri bölgelerde oyun, kişiselleştirilmiş reklamlardan önce Google'ın onay mesajını gösterir. Reklam kimliğini sıfırlayabilir veya reklam kişiselleştirmeyi cihaz ayarlarından kapatabilirsin (Android: Ayarlar > Gizlilik > Reklamlar; iOS: Ayarlar > Gizlilik ve Güvenlik > İzleme / Apple Reklamcılığı).", "Daha fazla bilgi: https://policies.google.com/technologies/ads ve https://support.google.com/admob/answer/6128543.", "Sürümler hakkında not: açık proje dosyaları AdMob SDK'sını içermez. SDK'sız bir sürümde reklam gösterilmez ve reklam verisi işlenmez. PRO kullanıcılar ve reklamları kaldıranlar reklam görmez."]),
 ("5. Satın almalar (PRO, reklamları kaldır)", ["Satın alma ve abonelikler Google Play veya Apple App Store tarafından işlenir. Kart veya hesap bilgilerini hiçbir zaman almayız. Oyun yalnızca PRO/reklamsız durumunun etkin olup olmadığını yerel olarak saklar. Oyunun sunucusu olmadığı için satın almalar tarafımızca bir sunucuda doğrulanmaz. Abonelikler mağaza hesap ayarlarından yönetilir ve iptal edilir; satın almaları geri yükleme mağaza üzerinden yapılır."]),
 ("6. Çocuklar", ["Oyun 13 yaş ve üzeri genel kitleye yöneliktir, çocuklara yönelik değildir. Çocuklardan bilerek kişisel veri toplamayız. Oyun çocuklara yönelik olmadığı için reklam isteklerinde çocuk odaklı etiketler kapalı yapılandırılır; 13 yaş altı bir çocuğun oyunu kullandığını düşünüyorsan bizimle iletişime geç ve cihazının ebeveyn denetimlerini/reklam kişiselleştirme ayarlarını kullan."]),
 ("7. Üçüncü taraf hizmetler", ["Google AdMob (reklam) - Google LLC. Google Play Faturalandırma (Android satın alma) - Google LLC. App Store Uygulama İçi Satın Alma (iOS) - Apple Inc. Oyun motoru (Godot, MIT lisansı) veri göndermez. Başka üçüncü taraf SDK kullanılmaz."]),
 ("8. Veri silme ve haklarınız", ["Hiçbir sunucuda sana ait kişisel veri tutmadığımız için uzaktan dışa aktaracak veya silecek bir şey yoktur. Tüm yerel verileri her zaman silebilirsin: Ayarlar > İlerlememi sil veya oyunu kaldır. Google veya Apple'ın tuttuğu veriler (reklam kimliği, satın alma geçmişi) için onların gizlilik denetimlerini kullan. AEA/BK (GDPR) ve Türkiye (KVKK) kullanıcıları her soru veya talep için aşağıdaki adrese yazabilir; 30 gün içinde yanıtlarız."]),
 ("9. Güvenlik", ["Kayıt dosyası uygulama kum havuzunda, işletim sistemi korumasıyla ve bozulmaya karşı bütünlük sağlama toplamıyla saklanır. Bu dosya hiçbir yere iletilmez."]),
 ("10. Değişiklikler", ["Oyunun veriyi işleme şekli değişirse (ör. bir SDK eklenirse) o sürüm yayımlanmadan önce bu sayfayı ve yürürlük tarihini güncelleriz."]),
 ("11. İletişim", [CONTACT]),
])}

TERMS = {
"en": ("Terms of Service", f"Effective date: {DATE}", [
 ("1. Agreement", ["By installing or playing FrogPop: Bubble Quest (\"the game\") you agree to these terms. The game is published by Poyraz Yazılım. If you do not agree, do not use the game."]),
 ("2. License", ["We grant you a personal, non-exclusive, non-transferable, revocable license to install and play the game on your own devices for non-commercial entertainment. You may not copy, modify, reverse engineer, redistribute, resell or use the game's artwork, audio or code except as allowed by law."]),
 ("3. Virtual items", ["Coins, costumes, worlds and power-ups are virtual items with no cash value. They cannot be exchanged for money, are not transferable and exist only on your device. Deleting the game or its data removes them; we cannot restore them."]),
 ("4. Purchases and subscriptions", ["PRO subscriptions (monthly, yearly), the lifetime PRO purchase and Remove Ads are processed by Google Play or the Apple App Store. Prices are shown by the store. Subscriptions renew automatically until cancelled in your store account at least 24 hours before the renewal date. Refunds are handled by the store under its policies. PRO benefits are listed on the PRO screen before purchase."]),
 ("5. Ads", ["Free users may see ads (interstitial between games, optional rewarded ads). Rewarded ads are always optional. PRO and ad-free users see no ads. Third-party ads are provided by Google AdMob; see the Privacy Policy."]),
 ("6. Fair play", ["There is no online leaderboard. Do not tamper with the game, its save data or your device clock to obtain rewards; such changes may be ignored or reset by the game."]),
 ("7. Disclaimer", ["The game is provided \"as is\" without warranties of any kind. We do not guarantee uninterrupted or error-free operation."]),
 ("8. Limitation of liability", ["To the maximum extent permitted by law, Poyraz Yazılım is not liable for indirect or consequential damages arising from use of the game."]),
 ("9. Changes", ["We may update these terms and the game. Continued use after an update means you accept the updated terms."]),
 ("10. Governing law", ["These terms are governed by the laws of the Republic of Türkiye, without prejudice to mandatory consumer-protection rules of your country of residence."]),
 ("11. Contact", [CONTACT]),
]),
"tr": ("Kullanım Şartları", f"Yürürlük tarihi: {DATE}", [
 ("1. Anlaşma", ["FrogPop: Bubble Quest'i (\"oyun\") yükleyerek veya oynayarak bu şartları kabul edersin. Oyun Poyraz Yazılım tarafından yayımlanır. Kabul etmiyorsan oyunu kullanma."]),
 ("2. Lisans", ["Sana, oyunu kendi cihazlarında ticari olmayan eğlence amacıyla yüklemen ve oynaman için kişisel, münhasır olmayan, devredilemez ve geri alınabilir bir lisans veriyoruz. Yasaların izin verdiği haller dışında oyunun kodunu, görsellerini veya seslerini kopyalayamaz, değiştiremez, tersine mühendislik yapamaz, dağıtamaz, satamaz veya kullanamazsın."]),
 ("3. Sanal öğeler", ["Altın, kostüm, dünya ve güçlendiriciler nakit değeri olmayan sanal öğelerdir. Paraya çevrilemez, devredilemez ve yalnızca cihazında bulunur. Oyunu veya verilerini silmek bunları kaldırır; geri yükleyemeyiz."]),
 ("4. Satın almalar ve abonelikler", ["PRO abonelikleri (aylık, yıllık), ömür boyu PRO ve Reklamları Kaldır, Google Play veya Apple App Store tarafından işlenir. Fiyatları mağaza gösterir. Abonelikler, yenileme tarihinden en az 24 saat önce mağaza hesabından iptal edilmedikçe otomatik yenilenir. İadeler mağazanın politikalarına göre mağaza tarafından yürütülür. PRO avantajları satın almadan önce PRO ekranında listelenir."]),
 ("5. Reklamlar", ["Ücretsiz kullanıcılar reklam görebilir (oyunlar arası geçiş reklamı, isteğe bağlı ödüllü reklam). Ödüllü reklamlar her zaman isteğe bağlıdır. PRO ve reklamsız kullanıcılar reklam görmez. Üçüncü taraf reklamlar Google AdMob tarafından sağlanır; Gizlilik Politikası'na bak."]),
 ("6. Adil oyun", ["Çevrim içi liderlik tablosu yoktur. Ödül elde etmek için oyunu, kayıt verilerini veya cihaz saatini değiştirme; bu tür değişiklikler oyun tarafından yok sayılabilir veya sıfırlanabilir."]),
 ("7. Sorumluluk reddi", ["Oyun \"olduğu gibi\" sunulur, hiçbir garanti verilmez. Kesintisiz veya hatasız çalışacağı garanti edilmez."]),
 ("8. Sorumluluğun sınırı", ["Yasaların izin verdiği azami ölçüde Poyraz Yazılım, oyunun kullanımından doğan dolaylı veya sonuç olarak ortaya çıkan zararlardan sorumlu değildir."]),
 ("9. Değişiklikler", ["Bu şartları ve oyunu güncelleyebiliriz. Güncellemeden sonra kullanmaya devam etmen güncel şartları kabul ettiğin anlamına gelir."]),
 ("10. Uygulanacak hukuk", ["Bu şartlar, ikamet ettiğin ülkenin emredici tüketici koruma kuralları saklı kalmak üzere Türkiye Cumhuriyeti hukukuna tabidir."]),
 ("11. İletişim", [CONTACT]),
])}

def md(doc):
    out = []
    for lang, title_hdr in (("en", "English"), ("tr", "Türkçe")):
        title, eff, secs = doc[lang]
        out.append(f"# {title} ({title_hdr})\n\n*{eff}*\n")
        for h, ps in secs:
            out.append(f"## {h}\n")
            for p in ps: out.append(p + "\n")
        out.append("\n---\n")
    return "\n".join(out)

def page(doc, name, other_link, other_name):
    def sec(lang):
        title, eff, secs = doc[lang]
        h = [f'<section lang="{lang}" id="{lang}"><h1>{html.escape(title)}</h1><p class="eff">{html.escape(eff)}</p>']
        for hh, ps in secs:
            h.append(f"<h2>{html.escape(hh)}</h2>")
            for p in ps:
                e = html.escape(p)
                import re
                e = re.sub(r"(https?://[^\s<]+?)([.,]?)(\s|$)", r'<a href="\1" rel="noopener">\1</a>\2\3', e)
                e = e.replace("omerr.poyrazz@gmail.com", '<a href="mailto:omerr.poyrazz@gmail.com">omerr.poyrazz@gmail.com</a>')
                h.append(f"<p>{e}</p>")
        h.append("</section>")
        return "\n".join(h)
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>FrogPop: Bubble Quest - {name}</title><meta name="robots" content="index,follow">
<link rel="icon" href="../assets/icon.png"><link rel="stylesheet" href="../style.css"></head>
<body class="legal"><header><a href="../" class="brand"><img src="../assets/icon.png" alt="FrogPop" width="44" height="44"><span>FrogPop: Bubble Quest</span></a>
<nav><a href="#en">English</a><a href="#tr">Türkçe</a><a href="../{other_link}/">{other_name}</a></nav></header>
<main>{sec('en')}<hr>{sec('tr')}</main>
<footer>&copy; 2026 Poyraz Yazılım &middot; <a href="../privacy-policy/">Privacy / Gizlilik</a> &middot; <a href="../terms/">Terms / Şartlar</a> &middot; <a href="mailto:omerr.poyrazz@gmail.com">Contact</a></footer></body></html>"""

open(os.path.join(ROOT, "PRIVACY_POLICY.md"), "w").write(md(PRIVACY))
open(os.path.join(ROOT, "TERMS_OF_SERVICE.md"), "w").write(md(TERMS))
os.makedirs(os.path.join(ROOT, "site", "privacy-policy"), exist_ok=True)
os.makedirs(os.path.join(ROOT, "site", "terms"), exist_ok=True)
open(os.path.join(ROOT, "site", "privacy-policy", "index.html"), "w").write(page(PRIVACY, "Privacy Policy / Gizlilik Politikası", "terms", "Terms of Service"))
open(os.path.join(ROOT, "site", "terms", "index.html"), "w").write(page(TERMS, "Terms of Service / Kullanım Şartları", "privacy-policy", "Privacy Policy"))
print("legal ok")
