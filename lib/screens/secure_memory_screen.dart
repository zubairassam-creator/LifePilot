import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:uuid/uuid.dart';

import '../models/secure_memory_note.dart';
import '../services/secure_memory_service.dart';
import '../services/vault_authentication_service.dart';
import '../services/vault_screen_security_service.dart';

class SecureMemoryScreen extends StatefulWidget {
  const SecureMemoryScreen({super.key});

  @override
  State<SecureMemoryScreen> createState() => _SecureMemoryScreenState();
}

class _SecureMemoryScreenState extends State<SecureMemoryScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<SecureMemoryNote> _notes = const [];
  bool _loading = true;
  bool _unlocked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VaultScreenSecurityService.enable();
    _unlockAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    VaultScreenSecurityService.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (mounted) {
        setState(() => _unlocked = false);
      }
    } else if (state == AppLifecycleState.resumed && !_unlocked) {
      _unlockAndLoad();
    }
  }

  Future<bool> _authenticate(String reason) async {
    _authenticating = true;
    try {
      return await VaultAuthenticationService.instance.authenticate(
        reason: reason,
      );
    } finally {
      _authenticating = false;
    }
  }

  Future<void> _unlockAndLoad() async {
    if (mounted) setState(() => _loading = true);
    final authenticated = await _authenticate(
      'Authenticate to open Secure Memory',
    );
    if (!mounted) return;
    if (!authenticated) {
      setState(() {
        _loading = false;
        _unlocked = false;
      });
      return;
    }
    await SecureMemoryService.instance.initialize();
    final notes = await SecureMemoryService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
      _unlocked = true;
    });
  }

  Future<void> _reload() async {
    final notes = await SecureMemoryService.instance.getAll();
    if (mounted) setState(() => _notes = notes);
  }

  Future<void> _createOrEdit([SecureMemoryNote? existing]) async {
    final result = await Navigator.push<SecureMemoryNote>(
      context,
      MaterialPageRoute(
        builder: (context) => SecureMemoryEditorScreen(note: existing),
      ),
    );
    if (result == null) return;
    await SecureMemoryService.instance.save(result);
    await _reload();
  }

  Future<void> _copy(SecureMemoryNote note) async {
    final text = note.body.trim().isEmpty
        ? note.title
        : '${note.title}\n\n${note.body}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note copied')),
    );
  }

  Future<void> _delete(SecureMemoryNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text(
          'This note and all of its attachments will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final authenticated = await _authenticate(
      'Authenticate to permanently delete this Secure Memory note',
    );
    if (!authenticated || !mounted) return;

    await SecureMemoryService.instance.delete(note);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted securely')),
    );
  }

  Future<void> _openAttachment(SecureMemoryAttachment attachment) async {
    try {
      final file = await SecureMemoryService.instance
          .createTemporaryDecryptedFile(attachment);
      final result = await OpenFilex.open(file.path);
      if (!mounted || result.type == ResultType.done) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this attachment.')),
      );
    }
  }

  List<SecureMemoryNote> get _filteredNotes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _notes;
    return _notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.body.toLowerCase().contains(query) ||
          note.attachments.any(
            (attachment) => attachment.fileName.toLowerCase().contains(query),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Memory'),
        actions: [
          if (_unlocked)
            IconButton(
              tooltip: 'New note',
              onPressed: _createOrEdit,
              icon: const Icon(Icons.note_add_outlined),
            ),
        ],
      ),
      floatingActionButton: _unlocked
          ? FloatingActionButton.extended(
              onPressed: _createOrEdit,
              icon: const Icon(Icons.add),
              label: const Text('New Note'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_unlocked
              ? _LockedView(onUnlock: _unlockAndLoad)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search title, note or attachment',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
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
                      child: _filteredNotes.isEmpty
                          ? _EmptySecureMemory(
                              hasSearch: _searchController.text.isNotEmpty,
                              onCreate: _createOrEdit,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _filteredNotes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final note = _filteredNotes[index];
                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _createOrEdit(note),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: colorScheme
                                                    .primaryContainer,
                                                child: Icon(
                                                  Icons.note_alt_outlined,
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      note.title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatDate(note.noteDate),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _createOrEdit(note);
                                                  } else if (value == 'copy') {
                                                    _copy(note);
                                                  } else if (value == 'delete') {
                                                    _delete(note);
                                                  }
                                                },
                                                itemBuilder: (context) => const [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: ListTile(
                                                      leading: Icon(Icons.edit),
                                                      title: Text('Edit'),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'copy',
                                                    child: ListTile(
                                                      leading: Icon(Icons.copy),
                                                      title: Text('Copy'),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: ListTile(
                                                      leading:
                                                          Icon(Icons.delete),
                                                      title: Text('Delete'),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (note.body.trim().isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              note.body,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          if (note.attachments.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: note.attachments
                                                  .map(
                                                    (attachment) => ActionChip(
                                                      avatar: Icon(
                                                        _attachmentIcon(
                                                          attachment.mimeType,
                                                        ),
                                                        size: 18,
                                                      ),
                                                      label: ConstrainedBox(
                                                        constraints:
                                                            const BoxConstraints(
                                                              maxWidth: 180,
                                                            ),
                                                        child: Text(
                                                          attachment.fileName,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _openAttachment(
                                                            attachment,
                                                          ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                          const SizedBox(height: 10),
                                          Text(
                                            'Modified ${_formatDateTime(note.updatedAt)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class SecureMemoryEditorScreen extends StatefulWidget {
  final SecureMemoryNote? note;

  const SecureMemoryEditorScreen({super.key, this.note});

  @override
  State<SecureMemoryEditorScreen> createState() =>
      _SecureMemoryEditorScreenState();
}

class _SecureMemoryEditorScreenState extends State<SecureMemoryEditorScreen> {
  static const _uuid = Uuid();
  static const _maximumFileBytes = 50 * 1024 * 1024;

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late DateTime _noteDate;
  late List<SecureMemoryAttachment> _attachments;
  final List<SecureMemoryAttachment> _newAttachments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    VaultScreenSecurityService.enable();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _noteDate = widget.note?.noteDate ?? DateTime.now();
    _attachments = List<SecureMemoryAttachment>.from(
      widget.note?.attachments ?? const [],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _noteDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _noteDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _noteDate.hour,
        _noteDate.minute,
      );
    });
  }

  Future<void> _showAttachmentOptions() async {
    final source = await showModalBottomSheet<_AttachmentChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () => Navigator.pop(context, _AttachmentChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              subtitle: const Text('Choose one or more images'),
              onTap: () => Navigator.pop(context, _AttachmentChoice.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              subtitle: const Text('PDF, document, audio, video or any format'),
              onTap: () => Navigator.pop(context, _AttachmentChoice.file),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      switch (source) {
        case _AttachmentChoice.camera:
          final image = await ImagePicker().pickImage(
            source: ImageSource.camera,
            imageQuality: 95,
          );
          if (image != null) await _addFile(image.path, image.name);
          break;
        case _AttachmentChoice.gallery:
          final images = await ImagePicker().pickMultiImage(imageQuality: 100);
          for (final image in images) {
            await _addFile(image.path, image.name);
          }
          break;
        case _AttachmentChoice.file:
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.any,
          );
          for (final file in result?.files ?? const <PlatformFile>[]) {
            if (file.path != null) await _addFile(file.path!, file.name);
          }
          break;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access the selected item.')),
      );
    }
  }

  Future<void> _addFile(String path, String fileName) async {
    final file = File(path);
    if (!await file.exists()) return;
    final length = await file.length();
    if (length > _maximumFileBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName is larger than the 50 MB limit.')),
      );
      return;
    }
    if (mounted) setState(() => _saving = true);
    final attachment = await SecureMemoryService.instance.encryptAttachment(
      sourcePath: path,
      fileName: fileName,
      mimeType: lookupMimeType(path) ?? 'application/octet-stream',
    );
    if (!mounted) return;
    setState(() {
      _attachments.add(attachment);
      _newAttachments.add(attachment);
      _saving = false;
    });
  }

  Future<void> _removeAttachment(SecureMemoryAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove attachment?'),
        content: Text('Remove ${attachment.fileName} from this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (_newAttachments.contains(attachment)) {
      await SecureMemoryService.instance.deleteAttachment(attachment);
      _newAttachments.remove(attachment);
    }
    if (mounted) setState(() => _attachments.remove(attachment));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title.')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.note;
    final note = SecureMemoryNote(
      id: existing?.id ?? _uuid.v4(),
      title: title,
      body: _bodyController.text.trim(),
      noteDate: _noteDate,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      attachments: List.unmodifiable(_attachments),
    );

    if (existing != null) {
      final removed = existing.attachments.where(
        (oldAttachment) => !_attachments.any(
          (current) => current.id == oldAttachment.id,
        ),
      );
      for (final attachment in removed) {
        await SecureMemoryService.instance.deleteAttachment(attachment);
      }
    }
    if (!mounted) return;
    Navigator.pop(context, note);
  }

  Future<bool> _confirmDiscard() async {
    if (_titleController.text.trim().isEmpty &&
        _bodyController.text.trim().isEmpty &&
        _newAttachments.isEmpty) {
      return true;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true) {
      for (final attachment in _newAttachments) {
        await SecureMemoryService.instance.deleteAttachment(attachment);
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Secure Note' : 'Edit Note'),
          actions: [
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _saving,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter a clear title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                minLines: 8,
                maxLines: 18,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Write your memory, information or details here',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Note date'),
                  subtitle: Text(_formatDate(_noteDate)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _chooseDate,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Attachments (${_attachments.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _showAttachmentOptions,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_attachments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.attach_file, size: 38),
                      SizedBox(height: 8),
                      Text(
                        'Add photos from camera or gallery, PDFs, documents, audio, video or any file format.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._attachments.map(
                  (attachment) => Card(
                    child: ListTile(
                      leading: Icon(_attachmentIcon(attachment.mimeType)),
                      title: Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatBytes(attachment.fileSizeBytes)),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        onPressed: () => _removeAttachment(attachment),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: _saving
            ? const LinearProgressIndicator()
            : SafeArea(
                minimum: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Secure Note'),
                ),
              ),
      ),
    );
  }
}

class _LockedView extends StatelessWidget {
  final Future<void> Function() onUnlock;

  const _LockedView({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 72),
            const SizedBox(height: 18),
            Text(
              'Secure Memory is locked',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your fingerprint, face, PIN or device password to continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock Secure Memory'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySecureMemory extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onCreate;

  const _EmptySecureMemory({required this.hasSearch, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasSearch ? Icons.search_off : Icons.note_add_outlined,
                size: 72),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No matching notes' : 'No secure notes yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search.'
                  : 'Save text, photos, PDFs and files securely.',
              textAlign: TextAlign.center,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create First Note'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _AttachmentChoice { camera, gallery, file }

IconData _attachmentIcon(String mimeType) {
  if (mimeType.startsWith('image/')) return Icons.image_outlined;
  if (mimeType.startsWith('video/')) return Icons.video_file_outlined;
  if (mimeType.startsWith('audio/')) return Icons.audio_file_outlined;
  if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
    return Icons.table_chart_outlined;
  }
  if (mimeType.contains('word') || mimeType.contains('document')) {
    return Icons.description_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatDateTime(DateTime date) {
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${_formatDate(date)}, $hour:$minute $period';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
