import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/product_provider.dart';
import 'providers/quotation_provider.dart';
import 'providers/customer_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (dark status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage
  await StorageService.init();

  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ProductProvider(apiService)),
        ChangeNotifierProvider(create: (_) => QuotationProvider(apiService)),
        ChangeNotifierProvider(create: (_) => CustomerProvider(apiService)),
      ],
      child: const HotelWorldApp(),
    ),
  );
}

class HotelWorldApp extends StatelessWidget {
  const HotelWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel World',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
