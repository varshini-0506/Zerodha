import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkDebugHelper {
  static Future<void> runNetworkDiagnostics() async {
    print('🔍 === NETWORK DIAGNOSTICS START ===');
    
    // Test 1: Basic connectivity
    await _testBasicConnectivity();
    
    // Test 2: DNS resolution
    await _testDnsResolution();
    
    // Test 3: API connectivity
    await _testApiConnectivity();
    
    // Test 4: Certificate verification
    await _testCertificates();
    
    print('🔍 === NETWORK DIAGNOSTICS END ===');
  }
  
  static Future<void> _testBasicConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      print('✅ Basic connectivity: ${result.isNotEmpty ? 'OK' : 'FAILED'}');
    } catch (e) {
      print('❌ Basic connectivity failed: $e');
    }
  }
  
  static Future<void> _testDnsResolution() async {
    try {
      final result = await InternetAddress.lookup('zerodha-production-04a6.up.railway.app');
      print('✅ DNS resolution: ${result.isNotEmpty ? 'OK' : 'FAILED'}');
      if (result.isNotEmpty) {
        print('📍 Resolved to: ${result.first.address}');
      }
    } catch (e) {
      print('❌ DNS resolution failed: $e');
    }
  }
  
  static Future<void> _testApiConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('https://zerodha-production-04a6.up.railway.app/api/market_status'),
      ).timeout(Duration(seconds: 15));
      print('✅ API connectivity: ${response.statusCode == 200 ? 'OK' : 'FAILED (${response.statusCode})'}');
    } catch (e) {
      print('❌ API connectivity failed: $e');
    }
  }
  
  static Future<void> _testCertificates() async {
    try {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        print('⚠️ Certificate warning for $host:$port');
        return false; // Reject bad certificates
      };
      
      final request = await client.getUrl(Uri.parse('https://zerodha-production-04a6.up.railway.app/api/market_status'));
      final response = await request.close();
      print('✅ Certificate validation: ${response.statusCode == 200 ? 'OK' : 'FAILED'}');
      
      client.close();
    } catch (e) {
      print('❌ Certificate validation failed: $e');
    }
  }
}
