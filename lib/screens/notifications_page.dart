import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifikasi")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("Tidak ada notifikasi."));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(_getNotificationText(notification)),
                subtitle: Text(notification['timestamp'].toDate().toString()),
                leading: Icon(_getNotificationIcon(notification['type'])),
                onTap: () {
                  _markAsRead(notifications[index].id);
                  // Arahkan ke post atau komentar terkait
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getNotificationText(Map<String, dynamic> notification) {
    switch (notification['type']) {
      case "like":
        return "Seseorang menyukai postingan Anda";
      case "comment":
        return "Seseorang mengomentari postingan Anda";
      case "reply":
        return "Seseorang membalas komentar Anda";
      case "like_comment":
        return "Seseorang menyukai komentar Anda";
      default:
        return "Notifikasi baru";
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case "like":
        return Icons.favorite;
      case "comment":
        return Icons.comment;
      case "reply":
        return Icons.reply;
      case "like_comment":
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}
