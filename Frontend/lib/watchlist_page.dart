import 'package:flutter/material.dart';
import 'models/stock_model.dart';
import 'services/stock_service.dart';
import 'auth_service.dart';
import 'stock_detail_page.dart';
import 'news_page.dart';
import 'events_page.dart';
import 'stock_list_page.dart';
import 'main.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  List<Stock> wishlistStocks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    final user = AuthService().getCurrentUser();
    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to view your wishlist.';
      });
      return;
    }
    try {
      final symbols = await StockService.getWishlist(userId: user.id);
      final stocks = <Stock>[];
      for (final symbol in symbols) {
        try {
          final stockDetail = await StockService.getStockDetail(symbol);
          stocks.add(Stock.fromJson(stockDetail));
        } catch (e) {
          // Skip if stock detail fails
        }
      }
      setState(() {
        wishlistStocks = stocks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load wishlist: $e';
      });
    }
  }

  Future _removeFromWishlist(Stock stock) async {
  final user = AuthService().getCurrentUser();
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please log in to manage your wishlist.')),
    );
    return;
  }
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      
      title: Text(
        'Remove from Wishlist',
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      
      // Fixed content with minimal padding
      content: Text(
        'Are you sure you want to remove ${stock.symbol} from your wishlist?',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
      
      // Key fix: Minimal padding between content and actions
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12), // Reduced bottom padding
      actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 16),   // Reduced top padding
      
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            minimumSize: Size(80, 40),
          ),
          child: Text(
            'Cancel', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        
        // Remove button (red color for destructive action)
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size(80, 40),
            elevation: 2,
          ),
          child: Text(
            'Remove', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  try {
    await StockService.removeFromWishlist(userId: user.id, symbol: stock.symbol);
    if (mounted) {
      setState(() {
        wishlistStocks.removeWhere((s) => s.symbol == stock.symbol);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${stock.symbol} removed from wishlist!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from wishlist: $e'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist'),
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
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text(
                    AuthService().getCurrentUser()?.email ?? 'user@example.com',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Text('MENU', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.home, color: Colors.teal),
              title: Text('Home', style: TextStyle(fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                // Already on Wishlist; keep consistent UX
              },
            ),
            ListTile(
              leading: Icon(Icons.article, color: Colors.teal),
              title: Text('News', style: TextStyle(fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => NewsPage(), settings: RouteSettings(name: '/news')));
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.deepPurple),
              title: Text('Events', style: TextStyle(fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthWrapper()),
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
              : wishlistStocks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_border, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Your wishlist is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Add stocks to your wishlist to see them here', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: wishlistStocks.length,
                      itemBuilder: (context, index) {
                        final stock = wishlistStocks[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.withOpacity(0.1),
                              child: Text(stock.symbol[0], style: TextStyle(color: Colors.teal)),
                            ),
                            title: Text('${stock.symbol} - ${stock.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₹${stock.lastPrice?.toStringAsFixed(2) ?? 'N/A'} | ${stock.changePercent?.toStringAsFixed(2) ?? 'N/A'}% | ${stock.rating} | ${stock.sector}',
                                    style: TextStyle(color: Colors.grey[600])),
                                if (stock.volume != null)
                                  Text('Volume: ${stock.volume!.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFromWishlist(stock),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StockDetailPage(stock: stock),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
} 