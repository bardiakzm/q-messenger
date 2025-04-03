import 'package:flutter/material.dart';
import 'package:mobile_number/sim_card.dart';
import 'package:q_messenger/services/aes_encryption.dart';
import '../resources/data_models.dart';
import '../services/conversation_provider.dart';
import '../services/crypto.dart';
import '../services/obfuscate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_messenger/services/sms_provider.dart';
import 'package:q_messenger/resources/widgets/sim_numbered_icon.dart';
import '../services/simcard_manager.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEncrypted = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(smsProvider.notifier).loadMessages());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    //scroll to bottom when the widget updates
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // final messages = ref.watch(smsProvider);
    final conversations = ref.watch(conversationsProvider);

    final simCards = ref.watch(simCardProvider);
    final selectedSim = ref.watch(selectedSimProvider);

    //find the current conversation from the global list
    final currentConversation = conversations.firstWhere(
      (c) => c.contact.phoneNumber == widget.conversation.contact.phoneNumber,
      orElse: () => widget.conversation,
    );

    //get messages from the current conversation
    final conversationMessages = currentConversation.messages;

    //scroll to bottom when messages change
    if (conversationMessages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade200,
              radius: 16,
              child: Text(
                currentConversation.contact.name[0],
                style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
              ),
            ),
            SizedBox(width: 8),
            Text(currentConversation.contact.name),
          ],
        ),
        actions: [
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

          ///Messages list
          Expanded(
            child: ListView.builder(
              // reverse: true,
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: conversationMessages.length,
              itemBuilder: (context, index) {
                final message = conversationMessages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Message composer
          Container(
            padding: EdgeInsets.only(right: 8, top: 4, bottom: 4, left: 10),
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
                PopupMenuButton<int>(
                  icon: Icon(Icons.sim_card, color: Colors.blueGrey),
                  elevation: 6, // Add a soft shadow effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  itemBuilder: (BuildContext context) {
                    return [
                      for (int index = 0; index < simCards.length; index++) ...[
                        PopupMenuItem<int>(
                          value: index,
                          child: Row(
                            children: [
                              Icon(
                                selectedSim == index
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color:
                                    selectedSim == index
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                              SizedBox(width: 10),
                              // SimCardIcon(simNumber: index),  //TODO
                              Expanded(
                                child: Text(
                                  simCards[index].carrierName ?? 'SIM $index',
                                  style: TextStyle(
                                    fontWeight:
                                        selectedSim == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        selectedSim == index
                                            ? Colors.blue
                                            : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < simCards.length - 1)
                          const PopupMenuDivider(), // Adds a line between items
                      ],
                    ];
                  },
                  onSelected: (int index) {
                    ref.read(selectedSimProvider.notifier).state = index;
                  },
                ),

                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.blue,
                  onPressed:
                      _isEncrypted ? _sendEncryptedMessage : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final bool isFromMe = message.isFromMe;

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
            SelectableText(
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

    _messageController.clear();

    final success = await ref
        .read(smsProvider.notifier)
        .sendMessage(
          phoneNumber: widget.conversation.contact.phoneNumber,
          text: messageText,
          simSlot: 0,
        );
    await ref.read(smsProvider.notifier).loadMessages();
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }

  Future<void> _sendEncryptedMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    //clear input field
    _messageController.clear();
    final Map<String, String> encryptedMessage = Aes.encryptMessage(
      messageText,
    );

    final String tHash = Crypto.generateTagHash(encryptedMessage['tag']!);
    final String obfsedTHash = Obfuscate.obfuscateFA1Tag(tHash);

    final encryptedText =
        '$obfsedTHash:${encryptedMessage['ciphertext']}:${encryptedMessage['iv']}';

    final obfuscatedText = Obfuscate.obfuscateText(
      encryptedText,
      obfuscationFA2Map,
    );
    final success = await ref
        .read(smsProvider.notifier)
        .sendMessage(
          phoneNumber: widget.conversation.contact.phoneNumber,
          text: obfuscatedText,
          simSlot: 0,
        );
    await ref.read(smsProvider.notifier).loadMessages();
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }
}
