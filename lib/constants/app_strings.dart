class AppStrings {
  // Main menu
  static const String appTitle = 'VAMPİR KÖYLÜ';
  static const String createRoom = 'ODA OLUŞTUR';
  static const String joinRoom = 'ODAYA KATIL';
  static const String statistics = 'İSTATİSTİKLER';

  // Profile
  static const String guest = 'Misafir';
  static const String loading = 'Yükleniyor...';

  // Dialogs
  static const String alreadyInRoom = 'Zaten bir odanız var';
  static const String leaveRoomMessage =
      'Yeni oda oluşturmak için önce "{roomId}" odasından ayrılmanız veya odayı kapatmanız gerekir.';
  static const String ok = 'TAMAM';

  // Night phase - Âşık
  static const String asikSelectTarget = 'Aşığını Seç 💘';
  static const String asikTargetSelected = '💘 Aşığını seçtiniz. Kaderinizi bekliyorsunuz...';
  static const String asikKinlendiButton = '💔 KİNLENDİ — Kurbanını Seç';
  static const String asikKinlendiSubmitted = '✓ Kurbanını seçtin. Intikamın alınacak...';
  static const String asikActionSubmitted = '✓ Aksiyonun gönderildi. Diğer oyuncular bekleniyor...';

  // Night results - Âşık effects
  static const String asikIntihar = '💔 Âşık aşkının ölümüne dayanamayıp intihar etti!';
  static const String asikKinlendi = '💔 Âşık sevgilisini yitirdi ve kinlendi...';
  static const String asikDeli = '💔 Âşık sevgilisini yitirdi ve deli oldu!';
  static const String asikVengeance = '🔥 Kinlendi âşık {name}\'i intikam için öldürdü!';
}
