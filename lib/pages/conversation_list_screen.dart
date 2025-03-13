import 'package:flutter/material.dart';
import 'package:q_messenger/resources/data_models.dart';
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final List<Conversation> _conversations = [
    Conversation(
      contact: Contact(name: "Ali", phoneNumber: "+98123456789"),
      messages: [
        Message(
          content: "Hello, how are you?",
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          isEncrypted: true,
          isFromMe: false,
        ),
      ],
    ),
    Conversation(
      contact: Contact(name: "Sara", phoneNumber: "+98987654321"),
      messages: [
        Message(
          content: "Meeting at 5pm tomorrow",
          timestamp: DateTime.now().subtract(Duration(hours: 4)),
          isEncrypted: true,
          isFromMe: true,
        ),
      ],
    ),
    Conversation(
      contact: Contact(name: "Reza", phoneNumber: "+98456789123"),
      messages: [
        Message(
          content: "Did you get the files?",
          timestamp: DateTime.now().subtract(Duration(minutes: 30)),
          isEncrypted: false,
          isFromMe: false,
        ),
      ],
    ),
  ];

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
        onPressed: () {
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
