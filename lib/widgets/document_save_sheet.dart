import 'package:flutter/material.dart';
import '../models/lifepilot_document.dart';

class DocumentSaveData {
  final String name;
  final DocumentCategory category;
  final String? description;
  final bool sensitive;
  const DocumentSaveData(this.name, this.category, this.description, this.sensitive);
}

class DocumentSaveSheet extends StatefulWidget {
  final PendingDocumentAttachment attachment;
  final String initialName;
  const DocumentSaveSheet({super.key, required this.attachment, required this.initialName});
  static Future<DocumentSaveData?> show(BuildContext context, PendingDocumentAttachment attachment, String initialName) => showModalBottomSheet<DocumentSaveData>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => DocumentSaveSheet(attachment: attachment, initialName: initialName));
  @override State<DocumentSaveSheet> createState() => _DocumentSaveSheetState();
}
class _DocumentSaveSheetState extends State<DocumentSaveSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  final TextEditingController _desc = TextEditingController();
  DocumentCategory _category = DocumentCategory.identity;
  late bool _sensitive = _category.defaultsSensitive;
  @override void dispose(){_name.dispose(); _desc.dispose(); super.dispose();}
  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left:16,right:16,bottom: MediaQuery.of(context).viewInsets.bottom + 16),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children:[
      Text('Save document', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height:12),
      TextField(controller:_name, decoration: const InputDecoration(labelText:'Document name')),
      DropdownButtonFormField(value:_category, decoration: const InputDecoration(labelText:'Category'), items: DocumentCategory.values.map((c)=>DropdownMenuItem(value:c, child:Text(c.label))).toList(), onChanged:(v){ if(v==null)return; setState((){_category=v; _sensitive=v.defaultsSensitive;});}),
      TextField(controller:_desc, decoration: const InputDecoration(labelText:'Optional description')),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Sensitive document'), value:_sensitive, onChanged:(v)=>setState(()=>_sensitive=v)),
      Text('Original filename: ${widget.attachment.fileName}'), Text('File type: ${widget.attachment.extension.toUpperCase()}'), Text('File size: ${_size(widget.attachment.fileSizeBytes)}'),
      const SizedBox(height:16), FilledButton(onPressed: _name.text.trim().isEmpty ? null : ()=>Navigator.pop(context, DocumentSaveData(_name.text.trim(), _category, _desc.text.trim().isEmpty?null:_desc.text.trim(), _sensitive)), child: const Text('Save securely')),
    ])),
  );
  String _size(int b) => b < 1024 * 1024 ? '${(b / 1024).toStringAsFixed(1)} KB' : '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}
