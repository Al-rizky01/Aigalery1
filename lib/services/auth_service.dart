import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';


class AuthService {
  Future<void> registerUser(String email, String password, String username, BuildContext context) async {
    try {
      var uuid = const Uuid(); // Membuat UUID
      var userId = uuid.v4(); // Generate User ID acak

      var bytes = utf8.encode(password);
      var hashedPassword = sha256.convert(bytes);

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'userId': userId, // Simpan userId
        'email': email,
        'password': hashedPassword.toString(),
        'username': username,
        
      });

      print("User registered successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User registered successfully!")),
      );

      // Redirect to login page after successful registration
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("Error registering user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error registering user: $e")),
      );
    }
  }
}
