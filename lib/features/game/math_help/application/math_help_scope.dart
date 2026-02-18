import 'package:flutter/widgets.dart';

import 'math_help_controller.dart';

/// Exposes [MathHelpController] to game widgets without direct coupling.
class MathHelpScope extends InheritedNotifier<MathHelpController> {
  final MathHelpController controller;

  const MathHelpScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  static MathHelpController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MathHelpScope>();
    if (scope == null) {
      throw FlutterError('MathHelpScope.of() called without MathHelpScope.');
    }
    return scope.controller;
  }

  static MathHelpController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MathHelpScope>()
        ?.controller;
  }
}
