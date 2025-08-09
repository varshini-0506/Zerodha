import 'package:flutter/material.dart';
import 'models/stock_model.dart';
import 'services/stock_service.dart';
import 'auth_service.dart';
import 'stock_detail_page.dart';

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

  Future<void> _removeFromWishlist(Stock stock) async {
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: Container(
          width: double.maxFinite,
          child: Text(
            'Are you sure you want to remove ${stock.symbol} from your wishlist?',
            style: TextStyle(fontSize: 16),
          ),
        ),
        contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Yes', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await StockService.removeFromWishlist(userId: user.id, symbol: stock.symbol);
      setState(() {
        wishlistStocks.removeWhere((s) => s.symbol == stock.symbol);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${stock.symbol} removed from wishlist!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from wishlist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wishlist')),
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