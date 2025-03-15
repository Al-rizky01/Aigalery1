// import 'dart:io';
import 'package:aigalery1/main.dart';
import 'package:aigalery1/screens/ShimmerLoadingWidget.dart';
// import 'package:aigalery1/widgets/app_bbn.dart';

// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:introduction_screen/introduction_screen.dart';
// import 'package:aigalery1/services/AuthCheckd.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aigalery1/screens/DetailPage.dart';
// import 'package:aigalery1/screens/UserDetailPage.dart';
// import 'package:aigalery1/screens/uploadImage_page.dart';
// import 'package:aigalery1/screens/AlbumPage.dart';
import 'package:aigalery1/screens/viewUseruploadpage.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'notifications_page.dart';
// import 'package:shimmer/shimmer.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ignore: unused_field
  bool _isIntroductionShown = false;
  String? userIdDariLogin;


  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userIdDariLogin = prefs.getString('userId');
    });
  }

  

  Future<List<Map<String, dynamic>>> getPhotoData() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('upload').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'url': data['url'] ?? '',
        'title': data['title'] ?? 'No Title',
        'description': data['description'] ?? 'No Description',
        'username': data['username'] ?? 'Unknown User',
        'postId': doc.id,
      };
    }).toList();
  }

  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthCheck()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          
       
      
        title: const Text('Home Page'),
        automaticallyImplyLeading: false,
        actions: [
          
          
          
    IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        );
         },
    ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: 
      Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getPhotoData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading photos'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No photos available'));
                }

                final photoData = snapshot.data!;

                return MasonryGridView.builder(
                  gridDelegate:
                      const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12.5),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: photoData.length,
                  itemBuilder: (context, index) {
                    final photo = photoData[index];
                    final postId = photo['postId'] ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              imageUrl: photo['url'] ?? '',
                              title: photo['title'] ?? 'No Title',
                              description:
                                  photo['description'] ?? 'No Description',
                              username: photo['username'] ?? 'Unknown User',
                              postId: postId,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: CachedNetworkImage(
                              imageUrl: photo['url'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => AspectRatio(
                                aspectRatio:
                                    1, // Sesuaikan dengan rasio yang diinginkan
                                child: ShimmerLoadingWidget(
                                  borderRadius: 12.0,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            photo['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
           // Tambahkan efek fade di bawah
        
        ],
      ),
     
    );
  }
}
