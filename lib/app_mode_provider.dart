// app_mode_provider.dart
import 'package:flutter/material.dart';

class AppModeProvider with ChangeNotifier {
  String _mode = 'restaurant'; // 'restaurant', 'catering', or 'both'

  String get mode => _mode;

  void setMode(String newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }
}
