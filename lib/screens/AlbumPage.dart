import 'package:aigalery1/screens/ViewAlbumPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumsPage extends StatefulWidget {
  final String userId;

  const AlbumsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _albumNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _albumNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddAlbumDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Album',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _albumNameController,
                decoration: const InputDecoration(
                  labelText: 'Album Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _createAlbum(context),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Album'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createAlbum(BuildContext context) async {
    String albumName = _albumNameController.text.trim();
    String description = _descriptionController.text.trim();

    if (albumName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('albums').add({
        'albumName': albumName,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': widget.userId,
        // Menambahkan field searchKeywords untuk memudahkan pencarian
        'searchKeywords': _generateSearchKeywords(albumName),
      });

      _albumNameController.clear();
      _descriptionController.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Album created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create album: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk menghasilkan keywords pencarian
  List<String> _generateSearchKeywords(String albumName) {
    List<String> keywords = [];
    String word = '';
    albumName = albumName.toLowerCase();

    for (int i = 0; i < albumName.length; i++) {
      word = word + albumName[i];
      keywords.add(word);
    }
    return keywords;
  }

  Stream<QuerySnapshot> _getAlbumsStream() {
    if (_searchQuery.isEmpty) {
      // Query default tanpa pencarian
      return FirebaseFirestore.instance
          .collection('albums')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    // Query dengan pencarian
    return FirebaseFirestore.instance
        .collection('albums')
        .where('userId', isEqualTo: widget.userId)
        .where('searchKeywords', arrayContains: _searchQuery.toLowerCase())
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAlbumDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search albums...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAlbumsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No albums found'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
  final album = snapshot.data!.docs[index];
  final albumData = album.data() as Map<String, dynamic>;

  // Ambil hingga 3 foto terbaru untuk album ini
  Future<List<String>> _getRecentPhotos() async {
    final albumDoc = await FirebaseFirestore.instance
        .collection('albums')
        .doc(album.id)
        .get();
    final List<String> photoIds = List<String>.from(albumDoc.data()?['photos'] ?? []);
    
    // Ambil hingga 3 foto terbaru
    final recentPhotos = photoIds.take(3).toList();

    List<String> photoUrls = [];
    for (var photoId in recentPhotos) {
      final photoDoc = await FirebaseFirestore.instance.collection('upload').doc(photoId).get();
      if (photoDoc.exists) {
        final photoData = photoDoc.data() as Map<String, dynamic>;
        photoUrls.add(photoData['url']);
      }
    }
    return photoUrls;
  }

  return FutureBuilder<List<String>>(
    future: _getRecentPhotos(),
    builder: (context, snapshot) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAlbumPage(
                  albumId: album.id,
                  albumName: albumData['albumName'] ?? 'Untitled Album',
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey[300],
                  ),
                  child: snapshot.hasData && snapshot.data!.isNotEmpty
    ? Row(
        children: snapshot.data!.asMap().entries.map((entry) {
          int index = entry.key;
          String url = entry.value;

          BorderRadius borderRadius;
          if (index == 0) {
            // Border untuk gambar paling kiri
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            );
          } else if (index == 2) {
            // Border untuk gambar paling kanan
            borderRadius = const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            );
          } else {
            // Tidak ada border untuk gambar tengah
            borderRadius = BorderRadius.zero;
          }

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.cover,
                ),
                borderRadius: borderRadius,
              ),
            ),
          );
        }).toList(),
      )
    : const Icon(
        Icons.photo_album,
        size: 50,
        color: Colors.white,
      ),

                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  albumData['albumName'] ?? 'Untitled Album',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
},

                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
