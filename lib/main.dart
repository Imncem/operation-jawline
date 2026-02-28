import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/mission/mission_bloc.dart';
import 'bloc/mission/mission_event.dart';
import 'repository/local_mission_repository.dart';
import 'screens/launch_splash_screen.dart';
import 'settings/reminder_settings_controller.dart';
import 'settings/settings_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OperationJawlineApp()));
}

class OperationJawlineApp extends ConsumerWidget {
  const OperationJawlineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(feedbackSettingsProvider);
    ref.watch(reminderSettingsProvider);

    return RepositoryProvider(
      create: (_) => LocalMissionRepository(),
      child: BlocProvider(
        create: (context) => MissionBloc(
          missionRepository: context.read<LocalMissionRepository>(),
        )..add(const LoadMissionRequested()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Operation: Jawline',
          theme: AppTheme.darkTheme(),
          home: const LaunchSplashScreen(),
        ),
      ),
    );
  }
}
