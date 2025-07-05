import 'package:chat/data/apiservice.dart';
import 'package:chat/data/models/chat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';


abstract class ChatEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadChatRooms extends ChatEvent {}

class RefreshChatRooms extends ChatEvent {}

abstract class ChatState extends Equatable {
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Chat> chatRooms;

  ChatLoaded({required this.chatRooms});

  @override
  List<Object> get props => [chatRooms];
}

class ChatError extends ChatState {
  final String message;

  ChatError({required this.message});

  @override
  List<Object> get props => [message];
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService;

  ChatBloc({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService(),
        super(ChatInitial()) {
    on<LoadChatRooms>(_onLoadChatRooms);
    on<RefreshChatRooms>(_onRefreshChatRooms);
  }

  void _onLoadChatRooms(LoadChatRooms event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    try {
      final userId = await _apiService.getUserId();
      
      if (userId == null || userId.isEmpty) {
        emit(ChatError(message: 'User not found. Please login again.'));
        return;
      }
      
      print('Loading chats for user ID: $userId');
      
      final chatRooms = await _apiService.getUserChats(userId);
      
      print('Loaded ${chatRooms.length} chat rooms');
      
      emit(ChatLoaded(chatRooms: chatRooms));
    } catch (e) {
      print('Error loading chats: $e');
      emit(ChatError(message: 'Failed to load chats: ${e.toString()}'));
    }
  }

  void _onRefreshChatRooms(RefreshChatRooms event, Emitter<ChatState> emit) async {
    try {
      final userId = await _apiService.getUserId();
      
      if (userId == null || userId.isEmpty) {
        emit(ChatError(message: 'User not found. Please login again.'));
        return;
      }
      
      print('Refreshing chats for user ID: $userId');
      
      final chatRooms = await _apiService.getUserChats(userId);
      
      print('Refreshed ${chatRooms.length} chat rooms');
      
      emit(ChatLoaded(chatRooms: chatRooms));
    } catch (e) {
      print('Error refreshing chats: $e');
      if (state is ChatLoaded) {
        emit(ChatError(message: 'Failed to refresh: ${e.toString()}'));
      } else {
        emit(ChatError(message: 'Failed to refresh chats: ${e.toString()}'));
      }
    }
  }
}