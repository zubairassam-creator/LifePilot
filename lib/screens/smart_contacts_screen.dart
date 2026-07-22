import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/smart_contact.dart';
import '../services/smart_contacts_service.dart';

class SmartContactsScreen extends StatefulWidget {
  const SmartContactsScreen({super.key});

  @override
  State<SmartContactsScreen> createState() => _SmartContactsScreenState();
}

class _SmartContactsScreenState extends State<SmartContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SmartContact> _contacts = const <SmartContact>[];
  bool _loading = true;
  bool _permissionDenied = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });
    try {
      var allowed = await SmartContactsService.hasPermission();
      if (!allowed) {
        allowed = await SmartContactsService.requestPermission();
      }
      if (!allowed) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }
      final contacts = await SmartContactsService.getContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(error.message ?? 'Unable to load contacts.');
    }
  }

  List<SmartContact> get _filteredContacts {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _contacts;
    return _contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(query) ||
          contact.phones.any((phone) => phone.toLowerCase().contains(query)) ||
          contact.emails.any((email) => email.toLowerCase().contains(query));
    }).toList(growable: false);
  }

  Future<void> _showContactEditor({SmartContact? contact}) async {
    final nameController = TextEditingController(text: contact?.displayName ?? '');
    final phoneController = TextEditingController(
      text: contact?.phones.isNotEmpty == true ? contact!.phones.first : '',
    );
    final emailController = TextEditingController(
      text: contact?.emails.isNotEmpty == true ? contact!.emails.first : '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a name.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      return;
    }

    try {
      if (contact == null) {
        await SmartContactsService.addContact(
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
        );
      } else {
        await SmartContactsService.updateContact(
          id: contact.id,
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
        );
      }
      await _loadContacts();
      _showMessage(contact == null ? 'Contact saved.' : 'Contact updated.');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Unable to save contact.');
    } finally {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
    }
  }

  Future<void> _confirmDelete(SmartContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          'Delete ${contact.displayName} from your phone contacts? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SmartContactsService.deleteContact(contact.id);
      if (!mounted) return;
      Navigator.maybePop(context);
      await _loadContacts();
      _showMessage('Contact deleted.');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Unable to delete contact.');
    }
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    _showMessage('$label copied.');
  }

  void _showContactDetails(SmartContact contact) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 38,
                    child: Text(
                      _initials(contact.displayName),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    contact.displayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  for (final phone in contact.phones)
                    _ContactValueTile(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: phone,
                      actions: [
                        IconButton(
                          tooltip: 'Call',
                          onPressed: () => SmartContactsService.call(phone),
                          icon: const Icon(Icons.call),
                        ),
                        IconButton(
                          tooltip: 'WhatsApp',
                          onPressed: () => SmartContactsService.openWhatsApp(phone),
                          icon: const Icon(Icons.chat),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: () => _copy(phone, 'Phone number'),
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  for (final email in contact.emails)
                    _ContactValueTile(
                      icon: Icons.email,
                      label: 'Email',
                      value: email,
                      actions: [
                        IconButton(
                          tooltip: 'Email',
                          onPressed: () => SmartContactsService.email(email),
                          icon: const Icon(Icons.send),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: () => _copy(email, 'Email address'),
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  if (contact.phones.isEmpty && contact.emails.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'No phone number or email address is stored for this contact.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showContactEditor(contact: contact);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(contact),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return '${words.first.characters.first}${words.last.characters.first}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filteredContacts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Contacts'),
        actions: [
          IconButton(
            tooltip: 'Refresh contacts',
            onPressed: _loading ? null : _loadContacts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _permissionDenied ? null : () => _showContactEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Contact'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search name, phone or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _permissionDenied
                      ? _PermissionView(onRetry: _loadContacts)
                      : contacts.isEmpty
                          ? const _EmptyContactsView()
                          : RefreshIndicator(
                              onRefresh: _loadContacts,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                                itemCount: contacts.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  final subtitle = contact.phones.isNotEmpty
                                      ? contact.phones.first
                                      : contact.emails.isNotEmpty
                                          ? contact.emails.first
                                          : 'No phone or email';
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(_initials(contact.displayName)),
                                    ),
                                    title: Text(
                                      contact.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: contact.phones.isEmpty
                                        ? const Icon(Icons.chevron_right)
                                        : IconButton(
                                            tooltip: 'Call',
                                            onPressed: () => SmartContactsService.call(
                                              contact.phones.first,
                                            ),
                                            icon: const Icon(Icons.call),
                                          ),
                                    onTap: () => _showContactDetails(contact),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactValueTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Widget> actions;

  const _ContactValueTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  SelectableText(value),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.contacts_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Contacts permission is required',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'LifePilot needs permission to display and manage the contacts saved on your phone.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.lock_open),
              label: const Text('Allow Contacts'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContactsView extends StatelessWidget {
  const _EmptyContactsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No contacts found. Tap “Add Contact” to create one.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
