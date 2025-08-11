import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'watchlist_page.dart';
import 'events_page.dart';
import 'stock_list_page.dart';
import 'main.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  Future<List<NewsItem>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('https://zerodha-production-04a6.up.railway.app/api/news'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newsList = data['news'] as List;
        return newsList.map((item) {
          return NewsItem(
            title: item['title'] ?? '',
            link: item['link'] ?? '',
            description: item['description'] ?? '',
            pubDate: item['pubDate'] ?? '',
            source: item['source'] ?? 'Unknown',
          );
        }).toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to load news');
    }
  }

  Future<void> _openUrl(String urlString) async {
    print('🔗 Attempting to open URL: $urlString');
    
    try {
      if (urlString.isEmpty) {
        print('❌ Empty URL provided');
        _showUrlError('Invalid news link');
        return;
      }

      String cleanUrl = urlString;
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        cleanUrl = 'https://$urlString';
        print('🔧 Added https protocol: $cleanUrl');
      }

      final uri = Uri.parse(cleanUrl);
      print('🌐 Parsed URI: $uri');

      bool canLaunch = await canLaunchUrl(uri);
      print('✅ Can launch URL: $canLaunch');

      if (canLaunch) {
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
          ),
        );
        
        print('🚀 URL launched successfully: $launched');
        
        if (!launched) {
          print('❌ Launch returned false, trying alternative method');
          await _tryAlternativeLaunch(uri);
        }
      } else {
        print('❌ Cannot launch URL, trying alternative method');
        await _tryAlternativeLaunch(uri);
      }
    } catch (e) {
      print('💥 Error launching URL: $e');
      _showUrlError('Failed to open article: ${e.toString()}');
    }
  }

  Future<void> _tryAlternativeLaunch(Uri uri) async {
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      
      if (!launched) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
          ),
        );
        print('📱 Opened in in-app web view');
      } else {
        print('✅ Alternative launch successful');
      }
    } catch (e) {
      print('❌ Alternative launch failed: $e');
      _showUrlError('Unable to open article. Please check your internet connection.');
    }
  }

  void _showUrlError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _formatDate(String pubDate) {
    try {
      final parts = pubDate.split(' ');
      if (parts.length >= 4) {
        return '${parts[1]} ${parts[2]} ${parts[3]}';
      }
      return pubDate;
    } catch (_) {
      return pubDate;
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
        title: Row(
          children: [
            Icon(Icons.article, color: Colors.white),
            SizedBox(width: 8),
            Text('Market News'),
          ],
        ),
        backgroundColor: Colors.teal[700],
        elevation: 3,
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
                // Already on News page; optionally refresh or do nothing. We'll keep navigation consistent.
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
                // No direct AuthService import here; handled from main wrapper generally
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
      body: FutureBuilder<List<NewsItem>>(
        future: fetchNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Failed to load news', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No news available'));
          }
          
          final newsList = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 16),
            itemCount: newsList.length,
            separatorBuilder: (context, index) => SizedBox(height: 0),
            itemBuilder: (context, index) {
              final news = newsList[index];
              return GestureDetector(
                onTap: () async {
                  await _openUrl(news.link);
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.07),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal[800]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          news.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
                        ),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.teal[300], size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    _formatDate(news.pubDate),
                                    style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.source, color: Colors.teal, size: 16),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      news.source,
                                      style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.open_in_new, color: Colors.teal, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: Colors.grey,
    );
  }
}

class NewsItem {
  final String title;
  final String link;
  final String description;
  final String pubDate;
  final String source;
  
  NewsItem({
    required this.title,
    required this.link,
    required this.description,
    required this.pubDate,
    required this.source,
  });
}
