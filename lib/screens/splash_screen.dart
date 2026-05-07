import 'package:flutter/material.dart';
import '../core/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller, 
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _navigateToNext();
  }

  void _navigateToNext() async {
    await _controller.forward();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryMaroon,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryMaroon,
              Color(0xFF4A0808),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background elements
            _buildDecor(top: -100, left: -100, size: 300),
            _buildDecor(bottom: -50, right: -50, size: 200),
            
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main App Icon
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 8),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // App Name
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'Mi CORAZON',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          Text(
                            'FRESHMEAT BUTCHERY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Uncompromising Quality, Unforgettable Taste',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 80),
                    
                    // Progress Indicator
                    SizedBox(
                      width: 240,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecor({double? top, double? left, double? right, double? bottom, required double size}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.03),
        ),
      ),
    );
  }
}

