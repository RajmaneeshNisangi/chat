import 'dart:convert';
import 'package:chat/data/models/chat.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user.dart';
import 'models/message.dart';

class ApiService {
  final String baseUrl = 'http://45.129.87.38:6065';

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/user/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'role': role}),
    );

    print('Login response: ${response.statusCode}');
    print('Login body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['encrypted'] == true && responseData['data'] != null) {
        final data = responseData['data'];

        if (data['token'] != null) {
          await _storeToken(data['token']);
        }
        if (data['user'] != null) {
          await _storeUserId(data['user']['_id']);
          await _storeUserData(data['user']);
        }

        return data;
      } else {
        return responseData;
      }
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = json.decode(userDataString);
      return User.fromJson(userData);
    }
    return null;
  }

  Future<List<Chat>> getUserChats(String userId) async {
    final url = Uri.parse('$baseUrl/chats/user-chats/$userId');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    print('Chats response: ${response.statusCode}');
    print('Chats body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Chat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chats: ${response.body}');
    }
  }

  Future<List<Message>> getChatMessages(String chatId) async {
    final url = Uri.parse('$baseUrl/messages/get-messagesformobile/$chatId');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    print('Messages response: ${response.statusCode}');
    print('Messages body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  Future<Message> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String fileUrl = '',
  }) async {
    final url = Uri.parse('$baseUrl/messages/sendMessage');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'messageType': messageType,
        'fileUrl': fileUrl,
      }),
    );

    print('Send message response: ${response.statusCode}');
    print('Send message body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Message.fromJson(data);
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _storeUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }
}
