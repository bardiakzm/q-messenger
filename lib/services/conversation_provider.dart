import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_messenger/resources/data_models.dart';
import 'package:q_messenger/services/crypto.dart';
import 'package:q_messenger/services/obfuscate.dart';
import 'package:q_messenger/services/aes_encryption.dart';
import 'package:q_messenger/services/sms_service.dart';
import 'package:q_messenger/services/sms_provider.dart';

final conversationsProvider = Provider<List<Conversation>>((ref) {
  final messages = ref.watch(smsProvider);
  return _organizeConversations(messages);
});

RegExp regex = RegExp(r'^[^:]+:([^:]+):([^:]+)$');

List<Conversation> _organizeConversations(List<SmsMessage> messages) {
  final List<Conversation> conversations = [];
  Map<String, List<SmsMessage>> messagesByAddress = {};

  for (var message in messages) {
    final String tag = 'qmsa2';
    final String tHash = Crypto.generateTagHash(tag);
    final String obfsedTHash = Obfuscate.obfuscateFA1Tag(tHash);
    if (message.body.startsWith(obfsedTHash)) {
      final String deobfuscatedText = Obfuscate.deobfuscateText(
        message.body,
        obfuscationFA2Map,
      );
      message.body = deobfuscatedText;

      Match? match = regex.firstMatch(deobfuscatedText);
      String? iv = match?.group(2)!;
      String? encryptedText = match?.group(1)!;
      if (iv != null) {
        final decryptedText = Aes.decryptMessage(encryptedText!, iv);
        message.body = decryptedText;
      }
    }

    if (!messagesByAddress.containsKey(message.address)) {
      messagesByAddress[message.address] = [];
    }
    messagesByAddress[message.address]!.add(message);
  }

  // Create conversations from grouped messages
  messagesByAddress.forEach((address, messages) {
    messages.sort((a, b) => a.date.compareTo(b.date));

    List<Message> formattedMessages =
        messages
            .map(
              (sms) => Message(
                content: sms.body,
                timestamp: sms.dateTime,
                isEncrypted: false, // Set based on your encryption logic
                isFromMe: sms.isSent,
              ),
            )
            .toList();

    String contactName =
        messages.first.senderName != 'Unknown'
            ? messages.first.senderName
            : address;

    conversations.add(
      Conversation(
        contact: Contact(name: contactName, phoneNumber: address),
        messages: formattedMessages,
      ),
    );
  });

  // Sort conversations by most recent message
  conversations.sort((a, b) {
    final aTime =
        a.messages.isNotEmpty ? a.messages.last.timestamp : DateTime(1970);
    final bTime =
        b.messages.isNotEmpty ? b.messages.last.timestamp : DateTime(1970);
    return bTime.compareTo(aTime); // Most recent first
  });

  return conversations;
}
