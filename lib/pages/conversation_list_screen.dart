import 'package:flutter/material.dart';
import 'package:q_messenger/resources/data_models.dart';
import 'chat_screen.dart';
import 'package:q_messenger/services/sms_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<SmsMessage> _messages = [];
  bool _loading = false;

  Future<void> _requestPermissionAndLoadMessages() async {
    setState(() => _loading = true);

    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        setState(() => _loading = false);
        return;
      }
    }
    final messages = await SmsService.getAllMessages();
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMessagesAndSetConversations();
  }

  Future<void> _loadMessagesAndSetConversations() async {
    await _requestPermissionAndLoadMessages();
    _organizeConversations();
  }

  final List<Conversation> _conversations = [];

  void _organizeConversations() {
    // Clear existing conversations
    _conversations.clear();

    // Group messages by address
    Map<String, List<SmsMessage>> messagesByAddress = {};

    for (var message in _messages) {
      if (!messagesByAddress.containsKey(message.address)) {
        messagesByAddress[message.address] = [];
      }
      messagesByAddress[message.address]!.add(message);
    }

    // Create conversations from grouped messages
    messagesByAddress.forEach((address, messages) {
      // Sort messages by date (oldest first for conversation history)
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

      _conversations.add(
        Conversation(
          contact: Contact(
            name: address, // Ideally, look up the contact name if possible
            phoneNumber: address,
          ),
          messages: formattedMessages,
        ),
      );
    });

    // Sort conversations by most recent message (for the conversation list)
    _conversations.sort((a, b) {
      final aTime =
          a.messages.isNotEmpty ? a.messages.last.timestamp : DateTime(1970);
      final bTime =
          b.messages.isNotEmpty ? b.messages.last.timestamp : DateTime(1970);
      return bTime.compareTo(aTime); // Most recent first
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu
            },
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final lastMessage = conversation.messages.last;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade200,
              child: Text(
                conversation.contact.name[0],
                style: TextStyle(color: Colors.blue.shade800),
              ),
            ),
            title: Text(
              conversation.contact.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                if (lastMessage.isEncrypted)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.lock, size: 14, color: Colors.green),
                  ),
                Expanded(
                  child: Text(
                    lastMessage.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Text(
              _formatTimestamp(lastMessage.timestamp),
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(conversation: conversation),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // List<SmsMessage> messages = await query.getAllSms;
          // print(messages[0]);
          // TODO: Implement new conversation
        },
        child: Icon(Icons.chat),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.day == now.day &&
        timestamp.month == now.month &&
        timestamp.year == now.year) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (timestamp.day == now.day - 1 &&
        timestamp.month == now.month &&
        timestamp.year == now.year) {
      return 'Yesterday';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
