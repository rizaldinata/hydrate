import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/registration/registration1_view.dart';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasReachedLastPage = false;
  Timer? _timer;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/splash/slide1.svg',
      'title': 'Hidrasi Harian',
      'subtitle': 'Disesuaikan dengan Keadaanmu',
      'description':
          'Target minum air disesuaikan dengan berat badanmu secara otomatis.',
    },
    {
      'image': 'assets/images/splash/slide2.svg',
      'title': 'Pantau Asupan Air',
      'subtitle': 'dengan Lebih Mudah',
      'description':
          'Aplikasi membantu mengingatkan kamu untuk minum secara rutin setiap hari.',
    },
    {
      'image': 'assets/images/splash/slide3.svg',
      'title': 'Lacak Progres Kamu',
      'subtitle': 'dalam Mencapai Target',
      'description':
          'Visualisasi grafik akan memudahkan kamu untuk melihat progres hidrasi harianmu.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _pages.length - 1) {
        // Slide ke kanan (halaman berikutnya)
        _currentPage++;
      } else {
        // Kembali ke slide pertama setelah mencapai slide terakhir
        _currentPage = 0;
      }
      
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      if (index == _pages.length - 1) {
        _hasReachedLastPage = true;
      }
    });
  }

// Membuat indikator halaman yang berubah ukuran
  Widget _buildIndicator(bool isActive) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? screenWidth * 0.3 : screenWidth * 0.1,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00A4C7) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        page['image']!,
                        height: size.height * 0.4,
                      ),
                      const SizedBox(height: 32),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.fredoka(
                              fontSize: 24,
                              color: Color(0xFF1D1B20),
                              fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                                text: "${page['title']} ",
                                style: const TextStyle(
                                  color: Color(0xFF00A6FB),
                                )),
                            TextSpan(text: page['subtitle']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page['description']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildIndicator(index == _currentPage),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _hasReachedLastPage
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(
                                builder: (context) => RegistrationData(),
                              ),);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADFFF),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Selanjutnya',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    height: 50,
                    width: double.infinity,
                    child: Text(
                      'Geser untuk melanjutkan',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: size.height * 0.08),
        ],
      ),
    );
  }
}