import 'package:flutter/material.dart';
import 'models/stock_model.dart';
import 'stock_detail_page.dart';
import 'watchlist_page.dart';
import 'services/stock_service.dart';
import 'news_page.dart';
import 'auth_service.dart';
import 'dart:async';
import 'events_page.dart';

class StockListPage extends StatefulWidget {
  @override
  _StockListPageState createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  String searchQuery = '';
  String selectedSector = 'All';
  String selectedRating = 'All';
  String selectedPerf = 'All';
  List<Stock> watchlist = [];
  List<Stock> allStocks = [];
  List<Stock> filteredStocks = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Set<String> wishlistSymbols = {};

  List<String> sectors = ['All', 'Technology', 'Banking & Finance', 'Healthcare', 'Automotive', 'Oil & Gas', 'Power & Energy', 'Others'];
  List<String> ratings = ['All', 'Buy', 'Hold', 'Sell'];
  List<String> perfOptions = ['All', 'Positive', 'Negative'];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Test API connection first
    final isApiConnected = await StockService.testApiConnection();
    if (!isApiConnected) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Unable to connect to server. Please check your internet connection and try again.';
      });
      return;
    }
    
    // Load data if API is connected
    await _loadStocks();
    await _loadWishlist();
  }

  Future<void> _loadStocks() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      print('Starting to load stocks...'); // Debug log
      
      // Load popular stocks first
      print('Loading popular stocks...'); // Debug log
      final popularStocksData = await StockService.getPopularStocks();
      final popularStocks = popularStocksData.map((json) => Stock.fromJson(json)).toList();
      print('Loaded ${popularStocks.length} popular stocks'); // Debug log
      
      // Load all stocks with pagination
      print('Loading all stocks...'); // Debug log
      final stocksData = await StockService.getStocks(page: 1, limit: 100);
      final stocks = (stocksData['stocks'] as List)
          .map((json) => Stock.fromJson(json))
          .toList();
      print('Loaded ${stocks.length} stocks'); // Debug log

      // Combine and fetch quote data for each stock
      final allStocksCombined = [...popularStocks, ...stocks];
      print('Fetching quotes for ${allStocksCombined.length} stocks...'); // Debug log
      final stocksWithQuotes = await _fetchQuotesForStocks(allStocksCombined);
      print('Successfully loaded ${stocksWithQuotes.length} stocks with quotes'); // Debug log

      setState(() {
        allStocks = stocksWithQuotes;
        filteredStocks = allStocks;
        isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      print('Error in _loadStocks: $e'); // Debug log
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadWishlist() async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;
    try {
      final symbols = await StockService.getWishlist(userId: user.id);
      setState(() {
        wishlistSymbols = symbols.toSet();
      });
    } catch (e) {
      // ignore error
    }
  }

  Future<List<Stock>> _fetchQuotesForStocks(List<Stock> stocks) async {
    final stocksWithQuotes = <Stock>[];
    
    // Limit to first 30 stocks for performance
    final stocksToFetch = stocks.take(30).toList();
    final symbols = stocksToFetch.map((stock) => stock.symbol).toList();
    
    try {
      // Use batch quotes API for better performance
      final batchQuotesResponse = await StockService.getBatchQuotes(symbols);
      final quotes = batchQuotesResponse['quotes'] as Map<String, dynamic>;
      
      // Update stocks with quote data
      for (final stock in stocksToFetch) {
        final quoteData = quotes[stock.symbol.toUpperCase()];
        if (quoteData != null) {
          // Create a new stock object with quote data
          final stockWithQuote = stock.copyWith(
            quote: quoteData,
            lastPrice: quoteData['last_price']?.toDouble(),
            volume: quoteData['volume']?.toDouble(),
            netChange: quoteData['change']?.toDouble(),
          );
          stocksWithQuotes.add(stockWithQuote);
        } else {
          stocksWithQuotes.add(stock);
        }
      }
    } catch (e) {
      print('Error fetching batch quotes: $e');
      // If batch quotes fail, add stocks without quotes
      stocksWithQuotes.addAll(stocksToFetch);
    }
    
    // Add remaining stocks without quotes
    stocksWithQuotes.addAll(stocks.skip(30));
    
    return stocksWithQuotes;
  }

  void _applyFilters() {
    setState(() {
      filteredStocks = allStocks.where((stock) {
        final matchesSearch = stock.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            stock.symbol.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesSector = selectedSector == 'All' || stock.sector == selectedSector;
        final matchesRating = selectedRating == 'All' || stock.rating == selectedRating;
        final matchesPerf = selectedPerf == 'All' ||
            (selectedPerf == 'Positive' && stock.perfPercent >= 0) ||
            (selectedPerf == 'Negative' && stock.perfPercent < 0);
        return matchesSearch && matchesSector && matchesRating && matchesPerf;
      }).toList();
    });
  }

  Future<void> _searchStocks(String query) async {
    if (query.isEmpty) {
      _applyFilters();
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final searchResults = await StockService.searchStocks(query);
      final searchStocks = searchResults.map((json) => Stock.fromJson(json)).toList();
      
      // Fetch quotes for search results using batch API
      final stocksWithQuotes = await _fetchQuotesForStocks(searchStocks);
      
      setState(() {
        filteredStocks = stocksWithQuotes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmAndToggleWishlist(Stock stock) async {
    final user = AuthService().getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to manage your wishlist.')),
      );
      return;
    }
    final isWishlisted = wishlistSymbols.contains(stock.symbol);
    final action = isWishlisted ? 'remove' : 'add';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'add' ? 'Add to' : 'Remove from'} Wishlist'),
        content: Text('Are you sure you want to ${action == 'add' ? 'add' : 'remove'} ${stock.symbol} ${action == 'add' ? 'to' : 'from'} your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (isWishlisted) {
        await StockService.removeFromWishlist(userId: user.id, symbol: stock.symbol);
        setState(() {
          wishlistSymbols.remove(stock.symbol);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${stock.symbol} removed from wishlist!')),
        );
      } else {
        await StockService.addToWishlist(userId: user.id, symbol: stock.symbol);
        setState(() {
          wishlistSymbols.add(stock.symbol);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${stock.symbol} added to wishlist!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${action == 'add' ? 'add to' : 'remove from'} wishlist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Stocks'),
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
            SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Text('MENU', style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('Wishlist', style: TextStyle(fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: ModalRoute.of(context)?.settings.name == '/wishlist' ? Colors.teal[50] : null,
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WatchlistPage(),
                    settings: RouteSettings(name: '/wishlist'),
                  ),
                );
                _loadWishlist();
              },
            ),
            ListTile(
              leading: Icon(Icons.article, color: Colors.teal),
              title: Text('News', style: TextStyle(fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: ModalRoute.of(context)?.settings.name == '/news' ? Colors.teal[50] : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsPage(),
                    settings: RouteSettings(name: '/news'),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.deepPurple),
              title: Text('Events', style: TextStyle(fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: ModalRoute.of(context)?.settings.name == '/events' ? Colors.teal[50] : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventsPage(),
                    settings: RouteSettings(name: '/events'),
                  ),
                );
              },
            ),
            Spacer(),
            Divider(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 20),
              child: Text('Zerodha Demo App', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or symbol...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
                if (query.length >= 2) {
                  _searchStocks(query);
                } else {
                  _applyFilters();
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<String>(
                  value: selectedSector,
                  onChanged: (value) {
                    setState(() {
                      selectedSector = value!;
                    });
                    _applyFilters();
                  },
                  items: sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                  dropdownColor: Colors.white,
                  underline: Container(height: 2, color: Colors.teal),
                ),
                DropdownButton<String>(
                  value: selectedRating,
                  onChanged: (value) {
                    setState(() {
                      selectedRating = value!;
                    });
                    _applyFilters();
                  },
                  items: ratings.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                  dropdownColor: Colors.white,
                  underline: Container(height: 2, color: Colors.teal),
                ),
                DropdownButton<String>(
                  value: selectedPerf,
                  onChanged: (value) {
                    setState(() {
                      selectedPerf = value!;
                    });
                    _applyFilters();
                  },
                  items: perfOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                  dropdownColor: Colors.white,
                  underline: Container(height: 2, color: Colors.teal),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildStockList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text('Loading stocks...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading stocks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(errorMessage, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      hasError = false;
                    });
                    _initializeApp();
                  },
                  child: Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      hasError = false;
                    });
                    StockService.testApiConnection().then((connected) {
                      if (connected) {
                        _initializeApp();
                      } else {
                        setState(() {
                          isLoading = false;
                          hasError = true;
                          errorMessage = 'Server is not reachable. Please check your internet connection.';
                        });
                      }
                    });
                  },
                  child: Text('Test Connection'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (filteredStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No stocks found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStocks.length,
      itemBuilder: (context, index) {
        final stock = filteredStocks[index];
        final hasQuoteData = stock.quote != null;
        
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
                if (hasQuoteData)
                  Text(
                    '₹${stock.lastPrice?.toStringAsFixed(2) ?? 'N/A'} | '
                    '${stock.quote?['change_percent'] != null ? (stock.quote!['change_percent'] >= 0 ? '+' : '') + stock.quote!['change_percent'].toStringAsFixed(2) : 'N/A'}% | '
                    '${stock.rating} | ${stock.sector}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                if (!hasQuoteData)
                  Text('Quote data loading... | ${stock.sector}',
                      style: TextStyle(color: Colors.grey[600])),
                if (hasQuoteData && stock.volume != null)
                  Text('Volume: ${stock.volume!.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                wishlistSymbols.contains(stock.symbol) ? Icons.star : Icons.star_border,
                color: wishlistSymbols.contains(stock.symbol) ? Colors.amber : Colors.teal,
              ),
              onPressed: () {
                _confirmAndToggleWishlist(stock);
              },
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockDetailPage(stock: stock),
              ),
            ),
          ),
        );
      },
    );
  }
} 