import 'package:flutter/foundation.dart';

import '../domain/math_help_context.dart';

/// Holds the active math-help context for the currently visible question.
class MathHelpController extends ChangeNotifier {
  MathHelpContext? _context;

  MathHelpContext? get context => _context;

  void setContext(MathHelpContext context) {
    if (_context == context) return;
    _context = context;
    notifyListeners();
  }

  void clearContext() {
    if (_context == null) return;
    _context = null;
    notifyListeners();
  }
}
