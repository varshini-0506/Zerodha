import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../services/websocket_service.dart';
import '../models/stock_model.dart';

class LivePriceChart extends StatefulWidget {
  final Stock stock;
  final double height;

  const LivePriceChart({
    Key? key,
    required this.stock,
    this.height = 300,
  }) : super(key: key);

  @override
  State<LivePriceChart> createState() => _LivePriceChartState();
}

class _LivePriceChartState extends State<LivePriceChart> with TickerProviderStateMixin {
  List<FlSpot> priceData = [];
  double currentPrice = 0;
  double previousPrice = 0;
  bool isPriceUp = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  StreamSubscription? _priceSubscription;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    currentPrice = widget.stock.lastPrice ?? 100.0;
    previousPrice = currentPrice;
    
    // Add initial data point
    priceData.add(FlSpot(0, currentPrice));
    
    _connectToWebSocket();
  }

  void _connectToWebSocket() async {
    try {
      await WebSocketService.instance.connect();
      _isConnected = WebSocketService.instance.isConnected;
      
      if (_isConnected) {
        _priceSubscription = WebSocketService.instance.priceStream.listen(
          (tickData) {
            _handlePriceUpdate(tickData);
          },
          onError: (error) {
            print('WebSocket error: $error');
          },
        );
      }
    } catch (e) {
      print('Connection error: $e');
    }
  }

  void _handlePriceUpdate(Map<String, dynamic> tickData) {
    try {
      final tickSymbol = tickData['symbol']?.toString().toUpperCase();
      final stockSymbol = widget.stock.symbol?.toUpperCase();
      
      if (tickSymbol == stockSymbol) {
        final newPrice = (tickData['last_price'] ?? tickData['ltp'] ?? currentPrice).toDouble();
        
        if (newPrice > 0 && newPrice != currentPrice) {
          setState(() {
            previousPrice = currentPrice;
            currentPrice = newPrice;
            isPriceUp = newPrice > previousPrice;
            
            final timestamp = DateTime.now().millisecondsSinceEpoch / 1000;
            priceData.add(FlSpot(timestamp, newPrice));
            
            // Keep only last 50 points
            if (priceData.length > 50) {
              priceData.removeAt(0);
            }
          });
          
          _animationController.reset();
          _animationController.forward();
        }
      }
    } catch (e) {
      print('Error handling price update: $e');
    }
  }

  @override
  void dispose() {
    _priceSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = isPriceUp ? Colors.green : Colors.red;
    
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Price Chart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnected ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: priceData.length > 1
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: priceData,
                          isCurved: true,
                          color: lineColor,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(enabled: false),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '₹${currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isConnected ? 'Waiting for updates...' : 'Connecting...',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 