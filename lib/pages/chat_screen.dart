import 'package:flutter/material.dart';

import '../resources/data_models.dart';
import '../services/sms_service.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  ChatScreen({required this.conversation});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late List<Message> _messages;
  bool _isEncrypted = true;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation.messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade200,
              radius: 16,
              child: Text(
                widget.conversation.contact.name[0],
                style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
              ),
            ),
            SizedBox(width: 8),
            Text(widget.conversation.contact.name),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_outlined),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: Icon(Icons.call_outlined),
            onPressed: () {
              // TODO: Implement call
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
      body: Column(
        children: [
          // Encryption status indicator
          Container(
            color: _isEncrypted ? Colors.green.shade100 : Colors.amber.shade100,
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isEncrypted ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color:
                      _isEncrypted
                          ? Colors.green.shade800
                          : Colors.amber.shade800,
                ),
                SizedBox(width: 8),
                Text(
                  _isEncrypted
                      ? 'Messages are encrypted end-to-end'
                      : 'Messages are not encrypted',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _isEncrypted
                            ? Colors.green.shade800
                            : Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final reversedIndex = _messages.length - 1 - index;
                final message = _messages[reversedIndex];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Message composer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    // TODO: Implement attachment
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade200
                              : Colors.grey.shade800,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 6,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isEncrypted ? Icons.lock : Icons.lock_open,
                    color: _isEncrypted ? Colors.green : Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEncrypted = !_isEncrypted;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: () {
                    // if (_messageController.text.isNotEmpty) {
                    //   setState(() {
                    //     _messages.add(
                    //       Message(
                    //         content: _messageController.text,
                    //         timestamp: DateTime.now(),
                    //         isEncrypted: _isEncrypted,
                    //         isFromMe: true,
                    //       ),
                    //     );
                    //     _messageController.clear();
                    //   });
                    // }
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isFromMe = message.isFromMe;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isFromMe ? 64 : 0,
          right: isFromMe ? 0 : 64,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isFromMe
                  ? Colors.blue.shade500
                  : Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade200
                  : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isFromMe ? Colors.white : null),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (message.isEncrypted)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: isFromMe ? Colors.white70 : Colors.green,
                    ),
                  ),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isFromMe ? Colors.white70 : Colors.grey,
                  ),
                ),
                if (isFromMe)
                  Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.done_all,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    // Clear the input field
    _messageController.clear();

    // Implement your encryption logic here if needed
    final encryptedText = messageText; // Replace with actual encryption

    final newMessage = Message(
      content: messageText,
      timestamp: DateTime.now(),
      isEncrypted: false, // Set based on your encryption logic
      isFromMe: true,
    );

    // Add message to the conversation immediately for UI responsiveness
    setState(() {
      widget.conversation.messages.add(newMessage);
    });

    // Send the SMS
    final success = await SmsService.sendSms(
      address: widget.conversation.contact.phoneNumber,
      body: encryptedText, // Use encrypted text if implemented
      simSlot: 0,
    );

    if (!success) {
      // Handle send failure
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message')));

      // Optionally mark the message as failed in the UI
      setState(() {
        // Add a 'failed' flag to your Message class if needed
        // widget.conversation.messages.last.failed = true;
      });
    }
  }
}
