import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/lifepilot_task.dart';
import 'screens/home_screen.dart';
import 'services/life_memory_repository.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'services/task_storage_service.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(ReminderModeAdapter());
  Hive.registerAdapter(RepeatTypeAdapter());
  Hive.registerAdapter(LifePilotTaskAdapter());

  // Open local databases
  await SyncService.initialize();
  await TaskStorageService.initialize();
  await LifeMemoryRepository.initialize();
  await SyncService.syncPendingChanges();

  // Initialize Services
  await NotificationService.initialize();
  await VoiceService.initialize();

  runApp(const LifePilotApp());
}

class LifePilotApp extends StatelessWidget {
  const LifePilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifePilot AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
