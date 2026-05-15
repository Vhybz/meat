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
    final size = MediaQuery.of(context).size;
    final bool isSmall = size.height < 700;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background Image
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
          
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildPage(_pages[index], index == _currentPage, isSmall),
          ),

          // Top Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('SKIP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ),

          // Bottom Navigation Section
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 30,
            right: 30,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) => _buildDot(index)),
                ),
                SizedBox(height: isSmall ? 24 : 50),
                Center(
                  child: SizedBox(
                    width: size.width > 460 ? 400 : double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.pushReplacementNamed(context, '/login');
                        } else {
                          _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_currentPage == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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

  Widget _buildPage(OnboardingData data, bool isActive, bool isSmall) {
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
              padding: EdgeInsets.all(isSmall ? 30 : 45),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Icon(data.icon, size: isSmall ? 70 : 110, color: Colors.white),
            ),
          ),
          SizedBox(height: isSmall ? 30 : 70),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: isActive ? 1.0 : 0.0,
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 28 : 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 15 : 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
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
