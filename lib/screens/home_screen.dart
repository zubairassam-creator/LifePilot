import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../widgets/feature_card.dart';
import 'my_tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LifePilot AI'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Tagline
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Your Personal Secretary",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/lifepilot_logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 24),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Day 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            'What would you like me to help you with?',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: GridView.count(
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.08,
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

                    const FeatureCard(
                      icon: Icons.wb_sunny,
                      title: 'Daily Briefing',
                      subtitle: 'Start your day',
                    ),

                    const FeatureCard(
                      icon: Icons.auto_awesome,
                      title: 'AI Assistant',
                      subtitle: 'Ask anything',
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
            ],
          ),
        ),
      ),
    );
  }
}
