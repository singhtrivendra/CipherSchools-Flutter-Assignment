import 'package:cipherx/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6A5ACD),
      body: Stack(
        children: [
          // Top right concentric rings
          Positioned(
            top: -50,
            right: -50,
            child: _buildConcentricRings(180, 0.3),
          ),
          
          // Bottom left concentric rings
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildConcentricRings(180, 0.2),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Logo at top left
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    // Replace Image.asset with a custom logo widget
                    child: Image.asset(
                      'assets/Logo.jpg', // Replace with your logo path
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                
                Spacer(),
                
                // Welcome text and arrow in same row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Welcome text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome to",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "CipherX.",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 30),
                            Text(
                              "The best way to track your expenses.",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 28,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to create concentric rings
  Widget _buildConcentricRings(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity * 0.3),
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(opacity * 0.5),
          ),
        ),
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
    
    // Draw small circle in center
    canvas.drawCircle(center, radius * 0.15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}