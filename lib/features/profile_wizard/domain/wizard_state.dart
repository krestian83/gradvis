import 'package:flutter/foundation.dart';

/// Ephemeral 3-step wizard state for profile creation.
class WizardState extends ChangeNotifier {
  String _emoji = '😀';
  String _name = '';
  int _trinn = 1;
  int _step = 0;

  String get emoji => _emoji;
  String get name => _name;
  int get trinn => _trinn;
  int get step => _step;

  bool get canProceedFromName => _name.trim().isNotEmpty;

  set emoji(String value) {
    _emoji = value;
    notifyListeners();
  }

  set name(String value) {
    _name = value;
    notifyListeners();
  }

  set trinn(int value) {
    _trinn = value;
    notifyListeners();
  }

  void nextStep() {
    if (_step < 2) {
      _step++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_step > 0) {
      _step--;
      notifyListeners();
    }
  }
}
