# Zerodha Stock Tracker - Flutter Frontend

A Flutter application for tracking stocks using real-time data from Zerodha's Kite API.

## Features

- **Real-time Stock Data**: Fetch live stock prices and market data
- **Stock Search**: Search stocks by name or symbol
- **Stock Details**: View detailed information for each stock
- **Watchlist**: Add stocks to your personal watchlist
- **Filtering**: Filter stocks by sector, rating, and performance
- **Modern UI**: Clean and intuitive user interface

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (version 3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Backend server running (see Backend README)

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Backend URL

Update the backend URL in `lib/services/stock_service.dart`:

```dart
static const String baseUrl = 'http://localhost:5000/api';
```

For Android emulator, use:
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

For physical device, use your computer's IP address:
```dart
static const String baseUrl = 'http://192.168.1.100:5000/api';
```

### 4. Run the Application

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point and theme configuration
├── stock_list_page.dart      # Main stock listing page
├── stock_detail_page.dart    # Stock detail view
├── watchlist_page.dart       # Watchlist management
├── services/
│   └── stock_service.dart    # API service for backend communication
└── models/
    └── stock_model.dart      # Stock data model
```

## API Integration

The app communicates with the backend through the following endpoints:

- `GET /api/stocks` - Get all stocks with pagination
- `GET /api/stocks/popular` - Get popular stocks
- `GET /api/stocks/{symbol}` - Get stock details
- `GET /api/quote/{symbol}` - Get real-time quote
- `GET /api/search` - Search stocks
- `GET /api/market_status` - Get market status

## Features in Detail

### Stock List Page
- Displays all available stocks
- Real-time search functionality
- Filter by sector, rating, and performance
- Add/remove stocks from watchlist
- Loading states and error handling

### Stock Detail Page
- Comprehensive stock information
- Price metrics (high, low, open, close)
- Performance indicators
- Real-time price updates
- Historical data visualization (placeholder)

### Watchlist Page
- Personal stock watchlist
- Quick access to favorite stocks
- Empty state handling

## Dependencies

- `http`: For API communication
- `fl_chart`: For chart visualization (future use)
- `flutter`: Core Flutter framework

## Development

### Adding New Features

1. **New API Endpoints**: Add methods to `StockService`
2. **New Models**: Create classes in `models/` directory
3. **New Pages**: Create widgets in the root `lib/` directory
4. **State Management**: Use `setState` for local state (consider Provider/Riverpod for larger apps)

### Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Handle errors gracefully
- Implement loading states

## Troubleshooting

### Common Issues

1. **Connection Error**: Ensure backend server is running
2. **CORS Issues**: Backend has CORS enabled, check URL configuration
3. **API Errors**: Check backend logs for detailed error messages
4. **Build Issues**: Run `flutter clean` and `flutter pub get`

### Debug Mode

Enable debug mode for detailed logging:

```dart
// In stock_service.dart
print('API Response: ${response.body}');
```

## Future Enhancements

- Real-time price updates via WebSocket
- Chart visualization with historical data
- Push notifications for price alerts
- Portfolio tracking
- News integration
- Advanced filtering options
- Dark mode support
- Offline data caching

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is for educational purposes. Please ensure compliance with Zerodha's API terms of service.
