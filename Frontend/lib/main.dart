import 'package:flutter/material.dart';

void main() {
  runApp(StockApp());
}

class StockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Tracker',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.grey[100], // Light gray background
        cardColor: Colors.white, // White cards for contrast
        primaryColor: Colors.teal, // Vibrant teal for accents
        colorScheme: ColorScheme.light(
          primary: Colors.teal,
          secondary: Colors.amber,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: Colors.black87,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          bodySmall: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
        ),
      ),
      home: StockListPage(),
    );
  }
}

class Stock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final String sector;
  final String rating;
  final double marketCap;
  final double peRatio;
  final double epsGrowth;
  final double dividendYield;
  final double roe;
  final String recentEarningsDate;
  final String upcomingEarningsDate;
  final double perfPercent;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.sector,
    required this.rating,
    required this.marketCap,
    required this.peRatio,
    required this.epsGrowth,
    required this.dividendYield,
    required this.roe,
    required this.recentEarningsDate,
    required this.upcomingEarningsDate,
    required this.perfPercent,
  });
}

List<Stock> sampleStocks = [
  Stock(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    price: 197.45,
    change: -0.88,
    sector: 'Technology',
    rating: 'Buy',
    marketCap: 2500,
    peRatio: 28.5,
    epsGrowth: 5.2,
    dividendYield: 0.8,
    roe: 12.3,
    recentEarningsDate: '2024-04-15',
    upcomingEarningsDate: '2024-07-15',
    perfPercent: 8.5,
  ),
  Stock(
    symbol: 'MSFT',
    name: 'Microsoft Corp.',
    price: 476.65,
    change: -0.46,
    sector: 'Technology',
    rating: 'Hold',
    marketCap: 2200,
    peRatio: 30.1,
    epsGrowth: 4.8,
    dividendYield: 0.9,
    roe: 11.7,
    recentEarningsDate: '2024-03-28',
    upcomingEarningsDate: '2024-07-28',
    perfPercent: 6.9,
  ),
  Stock(
    symbol: 'GOOG',
    name: 'Alphabet Inc.',
    price: 176.64,
    change: -0.19,
    sector: 'Technology',
    rating: 'Buy',
    marketCap: 1800,
    peRatio: 26.4,
    epsGrowth: 6.3,
    dividendYield: 0.7,
    roe: 10.5,
    recentEarningsDate: '2024-04-10',
    upcomingEarningsDate: '2024-07-10',
    perfPercent: 7.2,
  ),
  Stock(
    symbol: 'TSLA',
    name: 'Tesla Inc.',
    price: 312.12,
    change: 1.2,
    sector: 'Automotive',
    rating: 'Sell',
    marketCap: 950,
    peRatio: 20.1,
    epsGrowth: 3.5,
    dividendYield: 0.0,
    roe: 8.9,
    recentEarningsDate: '2024-04-08',
    upcomingEarningsDate: '2024-07-08',
    perfPercent: -2.4,
  ),
  Stock(
    symbol: 'AMZN',
    name: 'Amazon.com Inc.',
    price: 211.62,
    change: 0.76,
    sector: 'Consumer Services',
    rating: 'Hold',
    marketCap: 1700,
    peRatio: 33.2,
    epsGrowth: 5.0,
    dividendYield: 0.5,
    roe: 9.8,
    recentEarningsDate: '2024-04-12',
    upcomingEarningsDate: '2024-07-12',
    perfPercent: 5.7,
  ),
];

class StockListPage extends StatefulWidget {
  @override
  _StockListPageState createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  String searchQuery = '';
  String selectedSector = 'All';
  String selectedRating = 'All';
  String selectedPerf = 'All';
  List<Stock> watchlist = [sampleStocks[0], sampleStocks[1]]; // Initialize with AAPL and MSFT

  List<String> sectors = ['All', 'Technology', 'Automotive', 'Consumer Services'];
  List<String> ratings = ['All', 'Buy', 'Hold', 'Sell'];
  List<String> perfOptions = ['All', 'Positive', 'Negative'];

  @override
  Widget build(BuildContext context) {
    final filteredStocks = sampleStocks.where((stock) {
      final matchesSearch = stock.name.toLowerCase().contains(searchQuery) ||
          stock.symbol.toLowerCase().contains(searchQuery);
      final matchesSector = selectedSector == 'All' || stock.sector == selectedSector;
      final matchesRating = selectedRating == 'All' || stock.rating == selectedRating;
      final matchesPerf = selectedPerf == 'All' ||
          (selectedPerf == 'Positive' && stock.perfPercent >= 0) ||
          (selectedPerf == 'Negative' && stock.perfPercent < 0);
      return matchesSearch && matchesSector && matchesRating && matchesPerf;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('All Stocks'),
        actions: [
          IconButton(
            icon: Icon(Icons.star, color: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WatchlistPage(watchlist: watchlist),
                ),
              );
            },
          )
        ],
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
                  searchQuery = query.toLowerCase();
                });
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
            child: ListView.builder(
              itemCount: filteredStocks.length,
              itemBuilder: (context, index) {
                final stock = filteredStocks[index];
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
                    subtitle: Text('₹${stock.price} | ${stock.change}% | ${stock.rating} | ${stock.sector}',
                        style: TextStyle(color: Colors.grey[600])),
                    trailing: IconButton(
                      icon: Icon(
                        watchlist.contains(stock) ? Icons.star : Icons.star_border,
                        color: watchlist.contains(stock) ? Colors.amber : Colors.teal,
                      ),
                      onPressed: () {
                        setState(() {
                          if (!watchlist.contains(stock)) {
                            watchlist.add(stock);
                          } else {
                            watchlist.remove(stock);
                          }
                        });
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
          ),
        ],
      ),
    );
  }
}

class StockDetailPage extends StatelessWidget {
  final Stock stock;

  const StockDetailPage({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${stock.symbol} - ${stock.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price and change section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${stock.price}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text(
                      '${stock.change >= 0 ? '+' : ''}${stock.change}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: stock.change >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        stock.rating == 'Buy' ? Colors.green[100]! : stock.rating == 'Sell' ? Colors.red[100]! : Colors.blue[100]!,
                        stock.rating == 'Buy' ? Colors.green[50]! : stock.rating == 'Sell' ? Colors.red[50]! : Colors.blue[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    stock.rating,
                    style: TextStyle(
                      color: stock.rating == 'Buy' ? Colors.green[800] : stock.rating == 'Sell' ? Colors.red[800] : Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Price chart placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 40, color: Colors.teal),
                    SizedBox(height: 8),
                    Text('Price Chart', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            // Key metrics section
            Text('Key Metrics', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
              children: [
                _buildMetricItem('Sector', stock.sector),
                _buildMetricItem('Market Cap', '₹${stock.marketCap}B'),
                _buildMetricItem('P/E Ratio', stock.peRatio.toString()),
                _buildMetricItem('EPS Growth', '${stock.epsGrowth}%'),
                _buildMetricItem('Dividend Yield', '${stock.dividendYield}%'),
                _buildMetricItem('ROE', '${stock.roe}%'),
              ],
            ),
            SizedBox(height: 24),
            // Earnings section
            Text('Earnings', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            _buildEarningsItem(Icons.calendar_today, 'Recent', stock.recentEarningsDate),
            _buildEarningsItem(Icons.event, 'Upcoming', stock.upcomingEarningsDate),
            SizedBox(height: 24),
            // Performance section
            Text('Performance', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: stock.perfPercent.abs() / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                stock.perfPercent >= 0 ? Colors.green : Colors.red,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8),
            Text('${stock.perfPercent >= 0 ? '+' : ''}${stock.perfPercent}%',
                style: TextStyle(
                  color: stock.perfPercent >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildEarningsItem(IconData icon, String label, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(date, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}

class WatchlistPage extends StatelessWidget {
  final List<Stock> watchlist;
  const WatchlistPage({super.key, required this.watchlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wishlist')),
      body: ListView.builder(
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
              subtitle: Text('₹${stock.price} | ${stock.change}% | ${stock.rating} | ${stock.sector}',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          );
        },
      ),
    );
  }
}