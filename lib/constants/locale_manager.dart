import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeNotifier = ValueNotifier<String>('tr');

Future<void> loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  localeNotifier.value = prefs.getString('language') ?? 'tr';
}

Future<void> setLocale(String lang) async {
  localeNotifier.value = lang;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', lang);
}
