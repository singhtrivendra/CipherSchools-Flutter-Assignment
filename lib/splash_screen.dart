import 'dart:async';
import 'package:cipherx/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cipherx/onboarding.dart';
import 'package:cipherx/login.dart';
import 'package:cipherx/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(Duration(seconds: 2));
    
    // Check if user has opened the app before
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    
    // Check if user is logged in using your existing AuthService implementation
    final bool isLoggedIn = await _authService.isUserLoggedIn();
    
    if (mounted) {
      // Navigate to appropriate screen
      if (isFirstTime) {
        // First time user, show onboarding
        await prefs.setBool('isFirstTime', false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      } else if (isLoggedIn) {
        // User is already authenticated, go to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // User has used the app before but is not logged in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6A5ACD),
      body: Stack(
        children: [
          // Top right concentric ring
          Positioned(
            top: -50,
            right: -50,
            child: _buildConcentricRing(180, 0.2),
          ),
          
          // Bottom left concentric ring
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildConcentricRing(180, 0.2),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogoWidget(80),
                
                SizedBox(height: 20),
                
                // App name
                Text(
                  "CIPHERX",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // By Giant Source line at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "by ",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      "Open Source Community",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Progress indicator
                Container(
                  width: 100,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Custom widget to create the logo
  Widget _buildLogoWidget(double size) {
    return Container(
      width: size,
      height: size,
      child: Center(
        child: CustomPaint(
          size: Size(size, size),
          painter: LogoPainter(),
        ),
      ),
    );
  }
  
  // Helper method to create concentric ring
  Widget _buildConcentricRing(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity * 0.3),
      ),
    );
  }
}

// Custom painter to draw the logo
class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw the swirl pattern (based on the image shown)
    for (int i = 0; i < 4; i++) {
      final startAngle = i * 1.57; // 90 degrees in radians
      final sweepAngle = 1.57 - 0.3; // Slightly less than 90 degrees
      
      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
      );
      path.lineTo(center.dx, center.dy);
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}