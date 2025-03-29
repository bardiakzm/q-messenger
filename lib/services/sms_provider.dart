import 'package:q_messenger/services/sms_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smsProvider = StateNotifierProvider<SmsNotifier, List<SmsMessage>>((ref) {
  return SmsNotifier();
});

// Add a loading state provider to show loading indicators in the UI
final smsLoadingProvider = StateProvider<bool>((ref) => false);

class SmsNotifier extends StateNotifier<List<SmsMessage>> {
  SmsNotifier() : super([]);

  Future<void> loadMessages() async {
    try {
      print("SMS Provider: Loading messages from service");
      final messages = await SmsService.getAllMessages();
      print("SMS Provider: Got ${messages.length} messages");
      state = messages;
    } catch (e) {
      print("SMS Provider: Error loading messages: $e");
      // Still update state even if empty to prevent hanging
      state = [];
      rethrow;
    }
  }

  Future<bool> sendMessage({
    required String phoneNumber,
    required String text,
    required int simSlot,
  }) async {
    bool success = await SmsService.sendSms(
      address: phoneNumber,
      body: text,
      simSlot: simSlot,
    );
    if (success) {
      await loadMessages(); // Refresh messages after sending
    }
    return success;
  }
}
