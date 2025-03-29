import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_messenger/resources/data_models.dart';
import '../services/sms_provider.dart';
import '../services/sms_service.dart';
import 'chat_screen.dart';
import 'package:q_messenger/services/sms_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Provider for conversations based on SMS messages
final conversationsProvider = Provider<List<Conversation>>((ref) {
  final messages = ref.watch(smsProvider);
  return _organizeConversations(messages);
});

// Helper function to organize conversations
List<Conversation> _organizeConversations(List<SmsMessage> messages) {
  final List<Conversation> conversations = [];
  Map<String, List<SmsMessage>> messagesByAddress = {};

  for (var message in messages) {
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

    conversations.add(
      Conversation(
        contact: Contact(
          name: address, // Ideally, look up the contact name if possible
          phoneNumber: address,
        ),
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

// Loading state provider
final loadingProvider = StateProvider<bool>((ref) => false);

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionAndLoadMessages();
    });
  }

  Future<void> _requestPermissionAndLoadMessages() async {
    ref.read(loadingProvider.notifier).state = true;

    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        ref.read(loadingProvider.notifier).state = false;
        return;
      }
    }

    await ref.read(smsProvider.notifier).loadMessages();
    ref.read(loadingProvider.notifier).state = false;
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

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestPermissionAndLoadMessages,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement menu
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  if (conversation.messages.isEmpty) {
                    return const SizedBox.shrink(); // Skip empty conversations
                  }
                  final lastMessage = conversation.messages.last;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade200,
                      child: Text(
                        conversation.contact.name.isNotEmpty
                            ? conversation.contact.name[0]
                            : '?',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ),
                    title: Text(
                      conversation.contact.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        if (lastMessage.isEncrypted)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.lock,
                              size: 14,
                              color: Colors.green,
                            ),
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ChatScreen(conversation: conversation),
                        ),
                      ).then((_) {
                        // Refresh messages when returning from chat screen
                        // This ensures we show any new messages that were sent
                        ref.read(smsProvider.notifier).loadMessages();
                      });
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new conversation
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}
