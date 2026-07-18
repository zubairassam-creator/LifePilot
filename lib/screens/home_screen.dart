import 'package:flutter/material.dart';
import '../models/life_memory.dart';
import '../models/lifepilot_task.dart';
import '../services/life_memory_repository.dart';
import '../services/task_storage_service.dart';
import '../services/voice_service.dart';
import '../widgets/feature_card.dart';
import 'my_tasks_screen.dart';
import 'secretary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Map<String, int> _briefing() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final tasks = TaskStorageService.getAllTasks();
    final memories = LifeMemoryRepository.getAll();
    return {
      'overdue': tasks.where((t) => t.status != TaskStatus.completed && t.dueDateTime != null && t.dueDateTime!.isBefore(now)).length,
      'today': tasks.where((t) => t.status == TaskStatus.pending && t.dueDateTime != null && t.dueDateTime!.year == today.year && t.dueDateTime!.month == today.month && t.dueDateTime!.day == today.day).length,
      'upcoming': tasks.where((t) => t.status == TaskStatus.pending && t.dueDateTime != null && t.dueDateTime!.isAfter(tomorrow)).length,
      'expiries': memories.where((m) => m.type == LifeMemoryType.expiry && m.dueDate != null && m.dueDate!.difference(now).inDays <= 45).length,
      'events': memories.where((m) => (m.type == LifeMemoryType.birthday || m.type == LifeMemoryType.event) && m.eventDate != null).length,
      'loans': memories.where((m) => m.type == LifeMemoryType.loanTaken && m.status == LifeMemoryStatus.open).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final briefing = _briefing();
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
                            'Here is what needs attention now.',
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

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today and Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Overdue: ${briefing['overdue']} • Today: ${briefing['today']} • Upcoming: ${briefing['upcoming']}'),
                      Text('Expiries soon: ${briefing['expiries']} • Birthdays/events: ${briefing['events']} • Open loans: ${briefing['loans']}'),
                    ],
                  ),
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

                    FeatureCard(
                      icon: Icons.auto_awesome,
                      title: 'AI Assistant',
                      subtitle: 'Ask anything',
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
            ],
          ),
        ),
      ),
    );
  }
}
