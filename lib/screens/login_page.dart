import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'MyHomePage.dart';
import 'register_page.dart'; // Tambahkan import ke RegisterPage
import 'buildpage.dart'; // Tambahkan import ke RegisterPage


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> loginUser() async {
  if (!_formKey.currentState!.validate()) return; // Validasi sebelum login

  String userInput = _emailController.text.trim(); // Bisa berupa email atau username
  String password = _passwordController.text;

  try {
    var bytes = utf8.encode(password);
    var hashedPassword = sha256.convert(bytes).toString();

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(Filter.or(
          Filter('email', isEqualTo: userInput),
          Filter('username', isEqualTo: userInput),
        ))
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      var userSnapshot = querySnapshot.docs.first;

      if (userSnapshot.get('password') == hashedPassword) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userSnapshot.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful!")),
        );

        // Navigasi ke MyHomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  BuildPage()),
        );
      } else {
        _showError("Invalid password!");
      }
    } else {
      _showError("User not found!");
    }
  } catch (e) {
    _showError("Error logging in: $e");
  }
}


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white, // Warna latar belakang AppBar
      elevation: 0, // Hilangkan bayangan AppBar
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
         MaterialPageRoute(builder: (context) => const MyHomePage());
        },
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildTextFieldE(_emailController, "Email", Icons.email, false),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Password", Icons.lock, true),
              const SizedBox(height: 20),
              ElevatedButton(
                style: _buttonStyle(),
                onPressed: loginUser,
                child: const Text("Login", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text("Belum punya akun? Register"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your $hint";
        }
        return null;
      },
decoration: InputDecoration(
    labelText: "Password",
    prefixIcon: Icon(Icons.lock, color: Colors.blue),
    filled: true,
    fillColor: Colors.grey[100],
    border: _roundedBorder(),
    enabledBorder: _roundedBorder(),
    focusedBorder: _focusedBorder(),
    floatingLabelBehavior: FloatingLabelBehavior.auto, // Animasi label
  ),
    );
  }

  OutlineInputBorder _roundedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.transparent),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    );
  }

   

Widget _buildTextFieldE(
    TextEditingController controller, String hint, IconData icon, bool isPassword) {
  return TextFormField(
    controller: _emailController,
    decoration: InputDecoration(
      labelText: "Username/Email ",
      prefixIcon: Icon(Icons.person, color: Colors.blue),
      filled: true,
      fillColor: Colors.grey[100],
      border: _roundedBorder(),
      enabledBorder: _roundedBorder(),
      focusedBorder: _focusedBorder(),
      floatingLabelBehavior: FloatingLabelBehavior.auto, // Animasi label
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return "Email atau Username tidak boleh kosong";
      }
      return null;
    },
  );
}


      
}
