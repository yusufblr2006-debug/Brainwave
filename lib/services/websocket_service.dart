import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<String>? _controller;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Stream<String> get stream {
    _controller ??= StreamController<String>.broadcast();
    return _controller!.stream;
  }

  Future<void> connect(String userId) async {
    try {
      final wsUrl = Uri.parse('ws://api.judisai.in/ws/advocate/$userId');
      _channel = WebSocketChannel.connect(wsUrl);
      _controller ??= StreamController<String>.broadcast();
      _isConnected = true;
      _channel!.stream.listen(
        (data) => _controller?.add(data.toString()),
        onError: (e) => _controller?.addError(e),
        onDone: () => _isConnected = false,
      );
    } catch (e) {
      _isConnected = false;
      // In demo mode: simulate a response after 3 seconds
      _controller ??= StreamController<String>.broadcast();
    }
  }

  void send(String msg) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(msg);
    } else {
      // Demo fallback: generate a mock response
      Future.delayed(const Duration(seconds: 2), () {
        _controller?.add(
          'I am exercising my right to remain silent under Article 20(3) of the Constitution of India. '
          'I request that you identify yourself with name and badge number as per police regulations.',
        );
      });
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller?.close();
    _controller = null;
  }
}
