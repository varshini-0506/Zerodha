import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static WebSocketService? _instance;
  IO.Socket? _socket;
  StreamController<Map<String, dynamic>>? _priceController;
  bool _isConnected = false;

  Timer? _pingTimer;
  Timer? _pongTimeoutTimer;

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

  Future connect() async {
    if (_isConnected) return;

    try {
      _socket = IO.io(
        'https://zerodha-production-04a6.up.railway.app',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': true,
        },
      );

      _socket!.on('connect', (_) {
        _isConnected = true;
        print('Socket.IO connected successfully');
        _startHeartbeat();
      });

      _socket!.on('disconnect', (_) {
        _isConnected = false;
        print('Socket.IO connection closed');
        _stopHeartbeat();
        _reconnect();
      });

      _socket!.on('tick_data', (data) {
        print('📊 Received tick_data: ${data['data']?.length ?? 0} records');
        final tickData = data['data'] as List?;
        if (tickData != null) {
          for (final tick in tickData) {
            _priceController?.add(Map<String, dynamic>.from(tick));
          }
        } else {
          print('⚠️ No tick data found in the received data');
        }
      });

      _socket!.on('market_status', (data) {
        print('📡 Market status: $data');
      });

      // Listen for pong replies from the server
      _socket!.on('pong_from_server', (data) {
        print('Pong received from server: $data');
        _resetPongTimeout();
      });
    } catch (e) {
      print('Failed to connect to Socket.IO: $e');
      _isConnected = false;
      _stopHeartbeat();
    }
  }

  void _startHeartbeat() {
    // Cancel any existing timers before starting new ones
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();

    // Send ping every 20 seconds
    _pingTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      if (_socket?.connected == true) {
        print('Sending ping to server');
        _socket!.emit('ping_from_client', {'time': DateTime.now().toIso8601String()});
        // Start pong response timeout (10 seconds from ping)
        _startPongTimeout();
      }
    });
  }

  void _startPongTimeout() {
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = Timer(Duration(seconds: 10), () {
      // Pong not received within timeout
      print('Pong not received within timeout, reconnecting...');
      _socket?.disconnect();
      _socket = null;
      _isConnected = false;
      _stopHeartbeat();
      _reconnect();
    });
  }

  void _resetPongTimeout() {
    _pongTimeoutTimer?.cancel();
  }

  void _stopHeartbeat() {
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();
  }

  void _reconnect() {
    // Avoid multiple concurrent reconnect attempts
    if (!_isConnected) {
      Future.delayed(Duration(seconds: 5), () {
        if (!_isConnected) {
          print('Attempting to reconnect...');
          connect();
        }
      });
    }
  }

  void disconnect() {
    _stopHeartbeat();
    _socket?.disconnect();
    _isConnected = false;
    _priceController?.close();
  }

  void dispose() {
    disconnect();
  }
}
