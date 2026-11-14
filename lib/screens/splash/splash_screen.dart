import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );

    _animCtrl.forward();

    // Check auth and transition
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              auth.isAuthenticated ? const MainNavigationScreen() : const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Deep premium black
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hotel World Logo on Full Luxury Black Plate
                  Container(
                    width: 280,
                    height: 140,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), // Luxury black plate
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary500.withOpacity(0.7),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary500.withOpacity(0.35),
                          blurRadius: 35,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.9),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary400,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Brand Name in Gold
                  const Text(
                    'HOTEL WORLD',
                    style: TextStyle(
                      color: AppColors.primary400,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  const Text(
                    'COMMERCIAL KITCHEN EQUIPMENTS',
                    style: TextStyle(
                      color: AppColors.slate400,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Subtle Loading Indicator
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

