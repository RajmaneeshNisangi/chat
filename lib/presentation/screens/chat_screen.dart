// lib/presentation/screens/chat_screen.dart
import 'package:chat/data/apiservice.dart';
import 'package:chat/logic/bloc/message_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/message.dart';

class ChatScreen extends StatelessWidget {
  final String chatRoomId;
  final String chatRoomName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatRoomName,
  });

  @override
  Widget build(BuildContext context) {
    print('ChatScreen: Opening chat with ID: $chatRoomId, Name: $chatRoomName');
    
    return BlocProvider(
      create: (context) => MessageBloc()
        ..add(LoadMessages(chatId: chatRoomId))
        ..add(StartPolling(chatId: chatRoomId)),
      child: ChatScreenView(
        chatRoomId: chatRoomId, 
        chatRoomName: chatRoomName
      ),
    );
  }
}

class ChatScreenView extends StatefulWidget {
  final String chatRoomId;
  final String chatRoomName;

  const ChatScreenView({
    super.key,
    required this.chatRoomId,
    required this.chatRoomName,
  });

  @override
  State<ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<ChatScreenView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    print('ChatScreenView: Initialized for chat ${widget.chatRoomId}');
  }

  void _loadCurrentUserId() async {
    final userId = await ApiService().getUserId();
    setState(() {
      currentUserId = userId;
    });
    print('Current user ID loaded: $currentUserId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatRoomName),
            BlocBuilder<MessageBloc, MessageState>(
              builder: (context, state) {
                if (state is MessageLoaded) {
                  return Text(
                    state.isPolling ? 'Auto-refreshing...' : 'Tap to refresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: state.isPolling ? Colors.green : Colors.grey,
                    ),
                  );
                }
                return Text('Loading...', style: TextStyle(fontSize: 12));
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<MessageBloc>().add(
                RefreshMessages(chatId: widget.chatRoomId),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<MessageBloc, MessageState>(
        listener: (context, state) {
          if (state is MessageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          // Auto-scroll to bottom when new messages arrive
          if (state is MessageLoaded && state.messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        },
        builder: (context, state) {
          if (state is MessageLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is MessageLoaded) {
            return Column(
              children: [
                // Messages list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<MessageBloc>().add(
                        RefreshMessages(chatId: widget.chatRoomId),
                      );
                    },
                    child: state.messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet.\nStart the conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              return _buildMessageBubble(message);
                            },
                          ),
                  ),
                ),
                
                // Message input
                _buildMessageInput(),
              ],
            );
          } else if (state is MessageError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MessageBloc>().add(
                        LoadMessages(chatId: widget.chatRoomId),
                      );
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isCurrentUser = message.senderId == currentUserId;
    
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                message.senderName.isNotEmpty ? message.senderName : 'Other User',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            if (!isCurrentUser) SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 6,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          SizedBox(width: 8),
          BlocBuilder<MessageBloc, MessageState>(
            builder: (context, state) {
              final isLoading = state is MessageLoading;
              return FloatingActionButton(
                mini: true,
                onPressed: isLoading ? null : _sendMessage,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.send),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    print('Sending message: ${_messageController.text.trim()} to chat: ${widget.chatRoomId}');

    context.read<MessageBloc>().add(
      SendMessage(
        content: _messageController.text.trim(),
        chatId: widget.chatRoomId,
      ),
    );

    _messageController.clear();
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    print('ChatScreenView: Disposing and stopping polling for chat ${widget.chatRoomId}');
    context.read<MessageBloc>().add(StopPolling());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}