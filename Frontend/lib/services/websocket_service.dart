import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static WebSocketService? _instance;
  IO.Socket? _socket;
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
      _socket = IO.io('https://zerodha-ay41.onrender.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket!.on('connect', (_) {
        _isConnected = true;
        print('Socket.IO connected successfully');
      });

      _socket!.on('disconnect', (_) {
        _isConnected = false;
        print('Socket.IO connection closed');
        _reconnect();
      });

      _socket!.on('tick_data', (data) {
        print('📊 Received tick_data: ${data['data']?.length ?? 0} records');
        print('📊 Raw data structure: ${data.keys.toList()}');
        final tickData = data['data'] as List?;
        if (tickData != null) {
          for (final tick in tickData) {
            print('📈 Processing tick: ${tick['symbol']} - ${tick['last_price']}');
            print('📈 Tick keys: ${tick.keys.toList()}');
            _priceController?.add(Map<String, dynamic>.from(tick));
          }
        } else {
          print('⚠️ No tick data found in the received data');
        }
      });

      _socket!.on('market_status', (data) {
        print('📡 Market status: $data');
      });
    } catch (e) {
      print('Failed to connect to Socket.IO: $e');
      _isConnected = false;
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
    _socket?.disconnect();
    _priceController?.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
  }
} 