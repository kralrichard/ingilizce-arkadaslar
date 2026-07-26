# 22 Arkadaş — İngilizce Konuşma

22 farklı karakterle diyalog kurarak İngilizce pratiği. İnternet gerektirmez, API kullanmaz.

## Rakamlar

| | |
|---|---|
| Arkadaş | 22 |
| Arkadaş başına diyalog | 25 sahne |
| Sahne başına tur | 10 |
| Turda cümle | 1 arkadaş cümlesi + 3 cevap seçeneği |
| **Arkadaş başına cümle** | **25 × 10 × 4 = 1.000** |
| **Toplam** | **22 × 1.000 = 22.000 cümle** |

Her cümlenin Türkçe karşılığı da var. `build.pl` toplam 22.000'i her derlemede doğrular, tutmazsa hata verir.

## Arkadaşlar

Jack (Londra, barista, Arsenal) · Emily (Manchester, hemşire) · Leo (New York, aşçı) ·
Sophie (Brighton, öğrenci) · Marcus (Chicago, taksici) · Aisha (Birmingham, yazılımcı) ·
Tom (Dublin, tesisatçı) · Grace (Melbourne, yoga) · Daniel (Londra, futbolcu) ·
Nina (Toronto, diş hekimi) · Oliver (Leeds, öğrenci) · Maria (Boston, öğretmen) ·
Ryan (Cardiff, antrenör) · Chloe (Bristol, tasarımcı) · Hassan (Dubai, iş insanı) ·
Lucy (Liverpool, kuaför) · Ben (Newcastle, müze rehberi) · Yuki (Vancouver, fotoğrafçı) ·
Sam (Manchester, DJ) · Hannah (Edinburgh, veteriner) · Diego (Miami, restoran sahibi) ·
Ella (Auckland, gezgin)

Seviyeler: **A1** (Oliver) · **A2** (9 kişi) · **B1** (7 kişi) · **B2** (Aisha, Nina, Hassan, Ben).
Karakterin seviyesi ne konuştuğunu belirler — Oliver kısa ve basit, Ben uzun ve zengin cümleler kurar.

## 25 sahne (kategoriler)

- **Günlük hayat**: kafe, kahvaltı, restoran, hafta sonu, alışveriş, telefon
- **Tatil ve seyahat**: tatil planı, otelde, havaalanı
- **Futbol**: maç izlerken, maç sonrası muhabbet
- **Haberler**: TV haberleri, teknoloji ve dünya haberleri
- **İş ve okul**: iş günü, kariyer
- **Sağlık**: doktor, spor
- **Ev**: film gecesi, ev işleri ve komşular
- **Eğlence**: müzik ve konser, kitap ve dizi, doğum günü
- **İnsanlar**: aile, kötü bir gün, gelecek hayalleri

## Tutarlılık

Her karakterin sabit bir hayatı var: şehir, iş, takım, favori oyuncu, yemek, kahvaltı, evcil
hayvan, aile, hobi, müzik, film, dizi, hayal, son tatil, ulaşım, sevdiği hava, ağzından
düşmeyen laf. Bu bilgiler tüm diyaloglara yerleşir, bu yüzden:

- Grace'e takımını sorarsan **her zaman** Melbourne Victory der.
- Aynı diyaloğu tekrar açarsan **birebir aynı** cümleleri görürsün (seed'li üretim).
- **Onu tanı** sekmesinde 24 kişisel sorunun cevabı sabittir ve diyaloglarla çelişmez.

## Çalıştırma

```bash
perl server.pl 8147
```

Sonra `http://localhost:8147` adresini aç. (Veri `fetch` ile yüklendiği için dosyayı doğrudan
çift tıklayarak açmak yeterli değil, bir sunucu gerekiyor. GitHub Pages'e koyarsan hazır çalışır.)

## Yeniden üretme

```bash
perl build.pl
```

`src/characters.pl` (22 karakter profili) + `src/scenes1..5.pl` (25 sahne iskeleti) dosyalarını
okur, `data/index.json` ve `data/chars/*.json` dosyalarını üretir. Bir karakteri değiştirmek
istersen `src/characters.pl` içindeki alanı düzenleyip `build.pl` çalıştırman yeterli — o
karakterin 1000 cümlesi baştan üretilir.

## Dosyalar

```
index.html  style.css  app.js     arayüz
build.pl                          derleyici (22.000 cümleyi üretir + sayar)
server.pl                         yerel test sunucusu
src/characters.pl                 22 karakter profili
src/scenes1..5.pl                 25 sahne, her biri 10 tur
data/index.json                   arkadaş listesi
data/chars/<id>.json              karakterin 25 diyaloğu + 24 soru-cevabı (~95 KB)
```
