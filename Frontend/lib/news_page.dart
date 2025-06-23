import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  Future<List<NewsItem>> fetchNews() async {
    final response = await http.get(Uri.parse('https://pulse.zerodha.com/feed.php'));
    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');
      return items.map((node) {
        return NewsItem(
          title: node.findElements('title').single.text,
          link: node.findElements('link').single.text,
          description: node.findElements('description').single.text,
          pubDate: node.findElements('pubDate').isNotEmpty ? node.findElements('pubDate').single.text : '',
        );
      }).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }

  String _formatDate(String pubDate) {
    // Example: Mon, 23 Jun 2025 20:49:46 +0530
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
      body: FutureBuilder<List<NewsItem>>(
        future: fetchNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Shimmer/skeleton loader
            return ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load news', style: TextStyle(color: Colors.red)));
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
                  final url = Uri.parse(news.link);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
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
                          style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.4),
                        ),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.teal[300], size: 16),
                                SizedBox(width: 6),
                                Text(
                                  _formatDate(news.pubDate),
                                  style: TextStyle(color: Colors.teal[400], fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
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
      backgroundColor: Colors.grey[100],
    );
  }
}

class NewsItem {
  final String title;
  final String link;
  final String description;
  final String pubDate;
  NewsItem({required this.title, required this.link, required this.description, required this.pubDate});
} 