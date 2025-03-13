// Data Models
class Contact {
  final String name;
  final String phoneNumber;

  Contact({required this.name, required this.phoneNumber});
}

class Message {
  final String content;
  final DateTime timestamp;
  final bool isEncrypted;
  final bool isFromMe;

  Message({
    required this.content,
    required this.timestamp,
    this.isEncrypted = false,
    this.isFromMe = false,
  });
}

class Conversation {
  final Contact contact;
  final List<Message> messages;

  Conversation({required this.contact, required this.messages});
}
