import 'package:flutter/services.dart';

class SmsService {
  static const MethodChannel _channel = MethodChannel(
    'eth.bardiak.q_messenger/sms_service',
  );

  /// Get all SMS messages
  static Future<List<SmsMessage>> getAllMessages() async {
    try {
      final List<dynamic> messages = await _channel.invokeMethod('getAllSms');
      return messages
          .map((m) => SmsMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } on PlatformException catch (e) {
      print("Failed to get messages: ${e.message}");
      return [];
    }
  }

  /// send sms
  static Future<bool> sendSms({
    required String address,
    required String body,
    int simSlot = 0, //default SIM is 0 (SIM 1)
  }) async {
    try {
      final bool result = await _channel.invokeMethod('sendSms', {
        'address': address,
        'body': body,
        'simSlot': simSlot, // Pass selected SIM slot
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to send SMS: ${e.message}");
      return false;
    }
  }
}

class SmsMessage {
  final String senderName;
  final String id;
  final String address;
  String body;
  final int date;
  final int type; // 1 = inbox, 2 = sent, etc.
  final bool isEncrypted;

  SmsMessage({
    required this.senderName,
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.type,
    this.isEncrypted = false,
  });

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'].toString(),
      address: map['address'] ?? '',
      body: map['body'] ?? '',
      date: map['date'] ?? 0,
      type: map['type'] ?? 0,
      senderName: map['senderName'] ?? '',
    );
  }

  bool get isInbox => type == 1;
  bool get isSent => type == 2;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);
}
