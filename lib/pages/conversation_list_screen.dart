import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_messenger/resources/data_models.dart';
import 'package:q_messenger/services/crypto.dart';
import 'package:q_messenger/services/obfuscate.dart';
import '../services/aes_encryption.dart';
import '../services/conversation_provider.dart';
import '../services/sms_provider.dart';
import '../services/sms_service.dart';
import 'chat_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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
      _requestPermissionsAndLoadMessages();
    });
  }

  Future<void> _requestPermissionsAndLoadMessages() async {
    ref.read(loadingProvider.notifier).state = true;

    //request SMS permissions
    var smsStatus = await Permission.sms.status;
    if (!smsStatus.isGranted) {
      smsStatus = await Permission.sms.request();
      if (!smsStatus.isGranted) {
        ref.read(loadingProvider.notifier).state = false;
        //TODO req message here
        return;
      }
    }

    // Request phone state permission
    var phoneStatus = await Permission.phone.status;
    if (!phoneStatus.isGranted) {
      phoneStatus = await Permission.phone.request();
      if (!phoneStatus.isGranted) {
        //TODO handle phone perm not granted
      }
    }

    var sendSmsStatus = await Permission.sms.status;
    if (!sendSmsStatus.isGranted) {
      sendSmsStatus = await Permission.sms.request();
      //TODO handle phone perm not granted
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
            onPressed: _requestPermissionsAndLoadMessages,
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
