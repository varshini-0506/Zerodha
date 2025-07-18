import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  // Deployed backend URL
  static const String baseUrl = 'https://zerodha-ay41.onrender.com/api';
  
  // Get all stocks with pagination and search
  static Future<Map<String, dynamic>> getStocks({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final uri = Uri.parse('$baseUrl/stocks').replace(queryParameters: queryParams);
      print('Making request to: $uri'); // Debug log
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load stocks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getStocks: $e'); // Debug log
      throw Exception('Error fetching stocks: $e');
    }
  }
  
  // Get popular stocks
  static Future<List<Map<String, dynamic>>> getPopularStocks() async {
    try {
      final uri = Uri.parse('$baseUrl/stocks/popular');
      print('Making request to: $uri'); // Debug log
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['stocks']);
      } else {
        throw Exception('Failed to load popular stocks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPopularStocks: $e'); // Debug log
      throw Exception('Error fetching popular stocks: $e');
    }
  }
  
  // Get detailed stock information
  static Future<Map<String, dynamic>> getStockDetail(String symbol) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stocks/$symbol'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Stock not found');
      } else {
        throw Exception('Failed to load stock details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stock details: $e');
    }
  }
  
  // Search stocks
  static Future<List<Map<String, dynamic>>> searchStocks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search').replace(queryParameters: {'q': query})
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        throw Exception('Failed to search stocks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching stocks: $e');
    }
  }
  
  // Get market status
  static Future<Map<String, dynamic>> getMarketStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market_status'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load market status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching market status: $e');
    }
  }

  // Add a stock to the user's wishlist
  static Future<void> addToWishlist({required String userId, required String symbol}) async {
    final url = Uri.parse('$baseUrl/wishlist');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'symbol': symbol}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add to wishlist: ${response.body}');
    }
  }

  // Get all wishlisted stocks for a user (returns list of symbols)
  static Future<List<String>> getWishlist({required String userId}) async {
    final url = Uri.parse('$baseUrl/wishlist/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['wishlist'] ?? []);
    } else {
      throw Exception('Failed to fetch wishlist: ${response.body}');
    }
  }

  // Remove a stock from the user's wishlist
  static Future<void> removeFromWishlist({required String userId, required String symbol}) async {
    final url = Uri.parse('$baseUrl/wishlist');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId, 'symbol': symbol}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from wishlist: ${response.body}');
    }
  }
} 