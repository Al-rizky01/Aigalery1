import 'dart:io';

// import 'package:aigalery1/screens/ShimmerLoadingWidget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aigalery1/screens/ShowProfileDetailPage.dart';
import 'package:shimmer/shimmer.dart';

import 'package:permission_handler/permission_handler.dart';
// import 'package:http/http.dart';
import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.username,
    required this.postId,
  }) : super(key: key);

  final String description;
  final String imageUrl;
  final String postId;
  final String title;
  final String username;

  @override
  _DetailPageState createState() => _DetailPageState();
}

final TextEditingController commentController = TextEditingController();

bool showNotification = false;
String notificationMessage = '';
// Tambahkan di bagian state class
bool isLoadingAlbums = true;
Map<String, String> albumThumbnails = {};

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  String currentUserId = "user123";
  String currentUserProfileUrl = "";

  bool isLiked = false;
  int likeCount = 0;
  String uploadedByProfileUrl = "";
  String uploadedByUserId = "";
  String uploadedByUsername = "";

  List<Map<String, dynamic>> comments = [];
  String commentText = '';
  int commentCount = 0;

  Stream<QuerySnapshot>? albumsStream;
  bool isInitialLoading = true;

  late AnimationController _animationController;
  // ignore: unused_field
  late Animation<Offset> _animationOffset;

// Tambahkan fungsi untuk mengambil userId dari SharedPreferences
  Future<void> _getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId') ??
          "unknownUser"; // Set nilai default jika tidak ditemukan
    });
  }



  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _getLikeStatus();
    _getUserData();
    _getComments();
    _reloadComments();
    _checkSaveStatus();
    _initAlbumsStream();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animationOffset = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0))
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void showAnimatedOverlayNotification(BuildContext context, String message) {
    OverlayEntry overlayEntry;
    bool isVisible = true;

    overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AnimatedPositioned(
            top: isVisible
                ? 50
                : -120, // Turunkan notifikasi agar muncul lebih terlihat
            left: 20,
            right: 20,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOut,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12), // Tambahkan padding untuk memperbesar
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(121, 251, 251, 251).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18, // Tingkatkan ukuran font
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 22, 19, 19),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Tampilkan notifikasi sementara
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isVisible = false;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        overlayEntry.remove();
      });
    });
  }

// Tambahkan di bagian atas class _DetailPageState
  List<Map<String, dynamic>> userAlbums = [];

// Fungsi untuk mengambil daftar album user
  void _initAlbumsStream() {
    albumsStream = FirebaseFirestore.instance
        .collection('albums')
        .where('userId', isEqualTo: currentUserId)
        .snapshots();
  }

// Fungsi untuk menampilkan bottom sheet pemilihan album
  void _showAlbumSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Album',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Album List dengan StreamBuilder
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: albumsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        isInitialLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_album_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Create your first album',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Set isInitialLoading to false after first load
                    if (isInitialLoading) {
                      Future.microtask(
                          () => setState(() => isInitialLoading = false));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final albumData = doc.data() as Map<String, dynamic>;
                        final List<dynamic> photos = albumData['photos'] ?? [];
                        final String albumName =
                            albumData['albumName'] ?? 'Untitled Album';
                        final bool isPhotoInAlbum =
                            photos.contains(widget.postId);

                        // Get thumbnail from the last photo
                        String thumbnailUrl = '';
                        if (photos.isNotEmpty) {
                          // We'll fetch the thumbnail URL in a separate FutureBuilder
                          final lastPhotoId = photos.last;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('upload')
                                .doc(lastPhotoId)
                                .get(),
                            builder: (context, photoSnapshot) {
                              if (photoSnapshot.hasData &&
                                  photoSnapshot.data!.exists) {
                                thumbnailUrl = (photoSnapshot.data!.data()
                                        as Map<String, dynamic>)['imageUrl'] ??
                                    '';
                              }

                              return ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    image: thumbnailUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(thumbnailUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: thumbnailUrl.isEmpty
                                      ? const Icon(
                                          Icons.photo_album,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                title: Text(albumName),
                                subtitle: Text('${photos.length} photos'),
                                trailing: isPhotoInAlbum
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : const Icon(Icons.add_circle_outline),
                                onTap: () async {
                                  if (isPhotoInAlbum) {
                                    // Hapus foto dari album
                                    await FirebaseFirestore.instance
                                        .collection('albums')
                                        .doc(doc.id)
                                        .update({
                                      'photos': FieldValue.arrayRemove(
                                          [widget.postId]),
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Photo removed from "$albumName"')),
                                    );
                                  } else {
                                    // Tambahkan foto ke album
                                    await FirebaseFirestore.instance
                                        .collection('albums')
                                        .doc(doc.id)
                                        .update({
                                      'photos': FieldValue.arrayUnion(
                                          [widget.postId]),
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Photo added to "$albumName"')),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }

                        // Return default ListTile for empty albums
                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.photo_album,
                              color: Colors.grey,
                            ),
                          ),
                          title: Text(albumName),
                          subtitle: Text('${photos.length} photos'),
                          trailing: isPhotoInAlbum
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.add_circle_outline),
                          onTap: () => _savePhotoToAlbum(doc.id, albumName),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Fungsi untuk membuat album baru
  Future<void> _createNewAlbum(String albumName) async {
    try {
      await FirebaseFirestore.instance.collection('albums').add({
        'userId': currentUserId,
        'albumsName': albumName, // Updated field name
        'photos': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      showAnimatedOverlayNotification(context, "Album created successfully!");
    } catch (e) {
      print("Error creating album: $e");
      showAnimatedOverlayNotification(context, "Failed to create album");
    }
  }

// Update fungsi savePhotoToAlbum
  Future<void> _savePhotoToAlbum(String albumId, String albumName) async {
    try {
      final albumRef =
          FirebaseFirestore.instance.collection('albums').doc(albumId);

      await albumRef.update({
        'photos': FieldValue.arrayUnion([widget.postId])
      });

      Navigator.pop(context);
      showAnimatedOverlayNotification(context, "Saved to $albumName");
    } catch (e) {
      print("Error saving to album: $e");
      showAnimatedOverlayNotification(context, "Failed to save to album");
    }
  }

// Tambahkan variable state
  bool isSavedToAlbum = false;

// Tambahkan fungsi check status save
  Future<void> _checkSaveStatus() async {
    try {
      DocumentSnapshot albumSnapshot = await FirebaseFirestore.instance
          .collection('albums')
          .doc(currentUserId)
          .get();

      if (albumSnapshot.exists) {
        List<dynamic> photos = albumSnapshot['photos'] ?? [];
        setState(() {
          isSavedToAlbum = photos.contains(widget.postId);
        });
      }
    } catch (e) {
      print("Error checking save status: $e");
    }
  }

// Fungsi untuk toggle save ke album
  Future<void> _toggleSaveToAlbum() async {
    try {
      final albumRef =
          FirebaseFirestore.instance.collection('albums').doc(currentUserId);

      DocumentSnapshot albumDoc = await albumRef.get();

      if (!albumDoc.exists) {
        // Buat dokumen album baru jika belum ada
        await albumRef.set({
          'photos': [widget.postId]
        });
        setState(() {
          isSavedToAlbum = true;
        });
      } else {
        // Update array photos
        if (isSavedToAlbum) {
          await albumRef.update({
            'photos': FieldValue.arrayRemove([widget.postId])
          });
        } else {
          await albumRef.update({
            'photos': FieldValue.arrayUnion([widget.postId])
          });
        }
        setState(() {
          isSavedToAlbum = !isSavedToAlbum;
        });
      }

      showAnimatedOverlayNotification(
          context, isSavedToAlbum ? "Saved to album" : "Removed from album");
    } catch (e) {
      print("Error toggling save: $e");
      showAnimatedOverlayNotification(context, "Failed to save to album");
    }
  }

  void _showCommentWidget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.7,
        builder: (_, controller) {
          // Fixed: Remove the redundant scrollController declaration
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.0),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Comments ($commentCount)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('upload')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Error loading comments'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No comments yet'));
                        }

                        comments = snapshot.data!.docs
                            .map((doc) => doc.data() as Map<String, dynamic>)
                            .toList();
                        commentCount = comments.length;

                        return ListView.builder(
                          controller:
                              controller, // Fixed: Use the provided controller
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final String userId = comment['userId'];
                            final int likes = comment['likes'] ?? 0;
                            final bool isLikedByUser =
                                comment['likedBy']?.contains(currentUserId) ??
                                    false;
                            final timestamp =
                                (comment['timestamp'] as Timestamp).toDate();
                            final formattedDate =
                                DateFormat('dd-MM-yy hh:mm').format(timestamp);

                            // Fixed: Cache user info to avoid repeated loading
                            return FutureBuilder<Map<String, dynamic>>(
                              future: _getUserInfo(userId),
                              // Fixed: Add a key to help Flutter identify this widget
                              key: ValueKey('comment_$index'),
                              // Fixed: Add a cacheBuilder to avoid rebuilding unnecessarily
                              builder: (context, snapshot) {
                                // Show a simplified placeholder while loading
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Color.fromARGB(
                                              255, 224, 224, 224),
                                          child: Icon(Icons.person),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Loading...'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (snapshot.hasError ||
                                    !snapshot.hasData ||
                                    snapshot.data == null) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey[300],
                                      child: const Icon(Icons.person),
                                    ),
                                    title: Text(comment['text'] ?? ''),
                                    subtitle: const Text('Unknown user'),
                                  );
                                }

                                final userInfo = snapshot.data!;
                                final String username =
                                    userInfo['username'] ?? 'Unknown user';
                                final String? profilePicture =
                                    userInfo['profilePicture'];

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: profilePicture != null
                                        ? NetworkImage(profilePicture)
                                        : null,
                                    backgroundColor: Colors.grey[300],
                                    child: profilePicture == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        comment['text'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.thumb_up,
                                              color: isLikedByUser
                                                  ? Colors.blue
                                                  : Colors.grey,
                                              size: 18,
                                            ),
                                            onPressed: () => _toggleCommentLike(
                                                comment, index),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('$likes'),
                                          // Fixed: Add a more efficient way to get reply counts
                                          FutureBuilder<int>(
                                            future: _getReplyCount(
                                                comment['commentId']),
                                            // Fixed: Add a key to prevent rebuilding
                                            key: ValueKey(
                                                'reply_count_${comment['commentId']}'),
                                            builder: (context, snapshot) {
                                              int replyCount =
                                                  snapshot.data ?? 0;
                                              return Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.reply,
                                                      size: 18,
                                                    ),
                                                    onPressed: () {
                                                      _showReplyWidget(comment);
                                                    },
                                                  ),
                                                  Text('$replyCount'),
                                                ],
                                              );
                                            },
                                          ),
                                          if (userId == currentUserId)
                                            PopupMenuButton(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                size: 18,
                                              ),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editComment(
                                                      context, comment, index);
                                                } else if (value == 'delete') {
                                                  _deleteComment(index);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCommentInput(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// Add this method to your class to cache user info
  Map<String, Future<Map<String, dynamic>>> _userInfoCache = {};

  Future<Map<String, dynamic>> _getUserInfo(String userId) {
    if (!_userInfoCache.containsKey(userId)) {
      _userInfoCache[userId] = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .then((doc) {
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        } else {
          return {'username': 'Unknown user'};
        }
      });
    }
    return _userInfoCache[userId]!;
  }

// Add this method to efficiently get reply counts
  Map<String, Future<int>> _replyCountCache = {};

  Future<int> _getReplyCount(String commentId) {
    if (!_replyCountCache.containsKey(commentId)) {
      _replyCountCache[commentId] = FirebaseFirestore.instance
          .collection('upload')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .get()
          .then((snapshot) => snapshot.docs.length);
    }
    return _replyCountCache[commentId]!;
  }

  void _showReplyWidget(Map<String, dynamic> comment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final scrollController = ScrollController();
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16.0),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Reply to comment',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Original comment display
                FutureBuilder<Map<String, dynamic>>(
                  future: _getUserInfo(comment['userId']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final userInfo = snapshot.data!;
                    final String username =
                        userInfo['username'] ?? 'Unknown user';
                    final String? profilePicture = userInfo['profilePicture'];
                    final timestamp =
                        (comment['timestamp'] as Timestamp).toDate();
                    final formattedDate =
                        DateFormat('dd-MM-yy hh:mm').format(timestamp);

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePicture != null
                              ? NetworkImage(profilePicture)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child: profilePicture == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          comment['text'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('upload')
                        .doc(widget.postId)
                        .collection('comments')
                        .doc(comment['commentId'])
                        .collection('replies')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading replies'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No replies yet'));
                      }

                      List<Map<String, dynamic>> replies = snapshot.data!.docs
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: replies.length,
                        itemBuilder: (context, index) {
                          final reply = replies[index];
                          final String userId = reply['userId'];
                          // ignore: unused_local_variable
                          final int likes = reply['likes'] ?? 0;
                          // ignore: unused_local_variable
                          final bool isLikedByUser =
                              reply['likedBy']?.contains(currentUserId) ??
                                  false;
                          final timestamp =
                              (reply['timestamp'] as Timestamp).toDate();
                          final formattedDate =
                              DateFormat('dd-MM-yy hh:mm').format(timestamp);

                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getUserInfo(userId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 224, 224, 224),
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text('Loading...'),
                                );
                              }

                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data == null) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(Icons.person),
                                  ),
                                  title: Text(reply['text'] ?? ''),
                                  subtitle: const Text('Unknown user'),
                                );
                              }

                              final userInfo = snapshot.data!;
                              final String username =
                                  userInfo['username'] ?? 'Unknown user';
                              final String? profilePicture =
                                  userInfo['profilePicture'];

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: profilePicture != null
                                      ? NetworkImage(profilePicture)
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                  child: profilePicture == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (userId == currentUserId)
                                          PopupMenuButton(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 18,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editReply(
                                                    context,
                                                    comment['commentId'],
                                                    reply,
                                                    index);
                                              } else if (value == 'delete') {
                                                _deleteReply(
                                                    comment['commentId'],
                                                    reply['replyId']);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      reply['text'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                   
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _buildReplyInput(comment),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyInput(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Write a reply...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (value) {
                commentText = value;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _addReply(comment);
              commentController.clear();
            },
          ),
        ],
      ),
    );
  }


  Future<void> _addReply(Map<String, dynamic> comment) async {
    if (commentText.isEmpty) return;

    try {
      final timestamp = DateTime.now();

      // Get the document reference for the comment
      final commentDocRef = FirebaseFirestore.instance
          .collection('upload')
          .doc(widget.postId)
          .collection('comments')
          .doc(comment['commentId']);

      // Create a new document for the reply
      final newReplyDocRef = commentDocRef.collection('replies').doc();

      // Save the reply in Firestore
      await newReplyDocRef.set({
        'userId': currentUserId,
        'text': commentText,
        'timestamp': timestamp,
        'commentId': comment['commentId'],
        'replyId': newReplyDocRef.id,
        'likes': 0,
        'likedBy': [],
      });

      // Update the local state
      setState(() {
        // Add the new reply to the local list of replies
        comment['replies'] = [
          ...?comment['replies'],
          {
            'userId': currentUserId,
            'text': commentText,
            'timestamp': timestamp,
            'commentId': comment['commentId'],
            'replyId': newReplyDocRef.id,
          }
        ];
      });

      showAnimatedOverlayNotification(context, "Reply sent successfully!");
    } catch (e) {
      print("Error adding reply: $e");
      showAnimatedOverlayNotification(context, "Failed to send reply.");
    }
  }

  Future<void> _editComment(
      BuildContext context, Map<String, dynamic> comment, int index) async {
    String newCommentText = comment['text'];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Komentar'),
          content: TextField(
            controller: TextEditingController(text: newCommentText),
            onChanged: (value) {
              newCommentText = value;
            },
            decoration: const InputDecoration(
              labelText: 'Komentar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (newCommentText.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('upload')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(comment['commentId'])
                      .update({'text': newCommentText});

                  setState(() {
                    comments[index]['text'] = newCommentText;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editReply(BuildContext context, String commentId,
      Map<String, dynamic> reply, int index) async {
    String newReplyText = reply['text'];
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Reply'),
          content: TextField(
            controller: TextEditingController(text: newReplyText),
            onChanged: (value) {
              newReplyText = value;
            },
            decoration: const InputDecoration(
              labelText: 'Reply',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (newReplyText.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('upload')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .collection('replies')
                      .doc(reply['replyId'])
                      .update({'text': newReplyText});

                  setState(() {
                    reply['text'] = newReplyText;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReply(String commentId, String replyId) async {
    await FirebaseFirestore.instance
        .collection('upload')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .delete();

    setState(() {
      // Update UI if needed
    });
  }

  Future<void> _toggleReplyLike(
      String commentId, Map<String, dynamic> reply, int index) async {
    final documentRef = FirebaseFirestore.instance
        .collection('upload')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(reply['replyId']);

    if (reply['likedBy']?.contains(currentUserId) ?? false) {
      await documentRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUserId]),
      });
      setState(() {
        reply['likes'] = (reply['likes'] ?? 0) - 1;
        reply['likedBy'].remove(currentUserId);
      });
    } else {
      await documentRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUserId]),
      });
      setState(() {
        reply['likes'] = (reply['likes'] ?? 0) + 1;
        reply['likedBy'] = [...(reply['likedBy'] ?? []), currentUserId];
      });
    }
  }

// Fungsi untuk membangun input komentar
  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
              onChanged: (value) {
                commentText = value;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _addComment();
              commentController.clear();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(int index) async {
    final commentId = comments[index]['commentId'];
    await FirebaseFirestore.instance
        .collection('upload')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    setState(() {
      comments.removeAt(index);
      commentCount -= 1;
    });
  }

  Future<void> _toggleCommentLike(
      Map<String, dynamic> comment, int index) async {
    final commentId = comments[index]['commentId'];
    final documentRef = FirebaseFirestore.instance
        .collection('upload')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId);

    if (comment['likedBy']?.contains(currentUserId) ?? false) {
      // Jika pengguna sudah like, kurangi like dan hapus pengguna dari likedBy
      await documentRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([currentUserId]),
      });
      setState(() {
        comments[index]['likes'] = (comments[index]['likes'] ?? 0) - 1;
        comments[index]['likedBy'].remove(currentUserId);
      });
    } else {
      // Jika pengguna belum like, tambahkan like dan pengguna ke likedBy
      await documentRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([currentUserId]),
      });
      setState(() {
        comments[index]['likes'] = (comments[index]['likes'] ?? 0) + 1;
        comments[index]['likedBy'] = [
          ...(comments[index]['likedBy'] ?? []),
          currentUserId
        ];
      });
    }
  }

  Future<void> _getComments() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('upload')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      comments = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      commentCount = comments.length;
    });
  }

  Future<void> _addComment() async {
    if (commentText.isEmpty) return;

    try {
      final timestamp = DateTime.now();

      // Buat dokumen baru dengan ID unik
      final newCommentDoc = FirebaseFirestore.instance
          .collection('upload')
          .doc(widget.postId)
          .collection('comments')
          .doc();

      // Menyimpan komentar di Firestore
      await newCommentDoc.set({
        'userId': currentUserId,
        'text': commentText,
        'timestamp': timestamp,
        'likes': 0,
        'likedBy': [],
        'commentId': newCommentDoc.id, // Menyimpan commentId
      });

      // Memperbarui state lokal
      setState(() {
        comments.insert(0, {
          'userId': currentUserId,
          'text': commentText,
          'timestamp': timestamp,
          'likes': 0,
          'likedBy': [],
          'commentId': newCommentDoc.id, // Menyimpan commentId di state lokal
        });
        commentController.clear(); // Menghapus input setelah mengirim
        commentText = ""; // Mengosongkan teks komentar
        commentCount += 1; // Mengupdate jumlah komentar
      });

      showAnimatedOverlayNotification(context, "Comment sent successfully!");
    } catch (e) {
      print("Error adding comment: $e");
      showAnimatedOverlayNotification(context, "Failed to send comment.");
    }
  }

  Future<void> _getLatestComment() async {
    // Mengambil satu komentar terbaru
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('upload')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        comments.insert(0, snapshot.docs.first.data() as Map<String, dynamic>);
        commentCount += 1; // Update jumlah komentar
      });
    }
  }

// Tambahkan fungsi _reloadComments untuk memperbarui daftar komentar
  Future<void> _reloadComments() async {
    try {
      // Mengambil komentar berdasarkan postId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('upload')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        comments = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        commentCount = comments.length;
      });
    } catch (e) {
      print("Error reloading comments: $e");
    }
  }

  Future<void> _getLikeStatus() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('upload')
        .doc(widget.postId)
        .get();

    if (snapshot.exists) {
      List<dynamic> likes = snapshot['likes'] ?? [];
      setState(() {
        likeCount = likes.length;
        isLiked = likes.contains(currentUserId);
      });
    }
  }

  Future<void> _getUserData() async {
    try {
      DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('upload')
          .doc(widget.postId)
          .get();

      if (!postSnapshot.exists) {
        print("Post not found!");
        return;
      }

      String? userId = postSnapshot.get('userIdUploadters');
      if (userId == null) {
        print("userId is null in post document!");
        return;
      }

      setState(() {
        uploadedByUserId = userId;
      });

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userSnapshot.exists) {
        print("User document not found for userId: $userId");
        return;
      }

      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        uploadedByUsername = userData['username'] ?? '';
        uploadedByProfileUrl = userData['profilePicture'] ?? '';
      });
    } catch (e) {
      print("Error in _getUserData: $e");
    }
  }

  Future<void> downloadFileFromFirestore() async {
    try {
      // Ambil dokumen dari Firestore berdasarkan postId
      final docSnapshot = await FirebaseFirestore.instance
          .collection('upload')
          .doc(widget.postId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        // Ambil URL file dari Firestore
        final fileUrl = data['url'];

        if (fileUrl != null && fileUrl.isNotEmpty) {
          // Minta izin akses storage (khusus Android)
          if (Platform.isAndroid) {
            final status = await Permission.storage.request();
            if (!status.isGranted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Storage permission denied')),
              );
              return;
            }
          }

          // Unduh file dari URL
          final response = await http.get(Uri.parse(fileUrl));

          // Folder unduhan perangkat
          final downloadsDir = Directory('/storage/emulated/0/Download');

          // Periksa apakah folder ada, jika tidak buat folder
          if (!downloadsDir.existsSync()) {
            await downloadsDir.create(recursive: true);
          }

          // Simpan file dengan nama dari URL
          final fileName = Uri.parse(fileUrl).pathSegments.last;
          final filePath = '${downloadsDir.path}/$fileName';
          final file = File(filePath);

          await file.writeAsBytes(response.bodyBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File downloaded to $filePath')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File URL not found in Firestore')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No document found for this postId')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  Future<void> _toggleLike() async {
    final documentRef =
        FirebaseFirestore.instance.collection('upload').doc(widget.postId);

    if (isLiked) {
      await documentRef.update({
        'likes': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      await documentRef.update({
        'likes': FieldValue.arrayUnion([currentUserId]),
      });
    }
    _getLikeStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        // Tambahkan SafeArea di sini
        child: Stack(
          children: [
            // Konten utama
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar dengan border radius
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: AspectRatio(
                                aspectRatio: 16 /
                                    9, // Sesuaikan dengan rasio yang diinginkan
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Konten lainnya, seperti jumlah likes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleLike,
                      ),
                      Text('$likeCount likes'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: _showCommentWidget,
                      ),
                      Text('$commentCount comments'),
                      const Spacer(), // Tambahkan ini untuk mendorong icon ke kanan
                      IconButton(
                        icon: Icon(
                          Icons.add_to_photos,
                          color: isSavedToAlbum ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          _initAlbumsStream(); // Refresh album list first
                          _showAlbumSelector();
                        }, // Refresh album list first
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () async {
                          await downloadFileFromFirestore();
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Profile photo with tap gesture
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowProfileDetail(
                                  userId: uploadedByUserId,
                                ),
                              ),
                            );
                          },
                          child: uploadedByProfileUrl.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(uploadedByProfileUrl),
                                  radius: 20,
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.grey[300],
                                  radius: 24,
                                  child: Icon(Icons.person,
                                      size: 20, color: Colors.grey[700]),
                                ),
                        ),
                        const SizedBox(width: 10),
                        // Username with tap gesture
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowProfileDetail(
                                  userId: uploadedByUserId,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            uploadedByUsername,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 24.0, top: 6.0, bottom: 0.0), // Margin kiri 24
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 24.0, top: 4.0, bottom: 36.0), // Margin kiri 24
                    child: Text(
                      widget.description,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Tombol kembali di pojok kiri atas
            Positioned(
              top: 24.0, // Jarak dari atas
              left: 18.0, // Jarak dari kiri
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Fungsi kembali
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Colors.black.withOpacity(0.8), // Warna hitam transparan
                  ),
                  padding: EdgeInsets.all(8.0), // Ukuran padding lingkaran
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white, // Warna ikon
                    size: 24.0, // Ukuran ikon
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
