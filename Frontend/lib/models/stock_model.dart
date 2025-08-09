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
  final double? lastPrice;
  final int? lastQuantity;
  final String? lastTradeTime;
  final double? lowerCircuitLimit;
  final double? netChange;
  final Map<String, dynamic>? ohlc;
  final int? volume;

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
    this.lastPrice,
    this.lastQuantity,
    this.lastTradeTime,
    this.lowerCircuitLimit,
    this.netChange,
    this.ohlc,
    this.volume,
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
      lastPrice: (json['last_price'] ?? json['quote']?['last_price'])?.toDouble(),
      lastQuantity: (json['last_quantity'] ?? json['quote']?['last_quantity'])?.toInt(),
      lastTradeTime: json['last_trade_time'] ?? json['quote']?['last_trade_time'],
      lowerCircuitLimit: (json['lower_circuit_limit'] ?? json['quote']?['lower_circuit_limit'])?.toDouble(),
      netChange: (json['net_change'] ?? json['quote']?['net_change'])?.toDouble(),
      ohlc: json['ohlc'] ?? json['quote']?['ohlc'],
      volume: (json['volume'] ?? json['quote']?['volume'])?.toInt(),
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
      'last_price': lastPrice,
      'last_quantity': lastQuantity,
      'last_trade_time': lastTradeTime,
      'lower_circuit_limit': lowerCircuitLimit,
      'net_change': netChange,
      'ohlc': ohlc,
      'volume': volume,
    };
  }

  // Helper methods to get quote data
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

  Stock copyWith({
    double? lastPrice,
    Map<String, dynamic>? quote,
    int? lastQuantity,
    String? lastTradeTime,
    double? netChange,
    Map<String, dynamic>? ohlc,
    int? volume,
  }) {
    return Stock(
      symbol: symbol,
      name: name,
      instrumentToken: instrumentToken,
      exchange: exchange,
      instrumentType: instrumentType,
      segment: segment,
      expiry: expiry,
      strike: strike,
      tickSize: tickSize,
      lotSize: lotSize,
      quote: quote ?? this.quote,
      historicalData: historicalData,
      lastUpdated: lastUpdated,
      lastPrice: lastPrice ?? this.lastPrice,
      lastQuantity: lastQuantity ?? this.lastQuantity,
      lastTradeTime: lastTradeTime ?? this.lastTradeTime,
      lowerCircuitLimit: lowerCircuitLimit,
      netChange: netChange ?? this.netChange,
      ohlc: ohlc ?? this.ohlc,
      volume: volume ?? this.volume,
    );
  }
} 