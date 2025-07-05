import 'package:chat/logic/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc()..add(LoadChatRooms()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chats'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                context.read<ChatBloc>().add(RefreshChatRooms());
              },
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                print('Logout pressed');
              },
            ),
          ],
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is ChatLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ChatBloc>().add(RefreshChatRooms());
                },
                child: ListView.builder(
                  itemCount: state.chatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom = state.chatRooms[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(chatRoom.name.isNotEmpty ? chatRoom.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(chatRoom.name),
                      subtitle: Text(chatRoom.lastMessage),
                      trailing: Text(
                        _formatTime(chatRoom.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatRoomId: chatRoom.id,
                              chatRoomName: chatRoom.name,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            } else if (state is ChatError) {
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
                        context.read<ChatBloc>().add(LoadChatRooms());
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
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}