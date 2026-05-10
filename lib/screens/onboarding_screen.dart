import 'package:flutter/material.dart';
import '../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Precision Inventory',
      description: 'Master your stock levels with ultra-precise tracking from pasture to plate.',
      icon: Icons.inventory_2_rounded,
      color: AppColors.primaryMaroon,
      bgAsset: 'assets/images/meat_art.jpg',
    ),
    OnboardingData(
      title: 'Seamless Checkout',
      description: 'Accelerate your workflow with our lightning-fast POS and integrated weighing scales.',
      icon: Icons.point_of_sale_rounded,
      color: const Color(0xFF1B5E20),
      bgAsset: 'assets/images/meat_on_scale.jpg',
    ),
    OnboardingData(
      title: 'Growth Analytics',
      description: 'Transform your sales data into powerful business insights and dominate your market.',
      icon: Icons.auto_graph_rounded,
      color: const Color(0xFF0D47A1),
      bgAsset: 'assets/images/beef_art.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background Image with Blur/Opacity
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Container(
              key: ValueKey(_currentPage),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_pages[_currentPage].bgAsset),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.85),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          
          // Gradient Overlay
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _pages[_currentPage].color.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], index == _currentPage);
            },
          ),

          // Top Skip Button
          Positioned(
            top: 60,
            right: 20,
            child: TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text(
                'SKIP',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Bottom Navigation Section
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: _pages[_currentPage].color.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.l),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        key: ValueKey(_currentPage),
                        children: [
                          Text(
                            _currentPage == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 800),
            scale: isActive ? 1.0 : 0.6,
            curve: Curves.elasticOut,
            child: Container(
              padding: const EdgeInsets.all(45),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                size: 110,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 70),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: isActive ? 1.0 : 0.0,
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isSelected = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 12,
      width: isSelected ? 40 : 12,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isSelected ? _pages[_currentPage].color : Colors.white24,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.white54, width: 2) : null,
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String bgAsset;

  OnboardingData({
    required this.title, 
    required this.description, 
    required this.icon,
    required this.color,
    required this.bgAsset,
  });
}
