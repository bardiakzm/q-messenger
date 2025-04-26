import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../resources/data_models.dart';
import '../services/conversation_provider.dart';
import '../services/simcard_manager.dart';
import '../services/sms_provider.dart';
import 'chat_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:q_messenger/services/global_providers.dart';

// Loading state provider
final loadingProvider = StateProvider<bool>((ref) => false);

final permissionsCheckedProvider = StateProvider<bool>((ref) => false);

//search provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered conversations provider
final filteredConversationsProvider = Provider<List<Conversation>>((ref) {
  final conversations = ref.watch(conversationsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return conversations;
  }

  return conversations.where((conversation) {
    // Search by contact name
    if (conversation.contact.name.toLowerCase().contains(searchQuery)) {
      return true;
    }

    // Search by message content
    for (final message in conversation.messages) {
      if (message.content.toLowerCase().contains(searchQuery)) {
        return true;
      }
    }

    return false;
  }).toList();
});

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    // _searchController.dispose();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndLoadMessages(forceRequest: true);
    });
    // Future.delayed(const Duration(seconds: 10), () {
    //   _requestPermissionsAndLoadMessages();
    // });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _endSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      ref.read(searchQueryProvider.notifier).state = '';
    });
  }

  Future<void> _requestPermissionsAndLoadMessages({
    bool forceRequest = false,
  }) async {
    ref.read(loadingProvider.notifier).state = true;

    var smsStatus = await Permission.sms.status;
    if (!smsStatus.isGranted || forceRequest) {
      smsStatus = await Permission.sms.request();
      if (!smsStatus.isGranted) {
        ref.read(loadingProvider.notifier).state = false;
        ref.read(permissionsCheckedProvider.notifier).state = true;
        return;
      }
    }
    await ref.read(smsProvider.notifier).loadMessages();

    ref.read(loadingProvider.notifier).state = false;
    ref.read(permissionsCheckedProvider.notifier).state = true;
  }

  Widget askForPermButton() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.lock_open),
        label: const Text('Grant Permissions'),
        onPressed: _requestPermissionsAndLoadMessages,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
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

  AppBar _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _endSearch,
        ),
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by name or message...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _startSearch,
          ), //TODO complete search function
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestPermissionsAndLoadMessages,
          ),
          // IconButton(
          //   icon: const Icon(Icons.more_vert),
          //   onPressed: () {
          //     // TODO: Implement menu
          //   },
          // ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredConversations = ref.watch(filteredConversationsProvider);
    final permissionsChecked = ref.watch(permissionsCheckedProvider);
    final notGrantedPerms = ref.watch(permissionProvider);
    final isLoading = ref.watch(loadingProvider);

    final bool smsPermGranted = notGrantedPerms.isEmpty;

    ref.watch(loadSimProvider);

    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(),
        body: FutureBuilder(
          future: Permission.sms.status,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final smsStatus = snapshot.data;
            final smsPermGranted = smsStatus?.isGranted ?? false;

            if (!smsPermGranted) {
              return askForPermButton();
            }

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (filteredConversations.isEmpty) {
              return Center(
                child: Text(
                  _isSearching
                      ? 'No results found for "${_searchController.text}"'
                      : 'No conversations',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              itemCount: filteredConversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = filteredConversations[index];
                if (conversation.messages.isEmpty) {
                  return const SizedBox.shrink();
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
                            (context) => ChatScreen(conversation: conversation),
                      ),
                    ).then((_) {
                      ref.read(smsProvider.notifier).loadMessages();
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
