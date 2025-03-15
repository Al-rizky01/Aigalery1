// File: build_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aigalery1/screens/MyHomePage.dart';
import 'package:aigalery1/screens/UserDetailPage.dart';
import 'package:aigalery1/screens/AlbumPage.dart';
import 'package:aigalery1/screens/uploadImage_page.dart';
import 'package:aigalery1/widgets/app_bottom_navigation.dart'; // Pastikan path ini benar

class BuildPage extends StatefulWidget {
  @override
  _BuildPageState createState() => _BuildPageState();
}

class _BuildPageState extends State<BuildPage> {
  int _currentIndex = 0; // Mulai dari Home (indeks 0)
  String? userIdDariLogin;
  bool isLoading = true;
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _getUserId();
    _pageController = PageController(initialPage: _currentIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userIdDariLogin = prefs.getString('userId');
      isLoading = false;
    });
  }

  void _onTabChange(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> _pages = [
      MyHomePage(), // Home (Indeks 0)
      UploadImagePage(userIdUploadters: userIdDariLogin!), // Upload (Indeks 1)
      AlbumsPage(userId: userIdDariLogin!), // Albums (Indeks 2)
      UserDetailPage(userId: userIdDariLogin!), // Profile (Indeks 3)
    ];

    return Scaffold(
     body: PageView(
  controller: _pageController,
  children: _pages,
  onPageChanged: (index) {
    setState(() {
      _currentIndex = index;
    });
  },
  physics: const BouncingScrollPhysics(), // Aktifkan swipe dengan efek elastis
),

      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTabChange: _onTabChange,
      ),
    );
  }
}