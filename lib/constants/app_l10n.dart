import 'locale_manager.dart';

class AppL10n {
  static bool get _isTr => localeNotifier.value == 'tr';

  // ─── Genel ───────────────────────────────────────────────────────────────
  static String get ok => _isTr ? 'TAMAM' : 'OK';
  static String get cancel => _isTr ? 'İPTAL' : 'CANCEL';
  static String get close => _isTr ? 'KAPAT' : 'CLOSE';
  static String get error => _isTr ? 'Hata' : 'Error';
  static String get loading => _isTr ? 'Yükleniyor...' : 'Loading...';
  static String get guest => _isTr ? 'Misafir' : 'Guest';
  static String get continue_ => _isTr ? 'DEVAM' : 'CONTINUE';
  static String get unknown => _isTr ? 'BILINMIYOR' : 'UNKNOWN';

  // ─── Ana Menü ────────────────────────────────────────────────────────────
  static String get appTitle => _isTr ? 'VAMPİR KÖYLÜ' : 'VAMPIRE VILLAGE';
  static String get createRoom => _isTr ? 'ODA OLUŞTUR' : 'CREATE ROOM';
  static String get joinRoom => _isTr ? 'ODAYA KATIL' : 'JOIN ROOM';
  static String get statistics => _isTr ? 'İSTATİSTİKLER' : 'STATISTICS';
  static String get settings => _isTr ? 'Ayarlar' : 'Settings';
  static String get alreadyInRoom => _isTr ? 'Zaten bir odanız var' : 'You already have a room';
  static String leaveRoomMessage(String roomId) => _isTr
      ? 'Yeni oda oluşturmak için önce "$roomId" odasından ayrılmanız veya odayı kapatmanız gerekir.'
      : 'To create a new room, you must first leave or close room "$roomId".';

  // ─── Welcome ─────────────────────────────────────────────────────────────
  static String get createAccount => _isTr ? 'HESAP OLUŞTUR' : 'CREATE ACCOUNT';
  static String get loginBtn => _isTr ? 'GİRİŞ YAP' : 'LOG IN';
  static String get playAsGuest => _isTr ? 'MİSAFİR OYNA' : 'PLAY AS GUEST';
  static String get privacyPolicyLink => _isTr ? 'Gizlilik Politikası' : 'Privacy Policy';
  static String get termsOfUseLink => _isTr ? 'Kullanım Koşulları' : 'Terms of Use';
  static String get privacyNoteBefore => _isTr ? 'Uygulamayı kullanarak ' : 'By using the app, ';
  static String get privacyNoteAnd => _isTr ? ' ve ' : ' and ';
  static String get privacyNoteAfter => _isTr ? "'nı kabul etmiş sayılırsınız." : ' you are deemed to have accepted.';
  static String get privacyNoteCreateBefore => _isTr ? 'Hesap oluşturarak ' : 'By creating an account, ';

  // ─── Hesap Oluştur ───────────────────────────────────────────────────────
  static String get createAccountTitle => _isTr ? 'Hesap Oluştur' : 'Create Account';
  static String get nicknameLabel => _isTr ? 'Nickname (Giriş için)' : 'Nickname (for login)';
  static String get gameNameLabel => _isTr ? 'Oyun İsmi' : 'Game Name';
  static String get passwordLabel => _isTr ? 'Şifre' : 'Password';
  static String get passwordHint => _isTr ? 'En az 4 karakter' : 'At least 4 characters';
  static String get passwordConfirmLabel => _isTr ? 'Şifre Tekrar' : 'Confirm Password';
  static String get passwordConfirmHint => _isTr ? 'Şifreyi tekrar girin' : 'Re-enter password';
  static String get passwordMismatch => _isTr ? 'Şifreler eşleşmiyor' : 'Passwords do not match';

  // ─── Giriş Yap ───────────────────────────────────────────────────────────
  static String get loginTitle => _isTr ? 'Giriş Yap' : 'Log In';
  static String get nicknameEmpty => _isTr ? 'Nickname boş olamaz' : 'Nickname cannot be empty';
  static String get passwordEmpty => _isTr ? 'Şifre boş olamaz' : 'Password cannot be empty';

  // ─── Misafir Girişi ──────────────────────────────────────────────────────
  static String get guestLoginTitle => _isTr ? 'Misafir Girişi' : 'Guest Login';
  static String get guestInfo => _isTr
      ? 'Misafir hesaplar kaydedilmez. İstatistikler tutulmaz.'
      : 'Guest accounts are not saved. Statistics are not tracked.';

  // ─── Oda Oluştur ─────────────────────────────────────────────────────────
  static String get createRoomTitle => _isTr ? 'Oda Oluştur' : 'Create Room';
  static String get roomCodeLabel => _isTr ? 'Oda Kodu' : 'Room Code';
  static String get passwordOptional => _isTr ? 'Şifre (Opsiyonel)' : 'Password (Optional)';
  static String get passwordHintRoom => _isTr
      ? 'Şifre girmezseniz oda herkese açık olur'
      : 'Without a password, the room will be open to everyone';
  static String get playerCountLabel => _isTr ? 'Oyuncu Sayısı' : 'Player Count';
  static String playerRange(int min) => _isTr ? '$min-15 arası' : '$min-15 range';
  static String get gameModeLabel => _isTr ? 'Oyun Modu' : 'Game Mode';
  static String get classic => _isTr ? 'Klasik' : 'Classic';
  static String get classicDesc => _isTr ? 'Vampir, Köylü, Doktor' : 'Vampire, Villager, Doctor';
  static String get eccentric => _isTr ? 'Egzantrik' : 'Eccentric';
  static String get eccentricDesc => _isTr
      ? '+ Rastgele 1-2 özel rol (Âşık, Deli, vs.)\nMinimum 7 oyuncu gerekir'
      : '+ Random 1-2 special roles (Lover, Mad, etc.)\nMinimum 7 players required';
  static String get userNotFound => _isTr ? 'Kullanıcı bilgisi bulunamadı.' : 'User information not found.';
  static String get roomCreateFailed => _isTr ? 'Oda oluşturulamadı. Tekrar deneyin.' : 'Failed to create room. Please try again.';

  // ─── Odaya Katıl ─────────────────────────────────────────────────────────
  static String get joinRoomTitle => _isTr ? 'Odaya Katıl' : 'Join Room';
  static String get passwordHintJoin => _isTr ? 'Oda şifresi' : 'Room password';
  static String get joinRoomBtn => _isTr ? 'ODAYA KATIL' : 'JOIN ROOM';
  static String get returnToRoom => _isTr ? 'ODAYA DÖN' : 'RETURN TO ROOM';
  static String get alreadyInRoomWarning => _isTr ? 'Zaten bir odanız var' : 'You already have a room';
  static String get enterRoomCode => _isTr ? 'Lütfen oda kodunu girin' : 'Please enter the room code';
  static String get roomCodeLength => _isTr ? 'Oda kodu 6 haneli olmalıdır' : 'Room code must be 6 characters';
  static String get roomNotFoundError => _isTr ? 'Oda bulunamadı' : 'Room not found';
  static String get wrongPassword => _isTr ? 'Yanlış şifre' : 'Wrong password';
  static String get gameAlreadyStarted => _isTr ? 'Oyun zaten başlamış' : 'Game has already started';
  static String get roomFull => _isTr ? 'Oda dolu' : 'Room is full';
  static String get tryAgain => _isTr ? 'Bir hata oluştu. Tekrar deneyin.' : 'An error occurred. Please try again.';
  static String get joinError => _isTr ? 'Odaya katılırken hata oluştu' : 'Error joining room';
  static String get userNotFoundShort => _isTr ? 'Kullanıcı bilgisi bulunamadı' : 'User not found';
  static String roomLabel(String code) => _isTr ? 'Oda: $code' : 'Room: $code';
  static String playerCountDisplay(int count, int max) => _isTr ? '$count/$max Oyuncu' : '$count/$max Players';
  static String gameModeDisplay(String mode) =>
      mode == 'classic' ? classic : eccentric;

  // ─── Oda Lobi ────────────────────────────────────────────────────────────
  static String get startGame => _isTr ? 'OYUNU BAŞLAT' : 'START GAME';
  static String get addBot => _isTr ? 'BOT EKLE' : 'ADD BOT';
  static String get closeRoomBtn => _isTr ? 'ODAYI KAPAT' : 'CLOSE ROOM';
  static String get leaveRoom => _isTr ? 'ODADAN AYRIL' : 'LEAVE ROOM';
  static String get closeRoomTitle => _isTr ? 'Odayı Kapat' : 'Close Room';
  static String get closeRoomConfirmLobby => _isTr
      ? 'Odayı kapatmak istediğinize emin misiniz? Tüm oyuncular odadan atılacak ve oda silinecek.'
      : 'Are you sure you want to close the room? All players will be removed and the room will be deleted.';
  static String get kickPlayerTitle => _isTr ? 'Oyuncuyu Çıkar' : 'Kick Player';
  static String kickConfirm(String name) => _isTr
      ? '$name adlı oyuncuyu odadan çıkarmak istediğinize emin misiniz?'
      : 'Are you sure you want to kick $name from the room?';
  static String get kick => _isTr ? 'ÇIKART' : 'KICK';
  static String get roomClosed => _isTr ? 'Oda kapatıldı' : 'Room closed';
  static String get roomFullLobby => _isTr ? 'Oda dolu!' : 'Room is full!';
  static String get playerKicked => _isTr ? 'Oyuncu odadan çıkarıldı' : 'Player was kicked from the room';
  static String get gameStarted => _isTr ? 'Oyun başladı! Roller dağıtıldı.' : 'Game started! Roles have been assigned.';
  static String get gameStartFailed => _isTr ? 'Oyun başlatılamadı. Tekrar deneyin.' : 'Failed to start the game. Please try again.';
  static String get gameStarting => _isTr ? 'Oyun başlıyor...' : 'Game is starting...';
  static String get kickTooltip => _isTr ? 'Oyuncuyu Çıkar' : 'Kick Player';

  // ─── İstatistikler ───────────────────────────────────────────────────────
  static String get statisticsTitle => _isTr ? 'İstatistikler' : 'Statistics';
  static String get guestNoStats => _isTr
      ? 'Misafir hesaplar istatistik görüntüleyemez.'
      : 'Guest accounts cannot view statistics.';
  static String get totalGames => _isTr ? 'Toplam Oyun' : 'Total Games';
  static String get won => _isTr ? 'Kazanılan' : 'Won';
  static String get lost => _isTr ? 'Kaybedilen' : 'Lost';
  static String get winrate => 'Winrate';

  // ─── Ayarlar ─────────────────────────────────────────────────────────────
  static String get settingsTitle => _isTr ? 'Ayarlar' : 'Settings';
  static String get soundSection => _isTr ? '🔊 Ses' : '🔊 Sound';
  static String get music => _isTr ? 'Müzik' : 'Music';
  static String get soundEffects => _isTr ? 'Ses Efektleri' : 'Sound Effects';
  static String get on => _isTr ? 'Açık' : 'On';
  static String get off => _isTr ? 'Kapalı' : 'Off';
  static String get languageSection => _isTr ? '🌍 Dil' : '🌍 Language';
  static String get languageLabel => _isTr ? 'Dil' : 'Language';
  static String get currentLanguage => _isTr ? 'Türkçe' : 'English';

  // ─── Oyun Ekranı ─────────────────────────────────────────────────────────
  static String get night => _isTr ? 'GECE' : 'NIGHT';
  static String get day => _isTr ? 'GÜNDÜZ' : 'DAY';
  static String playersAlive(int alive, int total) =>
      _isTr ? 'OYUNCULAR ($alive/$total Canlı)' : 'PLAYERS ($alive/$total Alive)';
  static String get myRole => _isTr ? 'Rolün' : 'Your Role';
  static String get alive => _isTr ? 'Canlı' : 'Alive';
  static String get dead => _isTr ? 'Ölü' : 'Dead';
  static String get closeRoomGame => _isTr ? 'ODAYI KAPAT' : 'CLOSE ROOM';
  static String get closeRoomConfirmGame => _isTr
      ? 'Odayı kapatmak istediğinize emin misiniz? Tüm oyuncular odadan çıkacak.'
      : 'Are you sure you want to close the room? All players will exit.';
  static String get hostControlPanel => _isTr ? 'HOST KONTROL PANELİ' : 'HOST CONTROL PANEL';
  static String get endNight => _isTr ? 'GECEYİ BİTİR' : 'END NIGHT';
  static String get notAllActed => _isTr
      ? 'Henüz tüm oyuncular aksiyonlarını göndermedi!'
      : 'Not all players have submitted their actions!';
  static String get nightResolved => _isTr ? 'Gece çözümlendi! Gündüz başladı.' : 'Night resolved! Day has begun.';
  static String get votingPhase => _isTr ? 'OYLAMA AŞAMASI' : 'VOTING PHASE';
  static String get freeTime => _isTr ? 'SERBEST ZAMAN' : 'FREE TIME';
  static String votingStatus(int count, int total) =>
      _isTr ? '$count / $total oyuncu oy verdi' : '$count / $total players voted';
  static String get freeTimeDesc => _isTr
      ? "Serbest zaman — 22:00'da gece başlayacak."
      : 'Free time — night will begin at 22:00.';
  static String get endVoting => _isTr ? 'OYLAMAYI BİTİR' : 'END VOTING';
  static String get startNight => _isTr ? 'GECEYİ BAŞLAT' : 'START NIGHT';
  static String get votingEnded => _isTr ? 'Oylama sonuçlandı! Serbest zaman başladı.' : 'Voting ended! Free time has started.';
  static String get nightStarted => _isTr ? 'Gece başladı!' : 'Night has begun!';
  static String get noTargets => _isTr ? 'Seçilebilecek hedef yok!' : 'No targets available!';
  static String get noVoteTargets => _isTr ? 'Oylanabilecek kimse yok!' : 'Nobody to vote for!';
  static String get selectTarget => _isTr ? 'HEDEF SEÇ' : 'SELECT TARGET';
  static String get voteSubmitted => _isTr ? 'Oy gönderildi!' : 'Vote submitted!';
  static String get actionSubmitted => _isTr ? 'Aksiyon gönderildi!' : 'Action submitted!';
  static String errorMsg(Object e) => _isTr ? 'Hata: $e' : 'Error: $e';
  static String get deadPlayerMsg => _isTr
      ? '💀 Öldün — Oyunu izleyebilirsin'
      : '💀 You died — You can observe the game';
  static String get deadChat => _isTr ? 'ÖLÜLER SOHBETİ' : 'DEAD CHAT';
  static String get noNightAction => _isTr
      ? '🌙 Gece fazında bir aksiyonun yok. Sabahı bekle...'
      : '🌙 You have no action in the night phase. Wait for morning...';
  static String get actionSent => _isTr
      ? '✓ Aksiyonun gönderildi. Diğer oyuncular bekleniyor...'
      : '✓ Action submitted. Waiting for other players...';
  static String get voteGiven => _isTr ? '✓ Oyunu verdin' : '✓ Vote submitted';
  static String get voteTargetLabel => _isTr ? 'Hedef: ' : 'Target: ';
  static String get voteQuestion => _isTr ? '☀️ KİME OY VERİYORSUN?' : '☀️ WHO ARE YOU VOTING FOR?';
  static String get votesVisible => _isTr ? 'Oylar herkese açık görünecek!' : 'Votes will be visible to everyone!';
  static String get doVote => _isTr ? '☀️ OYLAMA YAP' : '☀️ VOTE';
  static String get freeTimeBox => _isTr
      ? '💬 Serbest zaman\nKonuşabilir, tartışabilirsin.'
      : '💬 Free time\nYou can talk and discuss.';
  static String get coordination => _isTr ? 'KOORDİNASYON' : 'COORDINATION';
  static String get vampireCoordTitle => _isTr ? 'VAMPİR KOORDİNASYONU' : 'VAMPIRE COORDINATION';
  static String get vampireCoordSub => _isTr ? 'Kimi yemek istediğini işaretle' : 'Mark who you want to eliminate';
  static String get deadChatTitle => _isTr ? 'ÖLÜLER SOHBETİ' : 'DEAD CHAT';
  static String get deadChatSub => _isTr ? 'Sadece ölüler görebilir' : 'Only the dead can see this';
  static String get vampireChatTitle => _isTr ? 'VAMPİR SOHBETİ' : 'VAMPIRE CHAT';
  static String get vampireChatSub => _isTr ? 'Sadece vampirler görebilir' : 'Only vampires can see this';
  static String get roomNotFoundMsg => _isTr ? 'Oda bulunamadı' : 'Room not found';
  static String get dedektifUsed => _isTr
      ? '🔍 Dedektif hakkını kullandın. Sabahı bekle...'
      : '🔍 You have used your detective ability. Wait for morning...';
  static String get roleTooltip => _isTr ? 'Rol Bilgisi' : 'Role Info';
  static String get voteResult => _isTr ? 'OYLAMA SONUCU' : 'VOTE RESULT';
  static String get morningNews => _isTr ? 'SABAH HABERLERİ' : 'MORNING NEWS';
  static String get unknown_ => _isTr ? 'Bilinmeyen' : 'Unknown';

  // Dedektif sonucu
  static String dedektifResult(String name, String role) =>
      _isTr ? '🔍 $name\'ın rolü: $role' : '🔍 $name\'s role: $role';

  // ─── Rastgele Mesajlar ───────────────────────────────────────────────────
  static List<String> eliminatedMessages(String name) => _isTr
      ? [
          '$name köyden kovuldu!',
          '$name infaz edildi!',
          '$name karşı köye gönderildi!',
          '$name halk mahkemesinde yargılandı!',
          '$name köyün adaletine kurban gitti!',
          '$name ipini çekti!',
          '$name köy meydanında hesap verdi!',
        ]
      : [
          '$name was expelled from the village!',
          '$name was executed!',
          '$name was sent to the other side!',
          '$name was judged by the people!',
          '$name fell victim to village justice!',
          '$name met their end!',
          '$name faced justice in the village square!',
        ];

  static List<String> deathMessages(String name) => _isTr
      ? [
          '$name evinde ölü bulundu.',
          '$name tahtalı köye gitti.',
          '$name sabah ezanını duymadı.',
          'Sabah $name\'den ses çıkmadı.',
          '$name geceyi atlatamadı.',
          '$name köy meydanında ölü bulundu.',
          '$name\'in şansı bu gece tükendi.',
        ]
      : [
          '$name was found dead at home.',
          '$name is gone for good.',
          '$name did not wake up this morning.',
          'No sound came from $name at dawn.',
          '$name did not survive the night.',
          '$name was found dead in the village square.',
          '$name\'s luck ran out tonight.',
        ];

  static List<String> get peaceMessages => _isTr
      ? [
          'Bu gece kimse ölmedi.',
          'Köy huzurla uyudu.',
          'Vampirler bu gece boş döndü.',
          'Köy bir gece daha ayakta.',
          'Bu sabah herkes gözlerini açtı.',
        ]
      : [
          'Nobody died tonight.',
          'The village slept in peace.',
          'The vampires returned empty-handed.',
          'The village stands for another night.',
          'Everyone woke up this morning.',
        ];

  static List<String> get tieMessages => _isTr
      ? [
          'Oylar ayrılı, kimse öldürülemedi!',
          'Berabere kalmış oylar!',
          'Köy ikiye bölündü!',
          'Oy sayımında çetin bir beraberlik!',
          'Halk karar veremiyor!',
        ]
      : [
          'Votes are tied, nobody could be killed!',
          'The votes are equal!',
          'The village is divided!',
          'A fierce tie in the vote count!',
          'The people cannot decide!',
        ];

  static String tiedPlayersJoin(List<String> names) =>
      names.join(_isTr ? ' ve ' : ' and ');

  // ─── Rol Adları ──────────────────────────────────────────────────────────
  static String get roleVampir => _isTr ? 'VAMPİR' : 'VAMPIRE';
  static String get roleKoylu => _isTr ? 'KÖYLÜ' : 'VILLAGER';
  static String get roleDoktor => _isTr ? 'DOKTOR' : 'DOCTOR';
  static String get roleAsik => _isTr ? 'ÂŞIK' : 'LOVER';
  static String get roleDeli => _isTr ? 'DELİ' : 'MAD ONE';
  static String get roleDedektif => _isTr ? 'DEDEKTİF' : 'DETECTIVE';
  static String get roleMisafir => _isTr ? 'MİSAFİR' : 'VISITOR';
  static String get rolePolis => _isTr ? 'POLİS' : 'POLICE';
  static String get roleTakipci => _isTr ? 'TAKİPÇİ' : 'STALKER';
  static String get roleManipulator => _isTr ? 'MANİPÜLATÖR' : 'MANIPULATOR';

  static Map<String, String> get roleNames => {
        'vampir': roleVampir,
        'koylu': roleKoylu,
        'doktor': roleDoktor,
        'asik': roleAsik,
        'deli': roleDeli,
        'dedektif': roleDedektif,
        'misafir': roleMisafir,
        'polis': rolePolis,
        'takipci': roleTakipci,
        'manipulator': roleManipulator,
      };

  // _getRoleDisplayName için (dedektif sonucunda kullanılır)
  static String getRoleDisplayName(String role) {
    const icons = {
      'vampir': '🧛',
      'koylu': '🧑‍🌾',
      'doktor': '⚕️',
      'dedektif': '🔍',
      'misafir': '🏠',
      'polis': '👮',
      'takipci': '👣',
      'manipulator': '🎭',
      'asik': '💕',
      'deli': '🃏',
    };
    final icon = icons[role] ?? '';
    return '$icon ${roleNames[role] ?? role}';
  }

  // ─── Rol Açıklamaları ────────────────────────────────────────────────────
  static Map<String, String> get roleDescriptions => _isTr
      ? {
          'vampir':
              'Gece diğer vampirlerle birlikte bir köylüyü öldürüyorsun. Gündüz oylamada köylülere karış ve tespite çakılma!',
          'koylu':
              'Gündüz oylama ile vampirleri bul ve öldür. Sana özel bir yetki yok ama gözlemle her şeyi çözebilirsin!',
          'doktor':
              'Gece bir kişiyi koruyabilirsin. Eğer vampirler o kişiyi seçerse ölmez! Ama aynı kişiyi iki gece üst üste koruyamazsın.',
          'asik':
              'Oyun başında bir kişi seç, o senin aşkın. Eğer aşkın masum öldürülürse ertesi gün 1 kişi öldürme hakkın olur. Ama aşkın vampireyse öldürüldüğünde kendin ölürsün!',
          'deli':
              'Eğer kendini oylama ile astırırsan kazanırsın! Aksi takdirde her zaman kaybedersin. Herkes seni şüphelendirmeye çalış!',
          'dedektif':
              'Bir gece seçtiğin kişinin rolünü tam olarak öğrenebilirsin. Bu bilgiyi iyi kullan!',
          'misafir':
              'Gece gittiğin kişiyi işinden alıkoyarsın. Doktorsa koruma yapamaz, vampireyse öldürme yapamaz!',
          'polis':
              'Bir gece nöbet tutarsan, o eve kim geldiğini öğrenirsin. Kim vampir kim değil bulmana yardımcı olabilir!',
          'takipci':
              'Bir eve sızırsan, o kişi bir yere giderse nereye gittiğini öğrenirsin. Vampirlerin hareketlerini izle!',
          'manipulator':
              'Oyun boyunca bir kez, gündüz oylaması esnasında iki oyuncunun oylarını değiştirebilirsin. Herkes bunu görecek!',
        }
      : {
          'vampir':
              'Each night, work with other vampires to eliminate a villager. During the day, blend in and avoid being detected!',
          'koylu':
              'Find and eliminate vampires through daytime voting. You have no special ability, but careful observation can reveal everything!',
          'doktor':
              'Each night you can protect one person. If vampires target them, they survive! But you cannot protect the same person two nights in a row.',
          'asik':
              'At the start of the game, choose someone as your beloved. If your beloved is innocently killed, you can kill 1 person the next day. But if your beloved is a vampire, you die when they are eliminated!',
          'deli':
              'You win if you get voted out by the village! Otherwise you always lose. Try to make everyone suspicious of you!',
          'dedektif':
              'Once per game, you can learn the exact role of someone you investigate. Use this information wisely!',
          'misafir':
              'At night you distract the person you visit. If they are the doctor, they cannot protect; if they are a vampire, they cannot kill!',
          'polis':
              'If you keep watch one night, you learn who visited that house. This can help you figure out who is a vampire!',
          'takipci':
              'If you tail someone, you learn where they go that night. Track the vampires\' movements!',
          'manipulator':
              'Once during the game, you can swap two players\' votes during the daytime voting. Everyone will see this!',
        };

  // ─── Âşık Stringleri ─────────────────────────────────────────────────────
  static String get asikSelectTarget => _isTr ? 'Aşığını Seç 💘' : 'Choose Your Beloved 💘';
  static String get asikTargetSelected =>
      _isTr ? '💘 Aşığını seçtiniz. Kaderinizi bekliyorsunuz...' : '💘 You have chosen your beloved. Awaiting your fate...';
  static String get asikKinlendiButton => _isTr ? '💔 KİNLENDİ — Kurbanını Seç' : '💔 VENGEFUL — Choose Your Target';
  static String get asikKinlendiSubmitted =>
      _isTr ? '✓ Kurbanını seçtin. Intikamın alınacak...' : '✓ You have chosen your target. Your vengeance will be taken...';
  static String get asikActionSubmitted =>
      _isTr ? '✓ Aksiyonun gönderildi. Diğer oyuncular bekleniyor...' : '✓ Action submitted. Waiting for other players...';
  static String get asikIntihar =>
      _isTr ? '💔 Âşık aşkının ölümüne dayanamayıp intihar etti!' : '💔 The Lover could not bear the loss and committed suicide!';
  static String get asikKinlendi =>
      _isTr ? '💔 Âşık sevgilisini yitirdi ve kinlendi...' : '💔 The Lover lost their beloved and became vengeful...';
  static String get asikDeli =>
      _isTr ? '💔 Âşık sevgilisini yitirdi ve deli oldu!' : '💔 The Lover lost their beloved and went mad!';
  static String asikVengeance(String name) =>
      _isTr ? '🔥 Kinlendi âşık $name\'i intikam için öldürdü!' : '🔥 The vengeful lover killed $name in revenge!';

  // ─── Oyun Sonu ───────────────────────────────────────────────────────────
  static String get vampireWin => _isTr ? 'VAMPİRLER KAZANDI!' : 'VAMPIRES WIN!';
  static String get vampireWinSub => _isTr ? 'Karanlık galip geldi...' : 'Darkness prevailed...';
  static String get villagerWin => _isTr ? 'KÖYLÜLER KAZANDI!' : 'VILLAGERS WIN!';
  static String get villagerWinSub => _isTr ? 'Köy kurtarıldı!' : 'The village was saved!';
  static String get madWin => _isTr ? 'DELİ KAZANDI!' : 'THE MAD ONE WINS!';
  static String get madWinSub => _isTr ? 'Kaos her şeyi ele geçirdi!' : 'Chaos took over everything!';
  static String get gameOver => _isTr ? 'OYUN BİTTİ' : 'GAME OVER';
  static String get unknownResult => _isTr ? 'Bilinmeyen sonuç' : 'Unknown result';
  static String get winners => _isTr ? '🏆 KAZANANLAR' : '🏆 WINNERS';
  static String get returning => _isTr ? 'Dönülüyor...' : 'Returning...';
  static String get returnToRoomBtn => _isTr ? 'ODAYA DÖN' : 'RETURN TO ROOM';
  static String get mainMenu => _isTr ? 'ANA MENÜ' : 'MAIN MENU';
  static String get returnError => _isTr ? 'Hata' : 'Error';
}
