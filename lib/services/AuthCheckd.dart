import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_page.dart';  // Pastikan sudah ada file LoginPage
import '../screens/MyHomePage.dart';  // Import halaman MyHomePage

class AuthCheckd extends StatefulWidget {
  const AuthCheckd({super.key});

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheckd> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Fungsi untuk mengecek status login
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');

    setState(() {
      userId = storedUserId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Jika userId ada di SharedPreferences, navigasi ke MyHomePage
    if (userId != null) {
      return const MyHomePage();
    } else {
      // Jika tidak ada userId, navigasi ke LoginPage
      return const LoginPage();
    }
  }
}
