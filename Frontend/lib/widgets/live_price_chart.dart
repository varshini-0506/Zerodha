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
  List<DateTime> timeData = [];
  double currentPrice = 0;
  double previousPrice = 0;
  bool isPriceUp = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  StreamSubscription? _priceSubscription;
  bool _isConnected = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isMarketOpen = false; // Assume market is closed outside 9:15 AM - 3:30 PM IST

  // Chart styling getters
  Color get lineColor => isPriceUp ? Colors.green : Colors.red;
  List<Color> get gradientColors => [
    lineColor.withOpacity(0.3),
    lineColor.withOpacity(0.01),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    currentPrice = widget.stock.lastPrice ?? 0.0;
    previousPrice = currentPrice;
    final now = DateTime.now();
    priceData.add(FlSpot(now.millisecondsSinceEpoch / 1000, currentPrice));
    timeData.add(now);
    _checkMarketHours(); // Check if market is open
    _connectToWebSocket();
    _simulateDataIfNeeded(); // Simulate data if market is closed
  }

  void _checkMarketHours() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    // Market hours: 9:15 AM to 3:30 PM IST
    _isMarketOpen = (hour == 9 && minute >= 15) || (hour > 9 && hour < 15) || (hour == 15 && minute <= 30);
    print('Market status: ${_isMarketOpen ? "Open" : "Closed"} at ${now.toIso8601String()}');
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
            setState(() {
              _hasError = true;
              _errorMessage = 'WebSocket error: $error';
            });
          },
          onDone: () {
            setState(() {
              _isConnected = false;
              _hasError = true;
              _errorMessage = 'WebSocket connection closed';
            });
          },
        );
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to connect to WebSocket';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Connection error: $e';
      });
    }
  }

  void _handlePriceUpdate(Map<String, dynamic> tickData) {
    print('Tick received in chart: $tickData'); // Debug log
    final symbol = tickData['symbol'] ?? tickData['tradingsymbol'] ?? '';
    final instrumentToken = tickData['instrument_token']?.toString() ?? '';
    print('Matching ${widget.stock.symbol} with $symbol or $instrumentToken'); // Debug match
    if (symbol == widget.stock.symbol || instrumentToken == widget.stock.instrumentToken.toString()) {
      final newPrice = (tickData['last_price'] ?? tickData['ltp'] ?? 0.0).toDouble();
      final timestampStr = tickData['timestamp'] ?? DateTime.now().toIso8601String();
      final timestamp = DateTime.parse(timestampStr).toLocal();
      print('New price: $newPrice, Current price: $currentPrice'); // Debug price
      if (newPrice > 0 && newPrice != currentPrice) {
        setState(() {
          previousPrice = currentPrice;
          currentPrice = newPrice;
          isPriceUp = newPrice > previousPrice;
          priceData.add(FlSpot(timestamp.millisecondsSinceEpoch / 1000, newPrice));
          timeData.add(timestamp);
          if (priceData.length > 60) {
            priceData.removeAt(0);
            timeData.removeAt(0);
          }
          print('Price data length: ${priceData.length}'); // Debug length
        });
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  void _simulateDataIfNeeded() {
    if (!_isMarketOpen) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            final now = DateTime.now();
            currentPrice += 0.5; // Simulate price change
            priceData.add(FlSpot(now.millisecondsSinceEpoch / 1000, currentPrice));
            timeData.add(now);
            if (priceData.length > 60) {
              priceData.removeAt(0);
              timeData.removeAt(0);
            }
          });
        }
      });
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
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 8, right: 8, bottom: 32),
            child: _buildChartContent(),
          ),
          if (priceData.length > 1)
            Positioned(
              right: 8,
              top: 8,
              child: FadeTransition(
                opacity: _animation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: lineColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '₹${currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartContent() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _connectToWebSocket,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isConnected || (_isMarketOpen && priceData.length < 2)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isConnected
                  ? (_isMarketOpen ? 'Waiting for live data...' : 'Market closed, using simulated data...')
                  : 'Connecting to server...',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Calculate safe intervals
    double minY = priceData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxY = priceData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    double yRange = maxY - minY;
    double yInterval = (yRange / 5).abs();
    if (yInterval < 1e-2) yInterval = 1; // Never zero, at least 1

    // X-axis: show only a few evenly spaced labels
    int labelCount = 5;
    int totalPoints = priceData.length;
    int labelStep = (totalPoints / labelCount).ceil();
    if (labelStep < 1) labelStep = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SizedBox(
        height: widget.height + 40, // Make chart a bit taller for mobile
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 56, // More space for Y labels
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '₹${value.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = priceData.indexWhere((spot) => spot.x >= value);
                    if (idx < 0 || idx >= timeData.length) return const SizedBox.shrink();
                    // Only show a label every labelStep points
                    if (idx % labelStep != 0 && idx != totalPoints - 1) return const SizedBox.shrink();
                    final time = timeData[idx];
                    return Transform.rotate(
                      angle: -0.5, // Rotate for clarity
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                  reservedSize: 36,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: priceData.isNotEmpty ? priceData.first.x : 0,
            maxX: priceData.isNotEmpty ? priceData.last.x : 1,
            minY: priceData.isNotEmpty ? minY * 0.995 : 0,
            maxY: priceData.isNotEmpty ? maxY * 1.005 : 1,
            lineBarsData: [
              LineChartBarData(
                spots: priceData,
                isCurved: true,
                color: lineColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.grey[800]!.withOpacity(0.8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final time = DateTime.fromMillisecondsSinceEpoch((spot.x * 1000).toInt());
                    return LineTooltipItem(
                      '₹${spot.y.toStringAsFixed(2)}\n${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}