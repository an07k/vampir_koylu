// Backward-compat: delegates to AppL10n
import 'app_l10n.dart';

class AppStrings {
  static String get appTitle => AppL10n.appTitle;
  static String get createRoom => AppL10n.createRoom;
  static String get joinRoom => AppL10n.joinRoom;
  static String get statistics => AppL10n.statistics;
  static String get guest => AppL10n.guest;
  static String get loading => AppL10n.loading;
  static String get alreadyInRoom => AppL10n.alreadyInRoom;
  static String get ok => AppL10n.ok;

  static String leaveRoomMessage(String roomId) => AppL10n.leaveRoomMessage(roomId);

  // Âşık strings
  static String get asikSelectTarget => AppL10n.asikSelectTarget;
  static String get asikTargetSelected => AppL10n.asikTargetSelected;
  static String get asikKinlendiButton => AppL10n.asikKinlendiButton;
  static String get asikKinlendiSubmitted => AppL10n.asikKinlendiSubmitted;
  static String get asikActionSubmitted => AppL10n.asikActionSubmitted;
  static String get asikIntihar => AppL10n.asikIntihar;
  static String get asikKinlendi => AppL10n.asikKinlendi;
  static String get asikDeli => AppL10n.asikDeli;
  static String asikVengeance(String name) => AppL10n.asikVengeance(name);
}
