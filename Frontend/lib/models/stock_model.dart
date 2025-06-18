class Stock {
  final String symbol;
  final String name;
  final int instrumentToken;
  final String exchange;
  final String instrumentType;
  final String segment;
  final String? expiry;
  final double? strike;
  final double tickSize;
  final int lotSize;
  final Map<String, dynamic>? quote;
  final List<Map<String, dynamic>>? historicalData;
  final String? lastUpdated;

  Stock({
    required this.symbol,
    required this.name,
    required this.instrumentToken,
    required this.exchange,
    required this.instrumentType,
    required this.segment,
    this.expiry,
    this.strike,
    required this.tickSize,
    required this.lotSize,
    this.quote,
    this.historicalData,
    this.lastUpdated,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      instrumentToken: json['instrument_token'] ?? 0,
      exchange: json['exchange'] ?? '',
      instrumentType: json['instrument_type'] ?? '',
      segment: json['segment'] ?? '',
      expiry: json['expiry'],
      strike: json['strike']?.toDouble(),
      tickSize: json['tick_size']?.toDouble() ?? 0.0,
      lotSize: json['lot_size'] ?? 0,
      quote: json['quote'],
      historicalData: json['historical_data'] != null 
          ? List<Map<String, dynamic>>.from(json['historical_data'])
          : null,
      lastUpdated: json['last_updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'instrument_token': instrumentToken,
      'exchange': exchange,
      'instrument_type': instrumentType,
      'segment': segment,
      'expiry': expiry,
      'strike': strike,
      'tick_size': tickSize,
      'lot_size': lotSize,
      'quote': quote,
      'historical_data': historicalData,
      'last_updated': lastUpdated,
    };
  }

  // Helper methods to get quote data
  double? get lastPrice => quote?['last_price']?.toDouble();
  int? get volume => quote?['volume'];
  double? get change => quote?['change']?.toDouble();
  double? get high => quote?['high']?.toDouble();
  double? get low => quote?['low']?.toDouble();
  double? get open => quote?['open']?.toDouble();
  double? get close => quote?['close']?.toDouble();

  // Helper method to get change percentage
  double? get changePercent {
    if (lastPrice != null && close != null && close != 0) {
      return ((lastPrice! - close!) / close!) * 100;
    }
    return null;
  }

  // Helper method to get sector (simplified)
  String get sector {
    // This is a simplified mapping - you can expand this based on your needs
    if (name.contains('BANK') || name.contains('FINANCE')) return 'Banking & Finance';
    if (name.contains('TECH') || name.contains('SOFTWARE')) return 'Technology';
    if (name.contains('PHARMA') || name.contains('HEALTH')) return 'Healthcare';
    if (name.contains('AUTO') || name.contains('MOTOR')) return 'Automotive';
    if (name.contains('OIL') || name.contains('PETRO')) return 'Oil & Gas';
    if (name.contains('POWER') || name.contains('ENERGY')) return 'Power & Energy';
    return 'Others';
  }

  // Helper method to get rating based on performance
  String get rating {
    final change = changePercent ?? 0;
    if (change > 5) return 'Buy';
    if (change > 0) return 'Hold';
    return 'Sell';
  }

  // Helper method to get performance percentage
  double get perfPercent => changePercent ?? 0.0;
} 