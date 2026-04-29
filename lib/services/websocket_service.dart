import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';

class AdvocateService {
  WebSocketChannel? _channel;
  void connect(String userId) {
    if (kMockMode) return;
    _channel = WebSocketChannel.connect(
      Uri.parse('$WS_URL/ws/advocate/$userId'));
  }
  void send(String text) {
    if (kMockMode) return;
    _channel?.sink.add(
      jsonEncode({'speaker':'police','text':text}));
  }
  Stream get stream {
    if (kMockMode) return const Stream.empty();
    return _channel!.stream;
  }
  void disconnect() { _channel?.sink.close(); _channel = null; }
}
