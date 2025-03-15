import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectPhotosPage extends StatefulWidget {
  final String albumId;

  const SelectPhotosPage({
    Key? key,
    required this.albumId,
  }) : super(key: key);

  @override
  _SelectPhotosPageState createState() => _SelectPhotosPageState();
}

class _SelectPhotosPageState extends State<SelectPhotosPage> {
  String? userId;
  List<Map<String, dynamic>> userPhotos = [];
  List<String> selectedPhotoIds = [];

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

Future<void> _getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  print('User ID dari SharedPreferences: $userId');  // Debugging User ID
  if (userId != null) {
    await _fetchUserPhotos(userId);  // Panggil fungsi dengan userId
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User ID tidak ditemukan')),
    );
  }
}



Future<void> _fetchUserPhotos(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('upload')
        .where('userIdUploadters', isEqualTo: userId) // Sesuaikan nama field
        .get();

    print('Jumlah foto yang diambil: ${snapshot.docs.length}');
    if (snapshot.docs.isEmpty) {
      print('Tidak ada foto yang ditemukan!');
    }

    setState(() {
      userPhotos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Data foto: $data');
        return {
          'url': data['url'] ?? '',
          'title': data['title'] ?? 'No Title',
          'postId': doc.id,
        };
      }).toList();
    });
  } catch (e) {
    print('Error fetching user photos: $e');
  }
}




  void _toggleSelection(String postId) {
    setState(() {
      if (selectedPhotoIds.contains(postId)) {
        selectedPhotoIds.remove(postId);
      } else {
        selectedPhotoIds.add(postId);
      }
    });
  }

  Future<void> _addSelectedPhotosToAlbum() async {
    if (selectedPhotoIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu foto')),
      );
      return;
    }

    final albumRef = FirebaseFirestore.instance.collection('albums').doc(widget.albumId);

    await albumRef.update({
      'photos': FieldValue.arrayUnion(selectedPhotoIds),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto berhasil ditambahkan ke album')),
    );
    Navigator.pop(context);
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Select Photos'),
      actions: [
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _addSelectedPhotosToAlbum,
        ),
      ],
    ),
    body: userPhotos.isEmpty
        ? const Center(child: Text('Tidak ada foto untuk dipilih'))
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: userPhotos.length,
            itemBuilder: (context, index) {
              final photo = userPhotos[index];
              final postId = photo['postId'];
              final isSelected = selectedPhotoIds.contains(postId);

              return GestureDetector(
                onTap: () => _toggleSelection(postId),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: photo['url'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 12,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleSelection(postId),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}
}