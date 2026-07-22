import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'important_documents_screen.dart';
import 'my_tasks_screen.dart';
import 'password_vault_screen.dart';
import 'secretary_screen.dart';
import 'secure_memory_screen.dart';
import 'smart_contacts_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const double _outerPadding = 16;
  static const double _gridGap = 12;
  static const double _minimumCardHeight = 132;

  @override
  Widget build(BuildContext context) {
    final modules = <_DashboardModule>[
      _DashboardModule(
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
      _DashboardModule(
        icon: Icons.note_alt,
        title: 'Secure Memory',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecureMemoryScreen(),
            ),
          );
        },
      ),
      _DashboardModule(
        icon: Icons.folder,
        title: 'Important Documents',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ImportantDocumentsScreen(),
            ),
          );
        },
      ),
      _DashboardModule(
        icon: Icons.contacts,
        title: 'Smart Contacts',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SmartContactsScreen(),
            ),
          );
        },
      ),
      _DashboardModule(
        icon: Icons.auto_awesome,
        title: 'AI Assistant',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecretaryScreen()),
          );
        },
      ),
      _DashboardModule(
        icon: Icons.lock,
        title: 'Password Vault',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PasswordVaultScreen(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final targetCardHeight =
                (availableHeight - (_outerPadding * 2) - (_gridGap * 2)) / 3;
            final cardHeight = math.max(_minimumCardHeight, targetCardHeight);

            return GridView.builder(
              padding: const EdgeInsets.all(_outerPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: _gridGap,
                mainAxisSpacing: _gridGap,
                mainAxisExtent: cardHeight,
              ),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return _DashboardCard(
                  icon: module.icon,
                  title: module.title,
                  onTap: module.onTap,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DashboardModule {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _DashboardModule({required this.icon, required this.title, this.onTap});
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _DashboardCard({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1.5,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: colorScheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(icon, size: 30, color: colorScheme.primary),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
