import 'package:flutter/material.dart';

import '../services/voice_service.dart';
import '../widgets/feature_card.dart';
import 'my_tasks_screen.dart';
import 'secretary_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: [
            FeatureCard(
              icon: Icons.notifications_active,
              title: 'Smart Tasks',
              subtitle: 'Never miss a task',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmartRemindersScreen(),
                  ),
                );
              },
            ),
            const FeatureCard(
              icon: Icons.note_alt,
              title: 'Memory Notes',
              subtitle: 'Capture ideas',
            ),
            const FeatureCard(
              icon: Icons.folder,
              title: 'Important Documents',
              subtitle: 'Keep files safe',
            ),
            const FeatureCard(
              icon: Icons.contacts,
              title: 'Contacts',
              subtitle: 'People that matter',
            ),
            FeatureCard(
              icon: Icons.auto_awesome,
              title: 'AI Assistant',
              subtitle: 'Full-screen chat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecretaryScreen(),
                  ),
                );
              },
            ),
            FeatureCard(
              icon: Icons.record_voice_over,
              title: 'Test Voice',
              subtitle: 'Check speech',
              onTap: () async {
                await VoiceService.speak(
                  'LifePilot voice reminder test is working',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
