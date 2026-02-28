import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bloc/mission/mission_bloc.dart';
import '../bloc/mission/mission_event.dart';
import '../bloc/mission/mission_state.dart';
import '../models/daily_check_in.dart';
import '../models/enums.dart';
import '../services/mission_progress_service.dart';
import '../services/sfx_service.dart';
import '../settings/reminder_settings_controller.dart';
import '../widgets/rise_in.dart';
import '../widgets/recommendation_card.dart';
import 'promotion_screen.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sleepController = TextEditingController();
  final _waterController = TextEditingController();
  final _weightController = TextEditingController();

  double _energyLevel = 6;
  double _puffinessRating = 3;
  Mood _mood = Mood.good;

  // ── Palette ────────────────────────────────────────────────────────────────
  static const _amber = Color(0xFFD4A017);
  static const _green = Color(0xFF4CAF50);

  @override
  void dispose() {
    _sleepController.dispose();
    _waterController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MissionBloc, MissionState>(
      listenWhen: (previous, current) =>
          previous.status == MissionStatus.submitting &&
          current.status != MissionStatus.submitting,
      listener: (context, state) async {
        if (state.status == MissionStatus.ready &&
            state.snapshot.recommendation != null) {
          final container = ProviderScope.containerOf(context, listen: false);
          final mission = container.read(missionServiceProvider);
          await mission.setDisciplineChain(state.snapshot.disciplineChain);
          final latest = state.snapshot.latestCheckIn;
          if (latest != null) {
            await mission.appendCheckIn(latest);
          }
          await mission.markCheckInDone(DateTime.now());
          final update = await mission.recomputeAndAwardXP(DateTime.now());
          await container
              .read(reminderSettingsProvider.notifier)
              .rescheduleCheckInForNextDay();
          container.invalidate(todayMissionProvider);
          container.invalidate(userProgressProvider);
          if (!context.mounted) return;

          _showTacticalSnackBar(
            context,
            'TRANSMISSION LOGGED // +${update.xpDelta} XP (MISSION ${(update.dailyCompletion * 100).round()}%)',
            isError: false,
          );
          if (update.promoted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PromotionScreen(
                  previousRank: update.previousRankName,
                  newRank: update.rankName,
                ),
              ),
            );
          }
          return;
        }
        if (state.status == MissionStatus.failure) {
          _showTacticalSnackBar(
            context,
            state.errorMessage?.toUpperCase() ?? 'TRANSMISSION FAILED',
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == MissionStatus.submitting;

        return Theme(
          data: _tacticalFormTheme(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              // ── Header ───────────────────────────────────────────────
              _TacticalSectionHeader(
                tag: 'STATUS REPORT',
                title: 'DAILY CHECK-IN',
                subtitle: 'Submit intel. Maintain discipline.',
              ),
              const SizedBox(height: 24),

              // ── Form ─────────────────────────────────────────────────
              RiseIn(
                delay: const Duration(milliseconds: 80),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Energy Level
                      _FieldDivider(tag: '01', label: 'ENERGY LEVEL'),
                      const SizedBox(height: 10),
                      _TacticalSlider(
                        value: _energyLevel,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        displayValue: '${_energyLevel.round()} / 10',
                        accentColor: _green,
                        onChanged: (v) => setState(() => _energyLevel = v),
                      ),
                      const SizedBox(height: 20),

                      // Sleep
                      _FieldDivider(tag: '02', label: 'SLEEP HOURS'),
                      const SizedBox(height: 10),
                      _TacticalTextField(
                        controller: _sleepController,
                        hint: 'e.g. 7.5',
                        suffix: 'HRS',
                        validator: _requiredNumber,
                      ),
                      const SizedBox(height: 20),

                      // Water
                      _FieldDivider(tag: '03', label: 'HYDRATION INPUT'),
                      const SizedBox(height: 10),
                      _TacticalTextField(
                        controller: _waterController,
                        hint: 'e.g. 2.5',
                        suffix: 'L',
                        validator: _requiredNumber,
                      ),
                      const SizedBox(height: 20),

                      // Weight
                      _FieldDivider(tag: '04', label: 'BODY MASS (OPTIONAL)'),
                      const SizedBox(height: 10),
                      _TacticalTextField(
                        controller: _weightController,
                        hint: 'e.g. 78.4',
                        suffix: 'KG',
                        validator: null,
                      ),
                      const SizedBox(height: 20),

                      // Mood
                      _FieldDivider(tag: '05', label: 'PSYCHOLOGICAL STATE'),
                      const SizedBox(height: 10),
                      _TacticalMoodSelector(
                        selected: _mood,
                        onChanged: (m) => setState(() => _mood = m),
                      ),
                      const SizedBox(height: 20),

                      // Puffiness
                      _FieldDivider(tag: '06', label: 'FACE PUFFINESS INDEX'),
                      const SizedBox(height: 10),
                      _TacticalSlider(
                        value: _puffinessRating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        displayValue: '${_puffinessRating.round()} / 5',
                        accentColor: _amber,
                        onChanged: (v) => setState(() => _puffinessRating = v),
                      ),
                      const SizedBox(height: 28),

                      // Submit
                      _TacticalSubmitButton(
                        isSubmitting: isSubmitting,
                        onPressed: () => _submit(state),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recommendation ───────────────────────────────────────
              if (state.snapshot.recommendation != null) ...[
                const SizedBox(height: 28),
                _FieldDivider(tag: '///', label: 'MISSION DIRECTIVE'),
                const SizedBox(height: 12),
                RiseIn(
                  delay: const Duration(milliseconds: 160),
                  child: RecommendationCard(
                    recommendation: state.snapshot.recommendation!,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  ThemeData _tacticalFormTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
    );
  }

  void _showTacticalSnackBar(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? Colors.red.withValues(alpha: 0.12)
            : _green.withValues(alpha: 0.12),
        shape: Border(
          left: BorderSide(
            color: isError ? Colors.red : _green,
            width: 3,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 1.5,
            color: isError ? Colors.red : _green,
          ),
        ),
      ),
    );
  }

  String? _requiredNumber(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return 'ENTER A VALID NUMBER';
    return null;
  }

  void _submit(MissionState state) {
    if (!_formKey.currentState!.validate()) return;

    final sleep = double.parse(_sleepController.text.trim());
    final water = double.parse(_waterController.text.trim());
    final weightRaw = _weightController.text.trim();

    final checkIn = DailyCheckIn(
      energy: _energyLevel.round(),
      sleepHours: sleep,
      waterLiters: water,
      weightKg: weightRaw.isEmpty ? null : double.tryParse(weightRaw),
      mood: _mood,
      puffiness: _puffinessRating.round(),
      disciplineChain: state.snapshot.disciplineChain,
      lastCheckIn: DateTime.now(),
    );

    context.read<MissionBloc>().add(CheckInSubmitted(checkIn));
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _TacticalSectionHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;

  const _TacticalSectionHeader({
    required this.tag,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: const Color(0xFFD4A017)),
            const SizedBox(width: 8),
            Text(
              tag,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Color(0xFFD4A017),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCDD4C0),
            letterSpacing: 4,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: const Color(0xFFCDD4C0).withValues(alpha: 0.45),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Field Divider ────────────────────────────────────────────────────────────

class _FieldDivider extends StatelessWidget {
  final String tag;
  final String label;

  const _FieldDivider({required this.tag, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          tag,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: Color(0xFFD4A017),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 10, color: const Color(0xFFD4A017)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: Color(0xFFD4A017),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFD4A017).withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

// ─── Tactical Text Field ──────────────────────────────────────────────────────

class _TacticalTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final String? Function(String?)? validator;

  const _TacticalTextField({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.validator,
  });

  @override
  State<_TacticalTextField> createState() => _TacticalTextFieldState();
}

class _TacticalTextFieldState extends State<_TacticalTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final amber = const Color(0xFFD4A017);
    final surface = const Color(0xFF111411);

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(
            color: _focused ? amber : amber.withValues(alpha: 0.25),
            width: _focused ? 1.5 : 1,
          ),
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: widget.validator,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            color: Color(0xFFCDD4C0),
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: const Color(0xFF3A4238),
              letterSpacing: 1,
            ),
            suffixText: widget.suffix,
            suffixStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: amber.withValues(alpha: 0.7),
              letterSpacing: 2,
            ),
            errorStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Colors.red,
              letterSpacing: 1,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ─── Tactical Slider ──────────────────────────────────────────────────────────

class _TacticalSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _TacticalSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111411),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.round().toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: const Color(0xFF3A4238),
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                  color: accentColor.withValues(alpha: 0.08),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Text(
                max.round().toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: const Color(0xFF3A4238),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.15),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.1),
              valueIndicatorColor: accentColor,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.round().toString(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Mood Selector ───────────────────────────────────────────────────

class _TacticalMoodSelector extends StatelessWidget {
  final Mood selected;
  final ValueChanged<Mood> onChanged;

  const _TacticalMoodSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _moodIcons = {
    Mood.great: (Icons.sentiment_very_satisfied_outlined, 'GREAT'),
    Mood.good: (Icons.sentiment_satisfied_outlined, 'GOOD'),
    Mood.neutral: (Icons.sentiment_neutral_outlined, 'NEUTRAL'),
    Mood.low: (Icons.sentiment_dissatisfied_outlined, 'LOW'),
    Mood.stressed: (
      Icons.sentiment_very_dissatisfied_outlined,
      'STRESSED',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111411),
        border:
            Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: Mood.values.map((mood) {
          final isSelected = mood == selected;
          final info = _moodIcons[mood]!;
          final amber = const Color(0xFFD4A017);

          return GestureDetector(
            onTap: () {
              SfxService.tap();
              onChanged(mood);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? amber.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? amber : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    info.$1,
                    size: 22,
                    color: isSelected ? amber : const Color(0xFF3A4238),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.$2,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      letterSpacing: 1,
                      color: isSelected ? amber : const Color(0xFF3A4238),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Tactical Submit Button ───────────────────────────────────────────────────

class _TacticalSubmitButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _TacticalSubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  State<_TacticalSubmitButton> createState() => _TacticalSubmitButtonState();
}

class _TacticalSubmitButtonState extends State<_TacticalSubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final amber = const Color(0xFFD4A017);
    final disabled = widget.isSubmitting;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              SfxService.tap();
              widget.onPressed();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: disabled
              ? amber.withValues(alpha: 0.05)
              : _pressed
                  ? amber.withValues(alpha: 0.25)
                  : amber.withValues(alpha: 0.12),
          border: Border.all(
            color: disabled ? amber.withValues(alpha: 0.2) : amber,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (disabled)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: amber.withValues(alpha: 0.5),
                ),
              )
            else
              Icon(Icons.send_outlined, size: 14, color: amber),
            const SizedBox(width: 10),
            Text(
              disabled ? 'TRANSMITTING...' : 'SUBMIT FIELD REPORT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: disabled ? amber.withValues(alpha: 0.35) : amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
