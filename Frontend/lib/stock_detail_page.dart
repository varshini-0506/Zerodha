import 'package:flutter/material.dart';
import 'models/stock_model.dart';
import 'services/stock_service.dart';
import 'widgets/live_price_chart.dart';
import 'dart:ui';
import 'dart:async'; // Added for StreamSubscription and Timer
import 'services/websocket_service.dart';
import 'watchlist_page.dart';
import 'events_page.dart';
import 'news_page.dart';
import 'stock_list_page.dart';
import 'main.dart';

class StockDetailPage extends StatefulWidget {
  final Stock stock;

  const StockDetailPage({Key? key, required this.stock}) : super(key: key);

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  late Stock _stock;
  bool _isLoading = false;
  final StockService _stockService = StockService();
  StreamSubscription? _tickSubscription; // Added for WebSocket subscription
  bool _isWebSocketConnected = false; // Track WebSocket connection status

  @override
  void initState() {
    super.initState();
    _stock = widget.stock;
    _fetchLatestQuote();
    // Connect to WebSocket and listen for live ticks
    WebSocketService.instance.connect();
    
    // Check WebSocket connection status
    _isWebSocketConnected = WebSocketService.instance.isConnected;
    
    // Periodically check WebSocket connection status
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _isWebSocketConnected = WebSocketService.instance.isConnected;
        });
      }
    });
    
    _tickSubscription = WebSocketService.instance.priceStream.listen((tickData) {
      final symbol = tickData['symbol'] ?? tickData['tradingsymbol'] ?? '';
      final instrumentToken = tickData['instrument_token']?.toString() ?? '';
      final newPrice = (tickData['last_price'] ?? tickData['ltp'] ?? 0.0).toDouble();
      
      print('🔄 Tick received for $symbol (current: ${_stock.symbol})');
      print('   Instrument token: $instrumentToken (current: ${_stock.instrumentToken})');
      print('   New price: $newPrice (current: ${_stock.lastPrice})');
      
      if (symbol == _stock.symbol || instrumentToken == _stock.instrumentToken.toString()) {
        print('✅ Match found! Updating stock details...');
        setState(() {
          _stock = _stock.copyWith(
            lastPrice: newPrice,
            quote: {
              ...?_stock.quote,
              'change': tickData['change'],
              'change_percent': tickData['change_percent'],
              'last_trade_time': tickData['timestamp'],
            },
          );
        });
        print('✅ Stock updated - New price: ${_stock.lastPrice}');
      } else {
        print('❌ No match - skipping update');
      }
    });
  }

  @override
  void dispose() {
    _tickSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestQuote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stockDetail = await StockService.getStockDetail(_stock.symbol);
      if (stockDetail != null) {
        setState(() {
          _stock = Stock.fromJson(stockDetail);
        });
      }
    } catch (e) {
      print('Error fetching quote: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_stock.name),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              print('🔄 Manual refresh triggered');
              _fetchLatestQuote();
            },
          ),
        ],
      ),
      drawer: Drawer(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        backgroundColor: Colors.grey[50],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[700]!, Colors.teal[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Text('MENU', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.home, color: Colors.teal),
              title: Text('Home', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => StockListPage(), settings: RouteSettings(name: '/home')),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => WatchlistPage(), settings: RouteSettings(name: '/wishlist')));
              },
            ),
            ListTile(
              leading: Icon(Icons.article, color: Colors.teal),
              title: Text('News', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => NewsPage(), settings: RouteSettings(name: '/news')));
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.deepPurple),
              title: Text('Events', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => EventsPage(), settings: RouteSettings(name: '/events')));
              },
            ),
            Spacer(),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => AuthWrapper()),
                  (route) => false,
                );
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[600]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.13),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _stock.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(
                            _stock.symbol,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Live Price',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Smooth number animation for price changes
                        _buildAnimatedPrice(),
                        SizedBox(height: 4),
                        if (_stock.quote?['last_trade_time'] != null)
                          Text(
                            'Last traded: ${_stock.quote!['last_trade_time']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Divider(thickness: 1.2, color: Colors.teal[100]),
              const SizedBox(height: 18),
              // Stock Metrics (Custom 2x3 Grid)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.08),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.teal.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Row 1: High, Low
                    Row(
                      children: [
                        Flexible(child: _buildMetricCard('High', '₹${(_stock.ohlc?['high'] ?? 0.0).toStringAsFixed(2)}', Icons.trending_up_rounded)),
                        SizedBox(width: 8),
                        Flexible(child: _buildMetricCard('Low', '₹${(_stock.ohlc?['low'] ?? 0.0).toStringAsFixed(2)}', Icons.trending_down_rounded)),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Row 2: Open, Prev. Close
                    Row(
                      children: [
                        Flexible(child: _buildMetricCard('Open', '₹${(_stock.ohlc?['open'] ?? 0.0).toStringAsFixed(2)}', Icons.play_arrow_rounded)),
                        SizedBox(width: 8),
                        Flexible(child: _buildMetricCard('Prev. Close', '₹${(_stock.ohlc?['close'] ?? 0.0).toStringAsFixed(2)}', Icons.close_rounded)),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Row 3: Volume (spans both columns)
                    Row(
                      children: [
                        Flexible(
                          child: _buildMetricCard('Volume', _stock.volume?.toString() ?? 'N/A', Icons.bar_chart_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Divider(thickness: 1.2, color: Colors.teal[100]),
              const SizedBox(height: 18),
              // Performance Summary
              KeyedSubtree(
                key: ValueKey('performance_${_stock.lastPrice}_${_stock.quote?['change']}_${_stock.quote?['change_percent']}'),
                child: _buildPerformanceSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    // Use live tick data for change calculations
    final double? change = _stock.quote?['change']?.toDouble() ??
        (_stock.lastPrice != null && _stock.ohlc?['close'] != null
            ? _stock.lastPrice! - _stock.ohlc!['close']
            : null);
    final double? changePercent = _stock.quote?['change_percent']?.toDouble() ??
        (_stock.lastPrice != null && _stock.ohlc?['close'] != null && _stock.ohlc!['close'] != 0
            ? ((_stock.lastPrice! - _stock.ohlc!['close']) / _stock.ohlc!['close']) * 100
            : null);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.07),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.withOpacity(0.18)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      Icon(Icons.trending_up, color: Colors.teal[600], size: 28),
                      SizedBox(height: 8),
                      Text(
                        'Change',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 500),
                        tween: Tween(begin: 0.0, end: change ?? 0.0),
                        builder: (context, animatedValue, child) {
                          return Text(
                            '₹${animatedValue.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.withOpacity(0.18)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      Icon(Icons.percent, color: Colors.teal[600], size: 28),
                      SizedBox(height: 8),
                      Text(
                        'Change %',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 500),
                        tween: Tween(begin: 0.0, end: changePercent ?? 0.0),
                        builder: (context, animatedValue, child) {
                          return Text(
                            '${animatedValue >= 0 ? '+' : ''}${animatedValue.toStringAsFixed(2)}%',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      constraints: BoxConstraints(minHeight: 56, maxHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(4),
            child: Icon(icon, color: Colors.teal[400], size: 18),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.teal[700], fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPrice() {
    final double currentPrice = _stock.lastPrice ?? 0.0;
    final double previousPrice = _stock.ohlc?['close'] ?? currentPrice;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500),
      tween: Tween(begin: previousPrice, end: currentPrice),
      builder: (context, animatedValue, child) {
        return Text(
          '₹${animatedValue.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        );
      },
    );
  }
} 