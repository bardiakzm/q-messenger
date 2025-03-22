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
}

class SmsMessage {
  final String id;
  final String address;
  final String body;
  final int date;
  final int type; // 1 = inbox, 2 = sent, etc.

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.type,
  });

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'].toString(),
      address: map['address'] ?? '',
      body: map['body'] ?? '',
      date: map['date'] ?? 0,
      type: map['type'] ?? 0,
    );
  }

  bool get isInbox => type == 1;
  bool get isSent => type == 2;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);
}
