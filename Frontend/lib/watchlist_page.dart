import 'package:flutter/material.dart';
import 'models/stock_model.dart';

class WatchlistPage extends StatelessWidget {
  final List<Stock> watchlist;
  const WatchlistPage({super.key, required this.watchlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wishlist')),
      body: watchlist.isEmpty
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
              itemCount: watchlist.length,
              itemBuilder: (context, index) {
                final stock = watchlist[index];
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
                  ),
                );
              },
            ),
    );
  }
} 