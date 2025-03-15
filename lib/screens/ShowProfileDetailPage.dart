import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShowProfileDetail extends StatefulWidget {
  const ShowProfileDetail({
    Key? key,
    required this.userId,
  }) : super(key: key);

  final String userId;

  @override
  _ShowProfileDetailState createState() => _ShowProfileDetailState();
}

class _ShowProfileDetailState extends State<ShowProfileDetail> {
  String error = '';
  bool isLoading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        setState(() {
          error = 'User not found';
          isLoading = false;
        });
        return;
      }

      setState(() {
        userData = userDoc.data();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading user data: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Detail'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : userData != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Picture
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: userData!['profilePicture'] != null
                                ? NetworkImage(userData!['profilePicture'])
                                : null,
                            child: userData!['profilePicture'] == null
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          const SizedBox(height: 20),
                          
                          // Username
                          Text(
                            userData!['username'] ?? 'No username',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Email
                          if (userData!['email'] != null)
                            Text(
                             'Email: ${userData!['email'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Bio or Description
                          if (userData!['bio'] != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                userData!['bio'],
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Add more user information fields as needed
                        ],
                      ),
                    )
                  : const Center(child: Text('No user data available')),
    );
  }
}