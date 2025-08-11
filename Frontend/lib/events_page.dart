import 'package:flutter/material.dart';
import 'models/stock_model.dart';
import 'services/stock_service.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'watchlist_page.dart';
import 'news_page.dart';
import 'stock_list_page.dart';
import 'main.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<String> wishlistSymbols = [];
  Map<String, dynamic> eventsData = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWishlistAndEvents();
  }

  Future<void> _fetchWishlistAndEvents() async {
    final user = AuthService().getCurrentUser();
    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to view events.';
      });
      return;
    }
    try {
      final symbols = await StockService.getWishlist(userId: user.id);
      setState(() {
        wishlistSymbols = symbols;
      });
      for (final symbol in symbols) {
        final events = await _fetchStockEvents(symbol);
        setState(() {
          eventsData[symbol] = events;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load events: $e';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchStockEvents(String symbol) async {
    final url = Uri.parse('https://zerodha-production-04a6.up.railway.app/api/stock_events/$symbol');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'error': 'Failed to fetch events for $symbol'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Events'),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
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
                // Already on Events; keep option visible
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red)))
              : wishlistSymbols.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No wishlisted stocks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Add stocks to your wishlist to see their events here', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      separatorBuilder: (context, idx) => SizedBox(height: 18),
                      itemCount: wishlistSymbols.length,
                      itemBuilder: (context, index) {
                        final symbol = wishlistSymbols[index];
                        final events = eventsData[symbol];
                        return Card(
                          elevation: 6,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Icon(Icons.event, color: Colors.deepPurple, size: 28),
                            title: Text(
                              symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.deepPurple[800],
                                letterSpacing: 1.2,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                child: events == null
                                    ? Center(child: CircularProgressIndicator())
                                    : events['error'] != null
                                        ? Text(events['error'], style: TextStyle(color: Colors.red))
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildDividendsSection(events['dividends_fmp'], theme),
                                              Divider(height: 32, thickness: 1.2, color: Colors.deepPurple[50]),
                                              _buildEarningsSection(events['earnings_finnhub'], theme),
                                              Divider(height: 32, thickness: 1.2, color: Colors.deepPurple[50]),
                                              _buildSplitsSection(events['splits_fmp'], theme),
                                              Divider(height: 32, thickness: 1.2, color: Colors.deepPurple[50]),
                                              _buildIposSection(events['ipos_finnhub'], theme),
                                            ],
                                          ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildDividendsSection(dynamic dividendsFmp, ThemeData theme) {
    final List<dynamic> dividends = dividendsFmp != null && dividendsFmp['historical'] != null ? dividendsFmp['historical'] : [];
    return _buildEventSection(
      'Dividends',
      dividends,
      (div) => [
        _eventRow([
          _eventFieldIconText(Icons.calendar_today, 'Date', div['date'] ?? '', theme),
          _eventFieldIconText(Icons.attach_money, 'Dividend', div['dividend']?.toString() ?? '', theme),
          if (div['declarationDate'] != null && div['declarationDate'] != '') _eventFieldIconText(Icons.announcement, 'Declaration', div['declarationDate'], theme),
          if (div['paymentDate'] != null && div['paymentDate'] != '') _eventFieldIconText(Icons.payment, 'Payment', div['paymentDate'], theme),
          if (div['recordDate'] != null && div['recordDate'] != '') _eventFieldIconText(Icons.receipt, 'Record', div['recordDate'], theme),
        ]),
      ],
      theme,
    );
  }

  Widget _buildEarningsSection(dynamic earningsFinnhub, ThemeData theme) {
    final List<dynamic> earnings = earningsFinnhub ?? [];
    return _buildEventSection(
      'Earnings',
      earnings,
      (earn) => [
        _eventRow([
          _eventFieldIconText(Icons.calendar_today, 'Period', earn['period'] ?? '', theme),
          _eventFieldIconText(Icons.trending_up, 'Actual', earn['actual']?.toString() ?? '', theme),
          _eventFieldIconText(Icons.trending_flat, 'Estimate', earn['estimate']?.toString() ?? '', theme),
          if (earn['surprise'] != null) _eventFieldIconText(Icons.flash_on, 'Surprise', earn['surprise'].toString(), theme),
          if (earn['surprisePercent'] != null) _eventFieldIconText(Icons.percent, 'Surprise %', earn['surprisePercent'].toString(), theme),
        ]),
      ],
      theme,
    );
  }

  Widget _buildSplitsSection(dynamic splitsFmp, ThemeData theme) {
    final List<dynamic> splits = splitsFmp != null && splitsFmp['historical'] != null ? splitsFmp['historical'] : [];
    return _buildEventSection(
      'Splits',
      splits,
      (split) => [
        _eventRow([
          _eventFieldIconText(Icons.calendar_today, 'Date', split['date'] ?? '', theme),
          _eventFieldIconText(Icons.call_split, 'Ratio', '${split['numerator'] ?? ''} : ${split['denominator'] ?? ''}', theme),
          if (split['label'] != null) _eventFieldIconText(Icons.label, 'Label', split['label'], theme),
        ]),
      ],
      theme,
    );
  }

  Widget _buildIposSection(dynamic iposFinnhub, ThemeData theme) {
    final List<dynamic> ipos = iposFinnhub ?? [];
    return _buildEventSection(
      'IPOs',
      ipos,
      (ipo) => [
        _eventRow([
          _eventFieldIconText(Icons.business, 'Name', ipo['name'] ?? '', theme),
          _eventFieldIconText(Icons.calendar_today, 'Date', ipo['date'] ?? '', theme),
          _eventFieldIconText(Icons.location_city, 'Exchange', ipo['exchange'] ?? '', theme),
          _eventFieldIconText(Icons.confirmation_number, 'Shares', ipo['numberOfShares']?.toString() ?? '', theme),
          _eventFieldIconText(Icons.attach_money, 'Price', ipo['price']?.toString() ?? '', theme),
          _eventFieldIconText(Icons.info, 'Status', ipo['status'] ?? '', theme),
        ]),
      ],
      theme,
    );
  }

  Widget _buildEventSection(String title, List<dynamic> data, List<Widget> Function(dynamic) fieldsBuilder, ThemeData theme) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No $title events', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Row(
            children: [
              Icon(_sectionIcon(title), color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 16, letterSpacing: 0.5)),
            ],
          ),
        ),
        ...data.take(5).map((event) => Container(
              margin: const EdgeInsets.only(left: 8.0, bottom: 10.0, top: 2.0),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fieldsBuilder(event),
              ),
            )),
      ],
    );
  }

  Widget _eventRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: children.expand((w) => [w, SizedBox(width: 18)]).toList()..removeLast(),
      ),
    );
  }

  Widget _eventFieldIconText(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.primaryColorDark.withOpacity(0.7)),
        SizedBox(width: 4),
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: theme.primaryColorDark.withOpacity(0.85))),
        Text(value, style: TextStyle(color: Colors.black87)),
      ],
    );
  }

  IconData _sectionIcon(String title) {
    switch (title) {
      case 'Dividends':
        return Icons.attach_money;
      case 'Earnings':
        return Icons.trending_up;
      case 'Splits':
        return Icons.call_split;
      case 'IPOs':
        return Icons.business;
      default:
        return Icons.event;
    }
  }
} 