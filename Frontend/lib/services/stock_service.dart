import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  // Update this URL based on your setup:
  // - Android Emulator: http://10.0.2.2:5000/api
  // - iOS Simulator: http://localhost:5000/api
  // - Physical Device (USB): http://192.168.0.8:5000/api (your computer's IP)
  // - Physical Device (WiFi): http://YOUR_COMPUTER_IP:5000/api
  static const String baseUrl = 'http://192.168.0.8:5000/api';
  
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
  
  // Get real-time quote for a stock
  static Future<Map<String, dynamic>> getQuote(String symbol) async {
    try {
      final uri = Uri.parse('$baseUrl/quote/$symbol');
      print('Making request to: $uri'); // Debug log
      final response = await http.get(uri);
      
      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed quote data: $data'); // Debug log
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Quote not available');
      } else {
        throw Exception('Failed to load quote: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getQuote: $e'); // Debug log
      throw Exception('Error fetching quote: $e');
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
} 