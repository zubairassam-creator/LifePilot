import 'dart:async';
import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/biometric_service.dart';
import '../services/password_vault_service.dart';
import '../widgets/password_card.dart';
import '../widgets/vault_lock_overlay.dart';
import 'add_password_screen.dart';
import 'edit_password_screen.dart';

class PasswordVaultScreen extends StatefulWidget { const PasswordVaultScreen({super.key}); @override State<PasswordVaultScreen> createState()=>_PasswordVaultScreenState(); }
class _PasswordVaultScreenState extends State<PasswordVaultScreen> with WidgetsBindingObserver { bool locked=true, searching=false; String? message; final search=TextEditingController(); final revealed=<String,String>{}; Duration autoLock=const Duration(minutes:1); Timer? timer;
  @override void initState(){super.initState(); WidgetsBinding.instance.addObserver(this); PasswordVaultService.instance.setScreenshotProtection(true); _unlock();}
  @override void dispose(){timer?.cancel(); search.dispose(); WidgetsBinding.instance.removeObserver(this); PasswordVaultService.instance.setScreenshotProtection(false); super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){ if(state==AppLifecycleState.paused||state==AppLifecycleState.inactive) _lock(); }
  void _touch(){ timer?.cancel(); if(!locked) timer=Timer(autoLock,_lock); }
  void _lock(){ if(mounted) setState((){locked=true; revealed.clear();}); }
  Future<void> _unlock() async { final r=await BiometricService.instance.authenticate('Unlock Password Vault'); if(!mounted)return; setState(()=>message=r.message); if(r.success){setState(()=>locked=false); _touch();} }
  List<PasswordEntry> get entries=>PasswordVaultService.instance.search(search.text);
  Future<bool> _reauth(String reason) async { final r=await BiometricService.instance.authenticate(reason); if(!r.success && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r.message??'Authentication failed'))); return r.success; }
  Future<void> _toggle(PasswordEntry e) async { _touch(); if(revealed.containsKey(e.id)){setState(()=>revealed.remove(e.id)); return;} if(!await _reauth('Reveal password for ${e.serviceName}')) return; final p=await PasswordVaultService.instance.decryptPassword(e); if(mounted)setState(()=>revealed[e.id]=p); }
  Future<void> _copyPassword(PasswordEntry e) async { _touch(); if(!await _reauth('Copy password for ${e.serviceName}')) return; final p=await PasswordVaultService.instance.decryptPassword(e); await PasswordVaultService.instance.copyPassword(p); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Password copied. Clipboard clears in 30 seconds.'))); }
  Future<void> _delete(PasswordEntry e) async { _touch(); final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Delete password?'), content:Text('Delete ${e.serviceName}?'), actions:[TextButton(onPressed:()=>Navigator.pop(context,false), child:const Text('Cancel')), FilledButton(onPressed:()=>Navigator.pop(context,true), child:const Text('Delete'))])); if(ok==true){await PasswordVaultService.instance.delete(e.id); if(mounted)setState((){});} }
  Future<void> _openAdd() async { _touch(); final changed=await Navigator.push(context, MaterialPageRoute(builder:_=>const AddPasswordScreen())); if(changed==true&&mounted)setState((){}); }
  Future<void> _openEdit(PasswordEntry e) async { _touch(); final changed=await Navigator.push(context, MaterialPageRoute(builder:_=>EditPasswordScreen(entry:e))); if(changed==true&&mounted)setState((){}); }
  @override Widget build(BuildContext context)=>GestureDetector(onTap:_touch, onPanDown:(_)=>_touch(), child:Scaffold(appBar:AppBar(title: searching?TextField(controller:search, autofocus:true, decoration:const InputDecoration(hintText:'Search vault'), onChanged:(_)=>setState((){})):const Text('Password Vault'), actions:[PopupMenuButton<Duration>(icon:const Icon(Icons.lock_clock), onSelected:(v)=>setState(()=>autoLock=v), itemBuilder:(_)=>const [PopupMenuItem(value:Duration(seconds:30), child:Text('Auto lock: 30 seconds')), PopupMenuItem(value:Duration(minutes:1), child:Text('Auto lock: 1 minute')), PopupMenuItem(value:Duration(minutes:5), child:Text('Auto lock: 5 minutes'))]), IconButton(icon:Icon(searching?Icons.close:Icons.search), onPressed:()=>setState((){searching=!searching; if(!searching)search.clear();})), IconButton(icon:const Icon(Icons.add), onPressed:locked?null:_openAdd)]), body: locked?VaultLockOverlay(onUnlock:_unlock,message:message): entries.isEmpty?const Center(child:Text('No passwords saved. Tap + to add one.')):ListView.builder(itemCount:entries.length, itemBuilder:(context,i){final e=entries[i]; return PasswordCard(entry:e, revealedPassword: revealed[e.id], revealed:revealed.containsKey(e.id), onToggle:()=>_toggle(e), onCopyUsername:(){_touch(); PasswordVaultService.instance.copyUsername(e.username); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Username copied.')));}, onCopyPassword:()=>_copyPassword(e), onEdit:()=>_openEdit(e), onDelete:()=>_delete(e));}))));
}
