import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../services/sfx_service.dart';
import '../settings/settings_repo.dart';
import 'app_shell_screen.dart';
import 'onboarding_screen.dart';

class LaunchSplashScreen extends StatefulWidget {
  const LaunchSplashScreen({super.key});

  @override
  State<LaunchSplashScreen> createState() => _LaunchSplashScreenState();
}

class _LaunchSplashScreenState extends State<LaunchSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _fadeController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _playSequence();
  }

  Future<void> _playSequence() async {
    await _logoController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await _fadeController.forward();
    if (!mounted) return;
    final settings = await AppSettingsService().load();
    final feedback = await SettingsRepo().load();
    if (!mounted) return;
    SfxService.configure(
      soundEnabled: feedback.soundEnabled,
      hapticsOn: feedback.hapticsEnabled,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => settings.onboardingShown
            ? const AppShellScreen()
            : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0C0A);
    const accent = Color(0xFFD4A017);
    const iconPath = 'assets/images/app_icon.png';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, _) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: accent.withValues(alpha: 0.7),
                            ),
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Image.asset(
                              iconPath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.shield_moon,
                                size: 52,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'OPERATION: JAWLINE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFFCDD4C0),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PROTOCOL INITIALIZING',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 10,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
