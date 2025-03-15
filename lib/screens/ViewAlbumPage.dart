import 'package:aigalery1/screens/DetailPage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewAlbumPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const ViewAlbumPage({
    Key? key,
    required this.albumId,
    required this.albumName,
  }) : super(key: key);

  @override
  _ViewAlbumPageState createState() => _ViewAlbumPageState();
}

class _ViewAlbumPageState extends State<ViewAlbumPage> {
  List<Map<String, dynamic>> albumPhotos = [];
  final Set<String> selectedPhotos = {}; // Set untuk menyimpan ID foto yang dipilih

  @override
  void initState() {
    super.initState();
    _loadAlbumPhotos();
  }

  Future<void> _loadAlbumPhotos() async {
    final photos = await _getAlbumPhotos();
    setState(() {
      albumPhotos = photos;
    });
  }

  Future<List<Map<String, dynamic>>> _getAlbumPhotos() async {
    final albumDoc = await FirebaseFirestore.instance
        .collection('albums')
        .doc(widget.albumId)
        .get();

    List<String> photoIds = List<String>.from(albumDoc.data()?['photos'] ?? []);
    if (photoIds.isEmpty) return [];

    List<Map<String, dynamic>> photosData = [];
    for (String photoId in photoIds) {
      try {
        final photoDoc = await FirebaseFirestore.instance
            .collection('upload')
            .doc(photoId)
            .get();
        if (photoDoc.exists) {
          final data = photoDoc.data() as Map<String, dynamic>;
          data['postId'] = photoDoc.id;
          photosData.add(data);
        }
      } catch (e) {
        print('Error fetching photo $photoId: $e');
      }
    }
    return photosData;
  }

  Future<List<Map<String, dynamic>>> _getUserPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    final querySnapshot = await FirebaseFirestore.instance
        .collection('upload')
        .where('userIdUploadters', isEqualTo: userId)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _addPhotosToAlbum(Set<String> selectedPhotos) async {
    final albumDoc = FirebaseFirestore.instance.collection('albums').doc(widget.albumId);
    final albumData = await albumDoc.get();

    List<String> existingPhotos = List<String>.from(albumData.data()?['photos'] ?? []);
    existingPhotos.addAll(selectedPhotos);

    await albumDoc.update({'photos': existingPhotos});
    _loadAlbumPhotos();
  }

  void _showPhotoSelector(BuildContext context) async {
  final photos = await _getUserPhotos(); // Mengambil foto pengguna di awal

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Photos to Add',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () async {
                        await _addPhotosToAlbum(selectedPhotos);  // Menyimpan foto yang dipilih
                        Navigator.pop(context);  // Menutup modal
                        setState(() {});  // Refresh halaman
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final isSelected = selectedPhotos.contains(photo['id']);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedPhotos.remove(photo['id']);
                          } else {
                            selectedPhotos.add(photo['id']);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(photo['url']),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(Icons.check_circle, color: Colors.green),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () => _showPhotoSelector(context),
          ),
        ],
      ),
      body: albumPhotos.isEmpty
          ? const Center(child: Text(''))
          : MasonryGridView.builder(
              gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.5),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              itemCount: albumPhotos.length,
              itemBuilder: (context, index) {
                final photo = albumPhotos[index];
                final postId = photo['postId'] ?? '';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(
                          imageUrl: photo['url'] ?? '',
                          title: photo['title'] ?? 'No Title',
                          description: photo['description'] ?? 'No Description',
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
                            aspectRatio: 1,
                            child: Container(color: Colors.grey[300]),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photo['title'] ?? 'No Title',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
