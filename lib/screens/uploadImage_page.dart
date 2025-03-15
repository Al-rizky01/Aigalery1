import 'dart:io';
// import 'package:aigalery1/widgets/app_bbn.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadImagePage extends StatefulWidget {
  final String userIdUploadters;

  const UploadImagePage({Key? key, required this.userIdUploadters}) : super(key: key);

  @override
  _UploadImagePageState createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _handlePermissions() async {
    if (Platform.isAndroid) {
      if (await _checkAndroidVersion()) {
        final photos = await Permission.photos.status;
        if (photos.isGranted) return true;
        final result = await Permission.photos.request();
        if (result.isDenied) {
          openAppSettings();
        }
        return result.isGranted;
      } else {
        final storage = await Permission.storage.status;
        if (storage.isGranted) return true;
        final result = await Permission.storage.request();
        if (result.isDenied) {
          openAppSettings();
        }
        return result.isGranted;
      }
    } else if (Platform.isIOS) {
      final photos = await Permission.photos.status;
      if (photos.isGranted) return true;
      final result = await Permission.photos.request();
      if (result.isDenied) {
        openAppSettings();
      }
      return result.isGranted;
    }
    return false;
  }

  Future<bool> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  Future<void> _pickImage() async {
    final hasPermission = await _handlePermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please enable it in app settings.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(String userIdUploadters) async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title  cannot be empty')),
      );
      return;
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        File(_imageFile!.path).absolute.path,
        File(_imageFile!.path).absolute.path + '_compressed.jpg',
        quality: 70,
      );

      if (compressedXFile == null) {
        throw Exception('Failed to compress image');
      }

      final compressedFile = File(compressedXFile.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('upload/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(compressedFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('upload').add({
        'url': downloadUrl,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'userIdUploadters': userIdUploadters,
      });

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _imageFile = null;
        _isLoading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Area untuk pratinjau gambar atau tombol Pick Image
GestureDetector(
  onTap: _pickImage,
  child: Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey),
    ),
    child: _imageFile == null
        ? const Icon(
            Icons.image,
            size: 50,
            color: Colors.grey,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_imageFile!.path),
              fit: BoxFit.cover,
            ),
          ),
  ),
),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16.0),
           
        
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _uploadImage(widget.userIdUploadters),
              child: _isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(value: _uploadProgress),
                        const SizedBox(height: 8),
                        Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                      ],
                    )
                  : const Text('Upload Image'),
            ),
          ],
        ),
      ),
      
    );
  }
}
