import 'package:flutter/material.dart';

import '../services/voice_service.dart';
import '../widgets/feature_card.dart';
import 'smart_reminders_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LifePilot AI'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Day 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'What would you like me to help you with?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: [
                  FeatureCard(
                    icon: Icons.notifications_active,
                    title: 'Smart Tasks',
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
                  ),
                  const FeatureCard(
                    icon: Icons.folder,
                    title: 'Important Documents',
                  ),
                  const FeatureCard(icon: Icons.contacts, title: 'Contacts'),
                  const FeatureCard(
                    icon: Icons.wb_sunny,
                    title: 'Daily Briefing',
                  ),
                  const FeatureCard(
                    icon: Icons.auto_awesome,
                    title: 'AI Assistant',
                  ),
                  FeatureCard(
                    icon: Icons.record_voice_over,
                    title: 'Test Voice',
                    onTap: () async {
                      await VoiceService.speak(
                        'LifePilot voice reminder test is working',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
