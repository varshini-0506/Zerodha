import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class StockService {
  // Deployed backend URL
  static const String baseUrl = 'https://zerodha-ay41.onrender.com/api';
  
  // HTTP client with optimized configuration for mobile networks
  static final http.Client _client = http.Client();
  
  // Increased timeout for mobile networks
  static const Duration _timeout = Duration(seconds: 30);
  
  // Connection pooling and retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // Get all stocks with pagination and search
  static Future<Map<String, dynamic>> getStocks({
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    return _retryRequest(() async {
      try {
        final queryParams = <String, String>{
          'page': page.toString(),
          'limit': limit.toString(),
        };
        
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        
        final uri = Uri.parse('$baseUrl/stocks').replace(queryParameters: queryParams);
        
        // Only log in debug mode
        if (kDebugMode) {
          print('Making request to: $uri');
        }
        
        final response = await _client.get(uri).timeout(_timeout);
        
        if (kDebugMode) {
          print('Response status: ${response.statusCode}');
          print('Response body length: ${response.body.length}');
        }
        
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to load stocks: ${response.statusCode} - ${response.body}');
        }
      } on SocketException catch (e) {
        if (kDebugMode) {
          print('Network error in getStocks: $e');
        }
        throw Exception('Network error: Please check your internet connection');
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          print('Timeout error in getStocks: $e');
        }
        throw Exception('Request timeout: Please try again');
      } catch (e) {
        if (kDebugMode) {
          print('Error in getStocks: $e');
        }
        throw Exception('Error fetching stocks: $e');
      }
    });
  }
  
  // Get popular stocks
  static Future<List<Map<String, dynamic>>> getPopularStocks() async {
    return _retryRequest(() async {
      try {
        final uri = Uri.parse('$baseUrl/stocks/popular');
        
        if (kDebugMode) {
          print('Making request to: $uri');
        }
        
        final response = await _client.get(uri).timeout(_timeout);
        
        if (kDebugMode) {
          print('Popular stocks response status: ${response.statusCode}');
        }
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return List<Map<String, dynamic>>.from(data['stocks']);
        } else {
          throw Exception('Failed to load popular stocks: ${response.statusCode} - ${response.body}');
        }
      } on SocketException catch (e) {
        if (kDebugMode) {
          print('Network error in getPopularStocks: $e');
        }
        throw Exception('Network error: Please check your internet connection');
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          print('Timeout error in getPopularStocks: $e');
        }
        throw Exception('Request timeout: Please try again');
      } catch (e) {
        if (kDebugMode) {
          print('Error in getPopularStocks: $e');
        }
        throw Exception('Error fetching popular stocks: $e');
      }
    });
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

  // Optimized batch quotes with better error handling
  static Future<Map<String, dynamic>> getBatchQuotes(List<String> symbols) async {
    return _retryRequest(() async {
      try {
        final uri = Uri.parse('$baseUrl/stocks/batch_quotes');
        
        if (kDebugMode) {
          print('Making batch quotes request to: $uri');
          print('Symbols: $symbols');
        }
        
        // Add headers for better mobile compatibility
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        };
        
        final response = await _client.post(
          uri,
          headers: headers,
          body: json.encode({'symbols': symbols}),
        ).timeout(_timeout);
        
        if (kDebugMode) {
          print('Batch quotes response status: ${response.statusCode}');
        }
        
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw Exception('Failed to load batch quotes: ${response.statusCode} - ${response.body}');
        }
      } on SocketException catch (e) {
        if (kDebugMode) {
          print('Network error in getBatchQuotes: $e');
        }
        throw Exception('Network error: Please check your internet connection');
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          print('Timeout error in getBatchQuotes: $e');
        }
        throw Exception('Request timeout: Please try again');
      } catch (e) {
        if (kDebugMode) {
          print('Error in getBatchQuotes: $e');
        }
        throw Exception('Error fetching batch quotes: $e');
      }
    });
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

  // Test API connectivity
  static Future<bool> testApiConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/market_status');
      
      if (kDebugMode) {
        print('Testing API connection to: $uri');
      }
      
      final response = await _client.get(uri).timeout(Duration(seconds: 10));
      
      if (kDebugMode) {
        print('API test response status: ${response.statusCode}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('API connection test failed: $e');
      }
      return false;
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

  // Retry mechanism for network requests
  static Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) {
          rethrow;
        }
        if (kDebugMode) {
          print('Request failed, retrying in ${_retryDelay.inSeconds}s... (attempt $attempts/$_maxRetries)');
        }
        await Future.delayed(_retryDelay);
      }
    }
    throw Exception('Max retries exceeded');
  }
} 