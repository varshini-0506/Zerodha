import 'package:flutter/material.dart';
import 'models/stock_model.dart';
import 'services/stock_service.dart';
import 'widgets/live_price_chart.dart';

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

  @override
  void initState() {
    super.initState();
    _stock = widget.stock;
    _fetchLatestQuote();
  }

  Future<void> _fetchLatestQuote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quote = await StockService.getQuote(_stock.symbol);
      if (quote != null) {
        setState(() {
          _stock = Stock(
            symbol: _stock.symbol,
            name: _stock.name,
            instrumentToken: _stock.instrumentToken,
            exchange: _stock.exchange,
            instrumentType: _stock.instrumentType,
            segment: _stock.segment,
            expiry: _stock.expiry,
            strike: _stock.strike,
            tickSize: _stock.tickSize,
            lotSize: _stock.lotSize,
            quote: quote,
            historicalData: _stock.historicalData,
            lastUpdated: _stock.lastUpdated,
          );
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
        title: Text(_stock.name),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[600]!, Colors.teal[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stock.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stock.symbol,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(_stock.lastPrice ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (_stock.changePercent ?? 0.0) >= 0 ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_stock.changePercent ?? 0.0) >= 0 ? '+' : ''}${(_stock.changePercent ?? 0.0).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Live Price Chart
            LivePriceChart(
              stock: _stock,
              height: 300,
            ),
            
            const SizedBox(height: 24),
            
            // Stock Metrics
            _buildMetricsSection(),
            
            const SizedBox(height: 24),
            
            // Performance Summary
            _buildPerformanceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Stock Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          _buildMetricRow('Open', '₹${(_stock.open ?? 0.0).toStringAsFixed(2)}'),
          _buildMetricRow('High', '₹${(_stock.high ?? 0.0).toStringAsFixed(2)}'),
          _buildMetricRow('Low', '₹${(_stock.low ?? 0.0).toStringAsFixed(2)}'),
          _buildMetricRow('Previous Close', '₹${(_stock.close ?? 0.0).toStringAsFixed(2)}'),
          _buildMetricRow('Volume', _stock.volume.toString()),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    final isPositive = (_stock.changePercent ?? 0.0) >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Change',
                  '₹${_stock.change?.toStringAsFixed(2) ?? 'N/A'}',
                  changeColor,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Change %',
                  '${(_stock.changePercent ?? 0.0) >= 0 ? '+' : ''}${_stock.changePercent?.toStringAsFixed(2) ?? 'N/A'}%',
                  changeColor,
                  Icons.percent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 