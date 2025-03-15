import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'DetailPage.dart';
import 'viewUseruploadpage.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  Map<String, dynamic>? userData;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _newImage;
  late Future<DocumentSnapshot> userFuture;

  @override
  void initState() {
    super.initState(); // Add this line
    userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  // Profile picture methods
  Future<void> _changeProfilePicture() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
      _newImage = pickedFile;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${widget.userId}.jpg');
      await storageRef.putFile(File(_newImage!.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'profilePicture': downloadUrl});

      setState(() {
        _isLoading = false;
        if (userData != null) {
          userData!['profilePicture'] = downloadUrl;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    }
  }

  void _showChangeProfilePictureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Profile Picture'),
          content: const Text('Do you want to change your profile picture?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _changeProfilePicture();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // User data editing methods
  Future<void> _changeUsername() async {
    final TextEditingController usernameController = TextEditingController(
      text: userData?['username'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Username'),
          content: TextFormField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'New Username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (usernameController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .update({'username': usernameController.text});

                    setState(() {
                      if (userData != null) {
                        userData!['username'] = usernameController.text;
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Username updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update username: $e')),
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeBirthdate() async {
    DateTime? selectedDate = userData?['birthdate'] is Timestamp
        ? (userData?['birthdate'] as Timestamp).toDate()
        : DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'birthdate': pickedDate});

        setState(() {
          if (userData != null) {
            userData!['birthdate'] = pickedDate;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Birthdate updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update birthdate: $e')),
        );
      }
    }
  }

  Future<void> _changeDescription() async {
    final TextEditingController descriptionController = TextEditingController(
      text: userData?['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Description'),
          content: TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'New Description',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (descriptionController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .update({'description': descriptionController.text});

                    setState(() {
                      if (userData != null) {
                        userData!['description'] = descriptionController.text;
                      }
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Description updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to update description: $e')),
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Utility methods
  String _formatBirthdate(dynamic birthdate) {
    if (birthdate is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(birthdate.toDate());
    } else if (birthdate is String) {
      try {
        final parsedDate = DateTime.parse(birthdate);
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        return birthdate;
      }
    } else {
      return 'N/A';
    }
  }

  // Profile actions menu
  void _showProfileActionsMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Change Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeProfilePictureDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Change Username'),
                onTap: () {
                  Navigator.pop(context);
                  _changeUsername();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Change Birthdate'),
                onTap: () {
                  Navigator.pop(context);
                  _changeBirthdate();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Change Description'),
                onTap: () {
                  Navigator.pop(context);
                  _changeDescription();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Detail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showProfileActionsMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<DocumentSnapshot>(
              future: userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User not found"));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                this.userData =
                    userData; // Store user data for editing functions

                final String username = userData['username'] ?? 'No Username';
                final String email = userData['email'] ?? 'No Email';
                final String profilePicture = userData['profilePicture'] ?? '';
                final String description =
                    userData['description'] ?? 'No description available';
                final dynamic birthdate = userData['birthdate'];

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _showChangeProfilePictureDialog,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: profilePicture.isNotEmpty
                                ? NetworkImage(profilePicture)
                                : null,
                            child: profilePicture.isEmpty
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    if (birthdate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Born: ${_formatBirthdate(birthdate)}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Upload",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Menampilkan daftar unggahan user
                    Expanded(
                      child: UserUploadsPage(userId: widget.userId),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class UserUploadsPage extends StatelessWidget {
  final String userId;

  const UserUploadsPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('upload')
          .where('userIdUploadters', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No uploads found.'));
        }

        final List<DocumentSnapshot> documents = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8, // Adjusted to show title below image
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final data = documents[index].data() as Map<String, dynamic>;
            final String postId = documents[index].id;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(
                      imageUrl: data['url'] ?? '',
                      title: data['title'] ?? 'No Title',
                      description: data['description'] ?? 'No Description',
                      username: data['username'] ?? 'Unknown User',
                      postId: postId,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: data['url'] != null && data['url'].isNotEmpty
                          ? Image.network(
                              data['url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            deleteImage(context, postId); // Gunakan postId
                          } else if (value == 'edit_details') {
                            editDetails(context, postId, data['title'] ?? '',
                                data['description'] ?? '');
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Image'),
                          ),
                          const PopupMenuItem(
                            value: 'edit_details',
                            child: Text('Edit'),
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
  }

  void editDetails(BuildContext context, String docId, String currentTitle,
      String currentDescription) {
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Invalid document ID")),
      );
      return;
    }

    TextEditingController titleController =
        TextEditingController(text: currentTitle);
    TextEditingController descriptionController =
        TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newTitle = titleController.text.trim();
              String newDescription = descriptionController.text.trim();

              if (newTitle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Title cannot be empty")),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('upload')
                    .doc(docId)
                    .update({'title': newTitle, 'description': newDescription});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Details updated successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error updating details: $e")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void deleteImage(BuildContext context, String? docId) {
    if (docId == null || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Invalid document ID")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Image"),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('upload')
                    .doc(docId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Image deleted successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error deleting image: $e")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void editTitle(BuildContext context, String? docId, String? currentTitle) {
    if (docId == null || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Invalid document ID")),
      );
      return;
    }

    TextEditingController titleController =
        TextEditingController(text: currentTitle ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Title"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: "Enter new title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newTitle = titleController.text.trim();
              if (newTitle.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Title cannot be empty")),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('upload')
                    .doc(docId)
                    .update({'title': newTitle});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Title updated successfully")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error updating title: $e")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
