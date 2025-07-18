import 'package:flutter/foundation.dart';
import 'package:foodie_customer/userPrefrence.dart';
import 'package:foodie_customer/utils/DarkThemePreference.dart';

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    UserPreference.getLightDarkThemeData() != null
        ? _darkTheme = UserPreference.getLightDarkThemeData()
        : _darkTheme = value;
    print("darkthemeValue ${_darkTheme}");
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }
}
