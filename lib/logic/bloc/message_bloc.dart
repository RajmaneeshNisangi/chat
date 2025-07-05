import 'dart:async';
import 'package:chat/data/apiservice.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/message.dart';

abstract class MessageEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadMessages extends MessageEvent {
  final String chatId;

  LoadMessages({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

class SendMessage extends MessageEvent {
  final String content;
  final String chatId;

  SendMessage({required this.content, required this.chatId});

  @override
  List<Object> get props => [content, chatId];
}

class RefreshMessages extends MessageEvent {
  final String chatId;

  RefreshMessages({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

class StartPolling extends MessageEvent {
  final String chatId;

  StartPolling({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

class StopPolling extends MessageEvent {}

abstract class MessageState extends Equatable {
  @override
  List<Object> get props => [];
}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<Message> messages;
  final bool isPolling;

  MessageLoaded({required this.messages, this.isPolling = false});

  @override
  List<Object> get props => [messages, isPolling];
}

class MessageError extends MessageState {
  final String message;

  MessageError({required this.message});

  @override
  List<Object> get props => [message];
}

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final ApiService _apiService;
  Timer? _pollingTimer;
  String? _currentChatId;

  MessageBloc({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      super(MessageInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<RefreshMessages>(_onRefreshMessages);
    on<StartPolling>(_onStartPolling);
    on<StopPolling>(_onStopPolling);
  }

  void _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    emit(MessageLoading());

    try {
      print('MessageBloc: Loading messages for chat ID: ${event.chatId}');

      final messages = await _apiService.getChatMessages(event.chatId);

      print(
        'MessageBloc: Loaded ${messages.length} messages for chat ${event.chatId}',
      );

      // Debug: Print first few messages
      if (messages.isNotEmpty) {
        print(
          'MessageBloc: First message - ID: ${messages.first.id}, Content: ${messages.first.content}, SenderId: ${messages.first.senderId}',
        );
      }

      _currentChatId = event.chatId;
      emit(MessageLoaded(messages: messages));
    } catch (e) {
      print('MessageBloc: Error loading messages for chat ${event.chatId}: $e');
      emit(MessageError(message: 'Failed to load messages: ${e.toString()}'));
    }
  }

  void _onSendMessage(SendMessage event, Emitter<MessageState> emit) async {
    try {
      final userId = await _apiService.getUserId();

      if (userId == null || userId.isEmpty) {
        print('MessageBloc: No user ID found, cannot send message');
        emit(MessageError(message: 'User not found. Please login again.'));
        return;
      }

      print(
        'MessageBloc: Sending message "${event.content}" to chat ${event.chatId} from user $userId',
      );

      final sentMessage = await _apiService.sendMessage(
        chatId: event.chatId,
        senderId: userId,
        content: event.content,
      );

      print(
        'MessageBloc: Message sent successfully with ID: ${sentMessage.id}',
      );

      // Refresh messages after sending
      add(RefreshMessages(chatId: event.chatId));
    } catch (e) {
      print('MessageBloc: Error sending message to chat ${event.chatId}: $e');
      emit(MessageError(message: 'Failed to send message: ${e.toString()}'));
    }
  }

  void _onRefreshMessages(
    RefreshMessages event,
    Emitter<MessageState> emit,
  ) async {
    try {
      print('MessageBloc: Refreshing messages for chat ${event.chatId}');

      final messages = await _apiService.getChatMessages(event.chatId);

      print(
        'MessageBloc: Refreshed ${messages.length} messages for chat ${event.chatId}',
      );

      if (state is MessageLoaded) {
        final currentState = state as MessageLoaded;
        emit(
          MessageLoaded(messages: messages, isPolling: currentState.isPolling),
        );
      } else {
        emit(MessageLoaded(messages: messages));
      }
    } catch (e) {
      print(
        'MessageBloc: Error refreshing messages for chat ${event.chatId}: $e',
      );
      // Don't emit error state for refresh failures, keep current messages
    }
  }

  void _onStartPolling(StartPolling event, Emitter<MessageState> emit) {
    print('MessageBloc: Starting polling for chat ${event.chatId}');

    _currentChatId = event.chatId;

    // Update state to show polling is active
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      emit(MessageLoaded(messages: currentState.messages, isPolling: true));
    }

    _pollingTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_currentChatId != null) {
        print(
          'MessageBloc: Polling - refreshing messages for chat $_currentChatId',
        );
        add(RefreshMessages(chatId: _currentChatId!));
      }
    });
  }

  void _onStopPolling(StopPolling event, Emitter<MessageState> emit) {
    print('MessageBloc: Stopping polling');

    _pollingTimer?.cancel();
    _pollingTimer = null;

    // Update state to show polling is stopped
    if (state is MessageLoaded) {
      final currentState = state as MessageLoaded;
      emit(MessageLoaded(messages: currentState.messages, isPolling: false));
    }
  }

  @override
  Future<void> close() {
    print('MessageBloc: Closing and cancelling polling timer');
    _pollingTimer?.cancel();
    return super.close();
  }
}
