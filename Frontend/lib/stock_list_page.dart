import 'package:flutter/material.dart';
import 'models/stock_model.dart';
import 'stock_detail_page.dart';
import 'watchlist_page.dart';
import 'services/stock_service.dart';
import 'news_page.dart';
import 'auth_service.dart';
import 'auth_page.dart';
import 'main.dart';
import 'dart:async';
import 'dart:io';
import 'events_page.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  
  // User data
  String? userEmail;
  String? username;
  
  // Pagination variables
  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  static const int pageSize = 25; // Reduced from 50 for better performance

  List<String> sectors = ['All', 'Technology', 'Banking & Finance', 'Healthcare', 'Automotive', 'Oil & Gas', 'Power & Energy', 'Others'];
  List<String> ratings = ['All', 'Buy', 'Hold', 'Sell'];
  List<String> perfOptions = ['All', 'Positive', 'Negative'];

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _loadUserData();
  }

  Future<void> _diagnosNetwork() async {
    print('🔍 Running network diagnostics...');
    
    // Test basic internet connectivity first
    try {
      final result = await InternetAddress.lookup('google.com');
      print('🌐 Basic internet connectivity: ${result.isNotEmpty ? 'OK' : 'FAILED'}');
    } catch (e) {
      print('❌ Basic internet connectivity failed: $e');
    }
    
    // Test your own API - this is what really matters for the app
    final apiConnected = await StockService.testApiConnection();
    print('🔗 API connectivity: ${apiConnected ? 'OK' : 'FAILED'}');
    
    if (!mounted) return;
    
    if (!apiConnected) {
      setState(() {
        hasError = true;
        errorMessage = 'Cannot connect to server. Please check:\n'
            '1. Your internet connection\n'
            '2. Server availability\n'
            '3. App permissions\n'
            '4. Network security settings';
      });
    }
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      hasError = false;
    });
    
    // Run network diagnostics first
    await _diagnosNetwork();
    
    if (!mounted) return;
    
    if (!hasError) {
      await _loadStocks();
      await _loadWishlist();
    }
  }

  Future<void> _loadStocks() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      if (kDebugMode) {
        print('Starting to load stocks...');
      }
      
      // Load popular stocks first (these are most important)
      if (kDebugMode) {
        print('Loading popular stocks...');
      }
      final popularStocksData = await StockService.getPopularStocks();
      final popularStocks = popularStocksData.map((json) => Stock.fromJson(json)).toList();
      if (kDebugMode) {
        print('Loaded ${popularStocks.length} popular stocks');
      }
      
      // Load only first page of stocks initially (reduced from 50 to 25)
      if (kDebugMode) {
        print('Loading initial stocks...');
      }
      final stocksData = await StockService.getStocks(page: 1, limit: 25);
      final stocks = (stocksData['stocks'] as List)
          .map((json) => Stock.fromJson(json))
          .toList();
      if (kDebugMode) {
        print('Loaded ${stocks.length} initial stocks');
      }

      // Combine stocks
      final allStocksCombined = [...popularStocks, ...stocks];
      if (kDebugMode) {
        print('Combined ${allStocksCombined.length} stocks');
      }
      
      if (!mounted) return;
      
      // Show stocks immediately without quotes, then update with quotes
      setState(() {
        allStocks = allStocksCombined;
        filteredStocks = allStocksCombined;
        isLoading = false;
      });

      // Fetch quotes in background
      _fetchQuotesInBackground(allStocksCombined);

    } catch (e) {
      if (kDebugMode) {
        print('Error in _loadStocks: $e');
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  // New method to fetch quotes in background
  Future<void> _fetchQuotesInBackground(List<Stock> stocks) async {
    try {
      print('🔄 Fetching quotes in background for ${stocks.length} stocks...');
      
      final stocksWithQuotes = await _fetchQuotesForStocks(stocks);
      
      if (!mounted) return;
      
      print('📊 Updating UI with ${stocksWithQuotes.length} stocks');
      print('📈 Stocks with quotes: ${stocksWithQuotes.where((s) => s.quote != null).length}');
      
      setState(() {
        allStocks = stocksWithQuotes;
        filteredStocks = stocksWithQuotes;
      });
      
      _applyFilters();
      
      print('✅ Successfully updated ${stocksWithQuotes.length} stocks with quotes');
    } catch (e) {
      print('❌ Error fetching quotes in background: $e');
      // Don't show error to user, just log it
    }
  }

  Future<void> _loadUserData() async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;
    
    try {
      if (!mounted) return;
      setState(() {
        userEmail = user.email;
      });
      
      // Fetch username from database
      final userData = await AuthService().getUserData(user.id);
      if (userData != null && mounted) {
        setState(() {
          username = userData['username'] as String?;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadWishlist() async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;
    try {
      final symbols = await StockService.getWishlist(userId: user.id);
      if (!mounted) return;
      setState(() {
        wishlistSymbols = symbols.toSet();
      });
    } catch (e) {
      // ignore error
    }
  }

  Future<void> _loadMoreStocks() async {
    if (isLoadingMore || !hasMoreData) return;
    
    if (!mounted) return;
    setState(() {
      isLoadingMore = true;
    });
    
    try {
      final nextPage = currentPage + 1;
      if (kDebugMode) {
        print('🔄 Loading more stocks (page $nextPage)...');
      }
      
      final stocksData = await StockService.getStocks(page: nextPage, limit: pageSize);
      final newStocks = (stocksData['stocks'] as List)
          .map((json) => Stock.fromJson(json))
          .toList();
      
      if (!mounted) return;
      
      if (newStocks.isEmpty) {
        setState(() {
          hasMoreData = false;
          isLoadingMore = false;
        });
        return;
      }
      
      // Fetch quotes for new stocks
      final newStocksWithQuotes = await _fetchQuotesForStocks(newStocks);
      
      if (!mounted) return;
      
      setState(() {
        allStocks.addAll(newStocksWithQuotes);
        currentPage = nextPage;
        isLoadingMore = false;
      });
      
      _applyFilters();
      if (kDebugMode) {
        print('✅ Loaded ${newStocksWithQuotes.length} more stocks');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading more stocks: $e');
      }
      if (!mounted) return;
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<List<Stock>> _fetchQuotesForStocks(List<Stock> stocks) async {
    final stocksWithQuotes = <Stock>[];
    
    // Increase limit to 50 stocks for better performance (backend limit)
    final stocksToFetch = stocks.take(50).toList();
    final symbols = stocksToFetch.map((stock) => stock.symbol).toList();
    
    try {
      print('🔄 Fetching batch quotes for ${symbols.length} stocks...');
      print('📋 First 5 symbols: ${symbols.take(5).join(', ')}');
      
      // Use batch quotes API for better performance
      final batchQuotesResponse = await StockService.getBatchQuotes(symbols);
      final quotes = batchQuotesResponse['quotes'] as Map<String, dynamic>;
      
      print('✅ Received quotes for ${quotes.length} symbols');
      print('📊 Quote keys: ${quotes.keys.take(5).join(', ')}');
      
      // Update stocks with quote data
      int updatedCount = 0;
      for (final stock in stocksToFetch) {
        final quoteData = quotes[stock.symbol.toUpperCase()];
        if (quoteData != null) {
          // Create a new stock object with quote data
          final stockWithQuote = stock.copyWith(
            quote: quoteData,
            lastPrice: quoteData['last_price']?.toDouble(),
            volume: quoteData['volume']?.toInt(),
            netChange: quoteData['change']?.toDouble(),
          );
          stocksWithQuotes.add(stockWithQuote);
          updatedCount++;
        } else {
          print('⚠️ No quote data for symbol: ${stock.symbol}');
          stocksWithQuotes.add(stock);
        }
      }
      
      print('📈 Updated ${updatedCount} stocks with quote data');
      
    } catch (e) {
      print('❌ Error fetching batch quotes: $e');
      // If batch quotes fail, add stocks without quotes
      stocksWithQuotes.addAll(stocksToFetch);
    }
    
    // Add remaining stocks without quotes
    stocksWithQuotes.addAll(stocks.skip(50));
    
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

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final searchResults = await StockService.searchStocks(query);
      final searchStocks = searchResults.map((json) => Stock.fromJson(json)).toList();
      
      // Fetch quotes for search results using batch API
      final stocksWithQuotes = await _fetchQuotesForStocks(searchStocks);
      
      if (!mounted) return;
      setState(() {
        filteredStocks = stocksWithQuotes;
        isLoading = false;
        // Reset pagination for search results
        currentPage = 1;
        hasMoreData = false; // Search results don't support pagination
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
    }
  }

  Future _confirmAndToggleWishlist(Stock stock) async {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      
      title: Text(
        '${action == 'add' ? 'Add to' : 'Remove from'} Wishlist',
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      
      // Reduced content with minimal padding
      content: Text(
        'Are you sure you want to ${action == 'add' ? 'add' : 'remove'} ${stock.symbol} ${action == 'add' ? 'to' : 'from'} your wishlist?',
        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
      ),
      
      // Key fix: Minimal padding between content and actions
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 12), // Reduced bottom padding from 0 to 12
      actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 16),   // Reduced top padding from 8 to 0
      
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            minimumSize: Size(80, 40),
          ),
          child: Text(
            'Cancel', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        
        // Confirm button
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: action == 'add' ? Colors.teal : Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size(80, 40),
            elevation: 2,
          ),
          child: Text(
            'Yes', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  
  if (confirmed != true) return;
  
  try {
    if (isWishlisted) {
      await StockService.removeFromWishlist(userId: user.id, symbol: stock.symbol);
      if (mounted) {
        setState(() {
          wishlistSymbols.remove(stock.symbol);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stock.symbol} removed from wishlist!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await StockService.addToWishlist(userId: user.id, symbol: stock.symbol);
      if (mounted) {
        setState(() {
          wishlistSymbols.add(stock.symbol);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stock.symbol} added to wishlist!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${action == 'add' ? 'add to' : 'remove from'} wishlist: $e'),
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
            // User Profile Section
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
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    username ?? 'User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userEmail ?? 'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
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
              tileColor: Colors.teal[50],
              onTap: () {
                Navigator.pop(context);
                // Already on Home page
              },
            ),
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
             ListTile(
               leading: Icon(Icons.logout, color: Colors.red),
               title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               onTap: () async {
                 Navigator.pop(context);
                 await AuthService().signOut();
                 // Clear user data
                 setState(() {
                   userEmail = null;
                   username = null;
                 });
                 // Navigate back to the root and clear all previous routes
                 Navigator.pushAndRemoveUntil(
                   context,
                   MaterialPageRoute(builder: (context) => AuthWrapper()),
                   (route) => false,
                 );
               },
             ),
             SizedBox(height: 16),
              // Footer label removed
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
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                        hasError = false;
                      });
                      
                      // Run full network diagnostics
                      await _diagnosNetwork();
                      
                      if (!mounted) return;
                      
                      if (!hasError) {
                        await _initializeApp();
                      } else {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                    child: Text('Test Connection'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      print('🧪 Testing simple HTTP request...');
                      try {
                        final response = await http.get(Uri.parse('https://httpbin.org/get'));
                        print('✅ Simple HTTP test successful: ${response.statusCode}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('HTTP test successful: ${response.statusCode}')),
                        );
                      } catch (e) {
                        print('❌ Simple HTTP test failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('HTTP test failed: $e')),
                        );
                      }
                    },
                    child: Text('Test HTTP'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
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

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          // User reached the bottom, load more stocks
          if (!isLoadingMore && hasMoreData) {
            _loadMoreStocks();
          }
        }
        return false;
      },
      child: ListView.builder(
        itemCount: filteredStocks.length + (hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          // Show load more indicator at the end
          if (index == filteredStocks.length && hasMoreData) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Center(
                child: isLoadingMore 
                  ? Column(
                      children: [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 8),
                        Text('Loading more stocks...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _loadMoreStocks,
                      child: Text('Load More Stocks'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    ),
              ),
            );
          }
          
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
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any ongoing operations, timers, or streams
    // This prevents memory leaks and setState calls after widget disposal
    super.dispose();
  }
} 