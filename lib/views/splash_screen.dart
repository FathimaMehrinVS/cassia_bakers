import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import 'auth_screen.dart';
import '../main.dart'; // To get access to MainNavigationFrame

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final state = Provider.of<AppState>(context, listen: false);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => state.isAuthenticated
            ? const MainNavigationFrame()
            : const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryMaroon,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Beautiful Custom Brand Logo
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryGold.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo/logo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Tagline
              const Text(
                '“Manage your bakery business smartly”',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
              const Spacer(flex: 2),
              // Custom styled progress bar
              const SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryGold),
                  minHeight: 3,
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// CUSTOM VECTOR CAKE PAINTER FOR LOGO (High Fidelity visual)
// =========================================================================
class CakeLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paint brushes
    final Paint goldPaint = Paint()..color = AppColors.secondaryGold;
    final Paint whitePaint = Paint()..color = Colors.white;
    final Paint maroonPaint = Paint()..color = AppColors.primaryMaroon;

    // 1. Draw elegant gold chef hat/crown at the top
    final Path crownPath = Path();
    crownPath.moveTo(w * 0.35, h * 0.2);
    crownPath.quadraticBezierTo(w * 0.35, h * 0.05, w * 0.42, h * 0.1);
    crownPath.quadraticBezierTo(w * 0.5, h * 0.02, w * 0.58, h * 0.1);
    crownPath.quadraticBezierTo(w * 0.65, h * 0.05, w * 0.65, h * 0.2);
    crownPath.lineTo(w * 0.35, h * 0.2);
    canvas.drawPath(crownPath, goldPaint);

    // 2. Draw cake stand base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.2, h * 0.82, w * 0.8, h * 0.88),
        const Radius.circular(4),
      ),
      goldPaint,
    );
    // Draw stand neck
    final Path neckPath = Path();
    neckPath.moveTo(w * 0.45, h * 0.82);
    neckPath.lineTo(w * 0.55, h * 0.82);
    neckPath.lineTo(w * 0.6, h * 0.95);
    neckPath.lineTo(w * 0.4, h * 0.95);
    neckPath.close();
    canvas.drawPath(neckPath, goldPaint);

    // 3. Draw bottom layer of Chocolate Cake
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.22, h * 0.55, w * 0.78, h * 0.82),
        const Radius.circular(8),
      ),
      whitePaint,
    );

    // Draw chocolate icing drips/layers on bottom layer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.22, h * 0.55, w * 0.78, h * 0.65),
        const Radius.circular(8),
      ),
      goldPaint,
    );

    // 4. Draw top layer of Cake
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.3, h * 0.3, w * 0.7, h * 0.55),
        const Radius.circular(6),
      ),
      goldPaint,
    );

    // Draw cream detail on top layer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.3, h * 0.3, w * 0.7, h * 0.38),
        const Radius.circular(6),
      ),
      whitePaint,
    );

    // 5. Draw 3 sweet gold candles or cherries on top
    canvas.drawCircle(Offset(w * 0.4, h * 0.26), 4, goldPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.24), 4, goldPaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.26), 4, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
