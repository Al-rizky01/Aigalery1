import 'package:aigalery1/screens/buildpage.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart'; // Import untuk introduction screen
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'screens/register_page.dart';
import 'screens/login_page.dart';
import 'screens/MyHomePage.dart';  // MyHomePage yang baru
import 'glowing_button.dart';
import 'firebase_options.dart'; 



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tambahkan ini untuk menghilangkan tulisan DEBUG
      title: 'Flutter Firestore Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? const MyHomePage() : const AuthCheck(), // Navigasi sesuai status login
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}



// Mengecek apakah user sudah login
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;  // Cek apakah userId sudah tersimpan
  }

  @override
Widget build(BuildContext context) {
  return FutureBuilder<bool>(
    future: isLoggedIn(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, // Tambahkan ini
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      } else if (snapshot.data == true) {
        return BuildPage();  // Jika sudah login langsung ke MyHomePage
      } else {
        return Welcome();  // Jika belum login, tampilkan IntroductionScreen
      }
    },
  );
}

}

// IntroductionScreen yang pertama ditampilkan
class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to AI Gallery",
          body: "This is the first introduction screen.",
          image: Image.asset('assets/intro1.png'),  // Gambar untuk halaman pertama
        ),
        PageViewModel(
          title: "Explore Features",
          body: "Discover the best features in our app.",
          image: Image.asset('assets/intro2.png'),  // Gambar untuk halaman kedua
        ),
        PageViewModel(
          title: "Get Started",
          body: "Let's start using the app!",
          image: Image.asset('assets/intro3.png'),  // Gambar untuk halaman ketiga
        ),
      ],
      onDone: () {
        // Ketika user selesai, navigasikan ke halaman MyHomePage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyHomePage())
        );
      },
      onSkip: () {
        // Jika user skip, navigasikan juga ke halaman MyHomePage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyHomePage())
        );
      },
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// MyHomePage setelah IntroductionScreen
class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg-homepage.png"),  // Background dari assets
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Menyebar elemen secara vertikal
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 135.0),  // Jarak dari atas layar
                child: Text(
                  "Welcome",  // Teks "Welcome" di bagian atas
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,  // Warna teks putih
                  ),
                ),
              ),
              Column(
                children: [
                  GlowingButton(
                    color1: Colors.cyan,
                    color2: Colors.greenAccent,
                    text: "Create Your Account",  // Teks untuk tombol Register
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),  // Jarak antar tombol
                  GlowingButton(
                    color1: Colors.purple,
                    color2: Colors.pinkAccent,
                    text: "Login In Your Account",  // Teks untuk tombol Login
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 1.0),  // Jarak dari bawah layar
                child: Image.asset(
                  'assets/AlGALERY-removebg-preview.png',  // Logo di bagian bawah
                  height: 250,  // Atur tinggi logo
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
