import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_settings_service.dart';
import '../services/sfx_service.dart';
import '../settings/reminder_settings.dart';
import '../settings/reminder_settings_controller.dart';
import '../settings/settings_controller.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final feedbackAsync = ref.watch(feedbackSettingsProvider);
    final reminderAsync = ref.watch(reminderSettingsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: settingsAsync.when(
        data: (settings) => feedbackAsync.when(
          data: (feedback) => reminderAsync.when(
            data: (reminders) =>
                _buildContent(context, ref, settings, feedback, reminders),
            loading: () => _TacticalLoader(),
            error: (_, __) =>
                const _TacticalError(message: 'UNABLE TO LOAD CONFIGURATION'),
          ),
          loading: () => _TacticalLoader(),
          error: (_, __) =>
              const _TacticalError(message: 'UNABLE TO LOAD CONFIGURATION'),
        ),
        loading: () => _TacticalLoader(),
        error: (_, __) =>
            const _TacticalError(message: 'UNABLE TO LOAD CONFIGURATION'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F0D),
          border: Border(bottom: BorderSide(color: _amber, width: 1.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: _amber,
                      size: 18,
                    ),
                  ),
                ),
                Container(width: 3, height: 32, color: _amber),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OP: JAWLINE  //  CONFIGURATION',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _amber.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _text,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
    dynamic feedback,
    ReminderSettings reminders,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── System Parameters ────────────────────────────────────
        _SectionDivider(label: 'SYSTEM PARAMETERS'),
        const SizedBox(height: 12),

        _TacticalToggleTile(
          tag: '01',
          label: 'SOUND',
          sublabel: 'Audio feedback during protocol',
          value: feedback.soundEnabled,
          onChanged: (value) async {
            await ref
                .read(feedbackSettingsProvider.notifier)
                .setSoundEnabled(value);
            await ref.read(appSettingsProvider.notifier).update(
                  (current) => current.copyWith(soundEnabled: value),
                );
          },
        ),
        const SizedBox(height: 10),

        _TacticalToggleTile(
          tag: '02',
          label: 'HAPTICS',
          sublabel: 'Tactile feedback on interactions',
          value: feedback.hapticsEnabled,
          onChanged: (value) async {
            await ref
                .read(feedbackSettingsProvider.notifier)
                .setHapticsEnabled(value);
            await ref.read(appSettingsProvider.notifier).update(
                  (current) => current.copyWith(hapticsEnabled: value),
                );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Note: some emulators do not support vibration.',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: _text.withValues(alpha: 0.45),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'TEST SOUND',
                onTap: () => SfxService.play('changing.wav'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'TEST HAPTICS',
                onTap: () async {
                  await SfxService.medium();
                  await SfxService.selection();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Operational Parameters ───────────────────────────────
        _SectionDivider(label: 'REMINDERS'),
        const SizedBox(height: 12),
        _ReminderTile(
          tag: '06',
          label: 'WORKOUT REMINDER',
          enabled: reminders.workoutReminderEnabled,
          timeLabel: _formatTime(
            reminders.workoutReminderHour,
            reminders.workoutReminderMinute,
          ),
          onToggle: (value) async {
            final granted = await ref
                .read(reminderSettingsProvider.notifier)
                .setWorkoutReminderEnabled(value);
            if (!granted && context.mounted) {
              _showPermissionSnackBar(context);
            }
          },
          onChangeTime: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: reminders.workoutReminderHour,
                minute: reminders.workoutReminderMinute,
              ),
            );
            if (picked == null || !context.mounted) return;
            final granted = await ref
                .read(reminderSettingsProvider.notifier)
                .updateWorkoutReminderTime(picked);
            if (!granted && context.mounted) {
              _showPermissionSnackBar(context);
            }
          },
        ),
        const SizedBox(height: 10),
        _ReminderTile(
          tag: '07',
          label: 'CHECK-IN REMINDER',
          enabled: reminders.checkInReminderEnabled,
          timeLabel: _formatTime(
            reminders.checkInReminderHour,
            reminders.checkInReminderMinute,
          ),
          onToggle: (value) async {
            final granted = await ref
                .read(reminderSettingsProvider.notifier)
                .setCheckInReminderEnabled(value);
            if (!granted && context.mounted) {
              _showPermissionSnackBar(context);
            }
          },
          onChangeTime: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: reminders.checkInReminderHour,
                minute: reminders.checkInReminderMinute,
              ),
            );
            if (picked == null || !context.mounted) return;
            final granted = await ref
                .read(reminderSettingsProvider.notifier)
                .updateCheckInReminderTime(picked);
            if (!granted && context.mounted) {
              _showPermissionSnackBar(context);
            }
          },
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'TEST NOTIFICATION',
          onTap: () async {
            final granted = await ref
                .read(reminderSettingsProvider.notifier)
                .showTestNotification();
            if (!granted && context.mounted) {
              _showPermissionSnackBar(context);
            }
          },
        ),
        const SizedBox(height: 24),
        _SectionDivider(label: 'OPERATIONAL PARAMETERS'),
        const SizedBox(height: 12),

        _TacticalSelectTile<String>(
          tag: '03',
          label: 'UNITS',
          sublabel: 'Body mass measurement standard',
          value: settings.units,
          options: const [
            _Option(value: 'kg', label: 'KG', sublabel: 'Kilograms'),
            _Option(value: 'lbs', label: 'LBS', sublabel: 'Pounds'),
          ],
          onChanged: (value) async {
            SfxService.selection();
            await ref.read(appSettingsProvider.notifier).update(
                  (current) => current.copyWith(units: value),
                );
          },
        ),
        const SizedBox(height: 10),

        _TacticalSelectTile<String>(
          tag: '04',
          label: 'EQUIPMENT',
          sublabel: 'Available field gear',
          value: settings.equipmentPreference,
          options: const [
            _Option(
                value: 'minimal',
                label: 'MINIMAL',
                sublabel: 'Bodyweight only'),
            _Option(
                value: 'dumbbells',
                label: 'DUMBBELLS',
                sublabel: 'Free weights'),
          ],
          onChanged: (value) async {
            SfxService.selection();
            await ref.read(appSettingsProvider.notifier).update(
                  (current) => current.copyWith(equipmentPreference: value),
                );
          },
        ),
        const SizedBox(height: 10),

        _TacticalSelectTile<String>(
          tag: '05',
          label: 'DURATION',
          sublabel: 'Protocol time allocation',
          value: settings.workoutDurationPreference,
          options: const [
            _Option(value: 'short', label: 'SHORT', sublabel: '~20 minutes'),
            _Option(
                value: 'standard', label: 'STANDARD', sublabel: '~40 minutes'),
            _Option(value: 'long', label: 'LONG', sublabel: '~60 minutes'),
          ],
          onChanged: (value) async {
            SfxService.selection();
            await ref.read(appSettingsProvider.notifier).update(
                  (current) =>
                      current.copyWith(workoutDurationPreference: value),
                );
          },
        ),
      ],
    );
  }

  static String _formatTime(int hour, int minute) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
    final paddedMinute = minute.toString().padLeft(2, '0');
    return '$normalizedHour:$paddedMinute $suffix';
  }

  static void _showPermissionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications disabled by system permission.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Section Divider ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: _amber),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: _amber,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: _amber.withValues(alpha: 0.2))),
      ],
    );
  }
}

// ─── Toggle Tile ─────────────────────────────────────────────────────────────

class _TacticalToggleTile extends StatelessWidget {
  final String tag;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TacticalToggleTile({
    required this.tag,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(
            color: value
                ? _amber.withValues(alpha: 0.35)
                : _dim.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Tag
            Text(
              tag,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: value ? _amber.withValues(alpha: 0.5) : _dim,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            Container(
                width: 1,
                height: 28,
                color: value
                    ? _amber.withValues(alpha: 0.25)
                    : _dim.withValues(alpha: 0.3)),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: value ? _text : _text.withValues(alpha: 0.5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: _text.withValues(alpha: 0.35),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Custom toggle
            _TacticalSwitch(value: value),
          ],
        ),
      ),
    );
  }
}

class _TacticalSwitch extends StatelessWidget {
  final bool value;

  const _TacticalSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 20,
      decoration: BoxDecoration(
        color: value ? _amber.withValues(alpha: 0.15) : Colors.transparent,
        border: Border.all(
          color: value ? _amber : _dim,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            value ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16,
            height: 18,
            color: value ? _amber : _dim,
            margin: const EdgeInsets.all(1),
          ),
        ],
      ),
    );
  }
}

// ─── Select Tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.tag,
    required this.label,
    required this.enabled,
    required this.timeLabel,
    required this.onToggle,
    required this.onChangeTime,
  });

  final String tag;
  final String label;
  final bool enabled;
  final String timeLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChangeTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(
          color: enabled
              ? _amber.withValues(alpha: 0.35)
              : _dim.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tag,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: enabled ? _amber.withValues(alpha: 0.55) : _dim,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: enabled ? _text : _text.withValues(alpha: 0.6),
                    letterSpacing: 2,
                  ),
                ),
              ),
              _TacticalSwitch(value: enabled),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'TIME // $timeLabel',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _text.withValues(alpha: 0.55),
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: enabled ? 'DISABLE' : 'ENABLE',
                  onTap: () => onToggle(!enabled),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'CHANGE TIME',
                  onTap: onChangeTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: _amber.withValues(alpha: 0.55)),
          color: _amber.withValues(alpha: 0.08),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _amber,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Option<T> {
  final T value;
  final String label;
  final String sublabel;

  const _Option(
      {required this.value, required this.label, required this.sublabel});
}

class _TacticalSelectTile<T> extends StatelessWidget {
  final String tag;
  final String label;
  final String sublabel;
  final T value;
  final List<_Option<T>> options;
  final ValueChanged<T> onChanged;

  const _TacticalSelectTile({
    required this.tag,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: _amber.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                    width: 1,
                    height: 24,
                    color: _amber.withValues(alpha: 0.25)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _text,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _text.withValues(alpha: 0.35),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Options row
          Container(
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: _amber.withValues(alpha: 0.1))),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: options.map((opt) {
                final isSelected = opt.value == value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(opt.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _amber.withValues(alpha: 0.12)
                            : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected ? _amber : _dim.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? _amber : _dim,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt.sublabel,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 7,
                              color: isSelected
                                  ? _amber.withValues(alpha: 0.5)
                                  : _dim.withValues(alpha: 0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Loader ──────────────────────────────────────────────────────────

class _TacticalLoader extends StatefulWidget {
  @override
  State<_TacticalLoader> createState() => _TacticalLoaderState();
}

class _TacticalLoaderState extends State<_TacticalLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _amber.withValues(alpha: _controller.value * 0.8),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING CONFIGURATION...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _amber.withValues(alpha: 0.6),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Error ───────────────────────────────────────────────────────────

class _TacticalError extends StatelessWidget {
  final String message;

  const _TacticalError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off_outlined, color: _dim, size: 28),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _dim,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
