import 'package:flutter/material.dart';
import 'package:aigalery1/services/auth_service.dart';
import 'login_page.dart';
import 'MyHomePage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol kembali
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyHomePage()),
                      );
                    },
                  ),

                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Register",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(_usernameController, "Username", Icons.person, false),
                        const SizedBox(height: 15),
                        _buildTextField(_emailController, "Email", Icons.email, false),
                        const SizedBox(height: 15),
                        _buildTextField(_passwordController, "Password", Icons.lock, true),
                        const SizedBox(height: 15),
                        _buildTextField(_confirmPasswordController, "Confirm Password", Icons.lock, true),
                        const SizedBox(height: 20),

                        // Tombol Register
                        ElevatedButton(
                          style: _buttonStyle(),
                          onPressed: _register,
                          child: const Text("Register", style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 15),

                        // Navigasi ke Login
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, "/login");
                          },
                          child: const Text("Sudah punya akun? Login"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi untuk membangun input field
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey[100],
        border: _roundedBorder(),
        enabledBorder: _roundedBorder(),
        focusedBorder: _focusedBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label tidak boleh kosong";
        }
        return null;
      },
    );
  }

  // Fungsi untuk menangani registrasi
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      await _authService.registerUser(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
        context, // Birthdate dihapus dari parameter
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Registrasi berhasil!"),
        backgroundColor: Colors.green,
      ));
    }
  }

  // Gaya tombol Register
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    );
  }

  // Border input field dengan radius melingkar
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
}
