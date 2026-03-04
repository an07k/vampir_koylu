# 🧛 Vampir Köylü

> Sosyal dedüksiyon oyunu **Vampir Köylü** için modern bir Flutter mobil uygulaması. Arkadaşlarınızla gerçek zamanlı çok oyunculu maçlarda rol tabanlı oyun, oylama mekanikleri ve ilerleme sistemleriyle oynayın.

[![Flutter](https://img.shields.io/badge/Flutter-3.10.8+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.8+-blue.svg)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime-orange.svg)](https://firebase.google.com)
[![Lisans](https://img.shields.io/badge/Lisans-MIT-green.svg)](LICENSE)

## 📋 Genel Bakış

Vampir Köylü, oyuncuların farklı roller aldığı ve tartışma ve oylama yoluyla gizli düşmanları belirlemesi gereken sıra tabanlı bir sosyal dedüksiyon oyunudur. Bu Flutter uygulaması, Firebase tarafından desteklenen gerçek zamanlı senkronizasyonla kusursuz bir çok oyunculu deneyim sağlar.

### Oyun Konsepti
- **Oyuncular** gizli roller alırlar (Köylüler, Vampirler, Görüler, vb.)
- **Gün Fazı**: Tüm oyuncular tartışır ve birini elemek için oy verirler
- **Gece Fazı**: Vampirler veya özel rollere sahip oyuncular eylemlerini gerçekleştirirler
- **Kazanma Koşulu**: Tüm vampirler elenir ya da vampirler köylülere eşit veya daha fazla olur
- **Ekonomi**: Altın para başarılı oyunları ödüllendirir ve maçlar arasında kazanılabilir

## ✨ Özellikler

- **Kullanıcı Hesapları**
  - Email/şifre ile güvenli kimlik doğrulama
  - Hızlı oyun için konuk girişi
  - Avatar ve takma adlarla özelleştirilebilir profiller

- **Çok Oyunculu Odalar**
  - Oyun odaları oluştur ve barındır
  - Oda kodlarıyla etkin oyunlara katıl
  - Gerçek zamanlı oyuncu senkronizasyonu
  - Oda kapasitesi ve oyun durumu yönetimi

- **Oyun Mekanikleri**
  - Birden fazla karakter türüyle rol tabanlı oyun
  - Gerçek zamanlı gün/gece faz geçişleri
  - Oyuncu eleme için oylama sistemi
  - Oyun sonuçlarını gösteren rol açıklama ekranı
  - Maç istatistikleriyle oyun sonu ekranı

- **İlerleme Sistemi**
  - Maçlardan kazanılan altın para
  - Oyuncu istatistikleri takibi
  - Hesap seviyelendirmesi (gelecek geliştirmeler)

- **Kullanıcı Arayüzü**
  - Özel markalandırma (koyu kırmızı) ile koyu tema
  - Çeşitli ekran boyutları için duyarlı tasarım
  - Sorunsuz animasyonlar ve geçişler
  - Türkçe dil desteği

## 🛠️ Teknoloji Yığını

- **Ön Uç**: Flutter 3.10.8+
- **Dil**: Dart 3.10.8+
- **Arka Uç**: Firebase
  - Gerçek zamanlı veritabanı için Cloud Firestore
  - Firebase Kimlik Doğrulaması
- **UI Çerçevesi**: Material 3
- **Ek Kütüphaneler**:
  - `google_fonts: ^8.0.2` - Tipografi
  - `crypto: ^3.0.0` - Güvenli işlemler
  - `shared_preferences: ^2.2.2` - Yerel depolama

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası, kimlik doğrulama akışı
├── firebase_options.dart     # Firebase yapılandırması
├── screens/                  # UI ekranları
│   ├── welcome_screen.dart
│   ├── login_account_screen.dart
│   ├── create_account_screen.dart
│   ├── guest_login_screen.dart
│   ├── create_room_screen.dart
│   ├── join_room_screen.dart
│   ├── room_lobby_screen.dart
│   ├── game_screen.dart
│   ├── role_reveal_screen.dart
│   ├── game_end_screen.dart
│   └── widgets/              # Yeniden kullanılabilir UI bileşenleri
└── services/                 # İş mantığı ve Firebase entegrasyonu
    ├── auth_service.dart     # Kimlik doğrulama mantığı
    ├── gold_service.dart     # Para birimi yönetimi
    ├── role_distribution.dart # Rol atama sistemi
    ├── day_resolution_service.dart    # Gün faz mantığı
    └── night_resolution_service.dart  # Gece faz mantığı
```

## 🚀 Başlarken

### Ön Koşullar

- Flutter SDK (3.10.8 veya daha yüksek)
- Dart SDK (3.10.8 veya daha yüksek)
- Ayarlanmış bir Firebase projesi
- Android Studio / Xcode (derleme için)

### Kurulum

1. **Depoyu klonla**
   ```bash
   git clone https://github.com/an07k/vampir_koylu.git
   cd vampir_koylu
   ```

2. **Bağımlılıkları yükle**
   ```bash
   flutter pub get
   ```

3. **Firebase'i yapılandır**
   - [Firebase Konsolu](https://console.firebase.google.com)nda bir Firebase projesi oluştur
   - `google-services.json` (Android) veya `GoogleService-Info.plist` (iOS) indir
   - Dosyaları uygun platform dizinlerine yerleştir
   - `firebase_options.dart` dosyasını Firebase yapılandırmanla güncelle

4. **Uygulamayı çalıştır**
   ```bash
   flutter run
   ```

## 🎮 Oyun Akışı

1. **Hoş Geldiniz** → Kullanıcı giriş yapar (hesap veya konuk)
2. **Ana Menü** → Oda oluşturmayı veya katılmayı seç
3. **Oda Lobi** → Oyuncuların katılmasını bekle, oyun kurulumu
4. **Oyun Başlangıcı** → İlk gece fazı başlar
5. **Gün/Gece Döngüleri** → Oylama ve rol eylemleri
6. **Oyun Sonu** → Sonuçlar ve altın dağıtımı
7. **Menüye Dön** → Başka bir oyun başlat

## 🏗️ Mimari

### Durum Yönetimi
Uygulama, Firebase'i tek kaynak olarak kullanan hizmet tabanlı bir mimari kullanır:
- **AuthService**: Kullanıcı kimlik doğrulaması ve oturum durumunu yönetir
- **GoldService**: Para birimi işlemlerini işler
- **Role Distribution Service**: Oyun başında roller atar
- **Game Resolution Services**: Gün/gece faz mantığını yönetir

### Gerçek Zamanlı Senkronizasyon
- Canlı oyun güncellemeleri için Cloud Firestore dinleyicileri
- Oyun verilerini organize etmek için oda tabanlı koleksiyonlar
- Kimlik doğrulama durumu aracılığıyla kullanıcı varlığı takibi

### Gezinti
- Adlandırılmış rotalarla MaterialApp yönlendirmesi
- Navigator kullanarak ekran tabanlı gezinti
- AuthChecker widget, giriş durumuna göre başlangıç rotasını belirler

## 📱 Desteklenen Platformlar

- ✅ Android (Android 5.0+ üzerinde test edildi)
- ✅ iOS (iOS 11.0+ üzerinde test edildi)
- 🔄 Web (Flutter for Web desteği - geliştirme aşamasında)
- 🔄 Windows/macOS (Flutter desktop aracılığıyla mümkün)

## 🔐 Güvenlik

- Crypto kütüphanesi kullanarak şifre şifrelemesi
- Güvenli kullanıcı yönetimi için Firebase Kimlik Doğrulaması
- Veri koruma için Firestore güvenlik kuralları
- Anonim oyun için konuk modu
- Sunucu tarafı oyun mantığı doğrulaması

## 📊 Veritabanı Şeması (Firestore)

### Koleksiyonlar
- **users**: Kullanıcı profilleri, kimlik doğrulama meta verileri, istatistikler
- **rooms**: Oyun odası durumu, oyuncu listesi, oyun yapılandırması
- **games**: Geçmiş oyun kayıtları ve sonuçları

## 🤝 Katkıda Bulunma

Katkılar memnuniyetle karşılanır! Lütfen şu adımları izleyin:

1. Depoyu fork et
2. Bir özellik dalı oluştur (`git checkout -b feature/amazing-feature`)
3. Değişiklikleri commit et (`git commit -m 'Add amazing feature'`)
4. Dala push et (`git push origin feature/amazing-feature`)
5. Bir Pull Request aç

### Geliştirme Yönergeleri
- Dart stil kılavuzu ve lint kurallarını takip et
- Değişiklikleri Android ve iOS'ta test et
- Yeni özellikler için belgeleri güncelle
- Gerekirse Firebase kurallarının güncellenmesini sağla

## 📝 Sürüm Geçmişi

- **v1.3.8** - En son sürüm
- Tam değişiklik günlüğü için [Sürümler](https://github.com/an07k/vampir_koylu/releases) bölümüne bak

## 🐛 Bilinen Sorunlar & Yol Haritası

Ayrıntılı teknik denetim, bilinen sorunlar ve gelecek geliştirmeler için [audit.md](audit.md) dosyasına bak.

### Planlanan Özellikler
- [ ] Hesap seviyelendirme sistemi
- [ ] Gelişmiş istatistik panosu
- [ ] Oyun içi sohbet sistemi
- [ ] Turnuva modu
- [ ] Elenen oyuncular için seyirci modu
- [ ] Çoklu dil desteği
- [ ] Sosyal özellikler (arkadaş listesi, sıralaması)

## 📄 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - ayrıntılar için LICENSE dosyasına bakın.

## 👨‍💻 Yazarlar

- **an07k** - Orijinal yazar ve yönetici

## 🙏 Teşekkürler

- Firebase ekibine harika gerçek zamanlı veritabanı çözümleri için
- Flutter ekibine inanılmaz çapraz platform çerçevesi için
- Topluluk katılımcılarına ve test edenlerine

## 📮 Destek

Sorunlar, sorular veya öneriler için lütfen:
- Bir [Sorun](https://github.com/an07k/vampir_koylu/issues) aç
- [docs/](docs/) dizinindeki mevcut belgeleri kontrol et
- Teknik ayrıntılar için [audit.md](audit.md) dosyasını gözden geçir

---

**Türkiye'de ❤️ ile yapılmıştır**
