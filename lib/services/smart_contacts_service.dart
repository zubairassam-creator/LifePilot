import 'package:flutter/services.dart';

import '../models/smart_contact.dart';

class SmartContactsService {
  SmartContactsService._();

  static const MethodChannel _channel = MethodChannel('lifepilot/contacts');

  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  static Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }

  static Future<List<SmartContact>> getContacts() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getContacts');
    return (result ?? const <dynamic>[])
        .map((item) => SmartContact.fromMap(item as Map<dynamic, dynamic>))
        .toList(growable: false);
  }

  static Future<void> addContact({
    required String name,
    required String phone,
    required String email,
  }) async {
    await _channel.invokeMethod<void>('addContact', <String, Object>{
      'name': name,
      'phone': phone,
      'email': email,
    });
  }

  static Future<void> updateContact({
    required String id,
    required String name,
    required String phone,
    required String email,
  }) async {
    await _channel.invokeMethod<void>('updateContact', <String, Object>{
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
    });
  }

  static Future<void> deleteContact(String id) async {
    await _channel.invokeMethod<void>('deleteContact', <String, Object>{'id': id});
  }

  static Future<void> call(String phone) async {
    await _channel.invokeMethod<void>('call', <String, Object>{'phone': phone});
  }

  static Future<void> openWhatsApp(String phone) async {
    await _channel.invokeMethod<void>('whatsApp', <String, Object>{'phone': phone});
  }

  static Future<void> email(String address) async {
    await _channel.invokeMethod<void>('email', <String, Object>{'email': address});
  }
}
