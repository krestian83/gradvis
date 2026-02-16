import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/domain/profile_state.dart';
import '../domain/wizard_state.dart';
import 'widgets/emoji_picker_step.dart';
import 'widgets/name_input_step.dart';
import 'widgets/trinn_select_step.dart';

class ProfileWizardScreen extends StatefulWidget {
  final ProfileState profileState;

  const ProfileWizardScreen({super.key, required this.profileState});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final _wizard = WizardState();
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _wizard.addListener(_onStepChanged);
  }

  @override
  void dispose() {
    _wizard.removeListener(_onStepChanged);
    _wizard.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged() {
    _pageController.animateToPage(
      _wizard.step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final profile = Profile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _wizard.name.trim(),
      emoji: _wizard.emoji,
      trinn: _wizard.trinn,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await widget.profileState.add(profile);
    if (mounted) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: ListenableBuilder(
        listenable: _wizard,
        builder: (context, _) {
          return Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(
                    onPressed: () {
                      if (_wizard.step > 0) {
                        _wizard.previousStep();
                      } else {
                        context.go(RouteNames.profileSelect);
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    EmojiPickerStep(
                      selectedEmoji: _wizard.emoji,
                      onEmojiChanged: (e) => _wizard.emoji = e,
                      onNext: _wizard.nextStep,
                    ),
                    NameInputStep(
                      emoji: _wizard.emoji,
                      name: _wizard.name,
                      onNameChanged: (n) => _wizard.name = n,
                      onNext: _wizard.canProceedFromName
                          ? _wizard.nextStep
                          : null,
                    ),
                    TrinnSelectStep(
                      emoji: _wizard.emoji,
                      name: _wizard.name,
                      selectedTrinn: _wizard.trinn,
                      onTrinnChanged: (t) => _wizard.trinn = t,
                      onStart: _finish,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
