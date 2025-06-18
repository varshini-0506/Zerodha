import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _priceController;
  bool _isConnected = false;
  
  // Singleton pattern
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }
  
  WebSocketService._internal();

  Stream<Map<String, dynamic>> get priceStream {
    _priceController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _priceController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // Connect to the WebSocket server
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.0.8:6789'), // Use your computer's IP
      );

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _reconnect();
        },
      );

      _isConnected = true;
      print('WebSocket connected successfully');
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic data) {
    print('🔌 WebSocket received raw data: $data'); // Debug print
    try {
      final message = json.decode(data);
      print('📦 Parsed message type: ${message['type']}');
      
      if (message['type'] == 'tick_data') {
        final tickData = message['data'] as List;
        print('📊 Received ${tickData.length} tick records');
        
        for (final tick in tickData) {
          print('📈 Processing tick: ${tick['symbol']} - ${tick['last_price']}');
          _priceController?.add(tick);
        }
      } else if (message['type'] == 'market_status') {
        print('📡 Market status: ${message['data']}');
      }
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
      print('Raw data was: $data');
    }
  }

  void _reconnect() {
    Future.delayed(Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect...');
        connect();
      }
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _priceController?.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
  }
} 