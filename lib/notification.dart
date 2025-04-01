import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model for notifications
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  // Create from Firebase message
  factory NotificationItem.fromMessage(RemoteMessage message) {
    // Determine notification type based on message data
    NotificationType type = NotificationType.system;
    if (message.data['type'] == 'transaction') {
      type = NotificationType.transaction;
    } else if (message.data['type'] == 'alert') {
      type = NotificationType.alert;
    }

    return NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      message: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );
  }

  // Create from Firestore document
  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse the timestamp
    DateTime timestamp;
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else {
      timestamp = DateTime.parse(data['timestamp']);
    }

    // Determine notification type
    NotificationType type;
    switch (data['type']) {
      case 'transaction':
        type = NotificationType.transaction;
        break;
      case 'alert':
        type = NotificationType.alert;
        break;
      default:
        type = NotificationType.system;
    }

    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: timestamp,
      isRead: data['isRead'] ?? false,
      type: type,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }
}

// Notification types for different icons and colors
enum NotificationType {
  transaction,
  alert,
  system,
}

class NotificationPage extends StatefulWidget {
  final RemoteMessage? initialMessage;

  const NotificationPage({Key? key, this.initialMessage}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NotificationItem> notifications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenForNotifications();
    
    // If page was opened from a notification, mark that notification as read
    if (widget.initialMessage != null) {
      _handleInitialMessage(widget.initialMessage!);
    }
    
    // Set up Firebase Messaging handlers for when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleNewNotification);
    
    // Handle when a notification is tapped while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNewNotification);
  }
  
  void _handleInitialMessage(RemoteMessage message) {
    if (message.messageId != null) {
      _firestore
          .collection('notifications')
          .where('messageId', isEqualTo: message.messageId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _firestore
              .collection('notifications')
              .doc(snapshot.docs.first.id)
              .update({'isRead': true});
        }
      });
    }
  }
  
  void _handleNewNotification(RemoteMessage message) {
    final newNotification = NotificationItem.fromMessage(message);
    
    // Update UI immediately
    setState(() {
      notifications.insert(0, newNotification);
    });
    
    // Save to Firestore (optional but recommended for persistence)
    _saveNotificationToFirestore(newNotification);
  }
  
  Future<void> _saveNotificationToFirestore(NotificationItem notification) async {
    await _firestore.collection('notifications').add(notification.toMap());
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();
      
      setState(() {
        notifications = snapshot.docs
            .map((doc) => NotificationItem.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _listenForNotifications() {
    _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        notifications = snapshot.docs
            .map((doc) => NotificationItem.fromFirestore(doc))
            .toList();
      });
    });
  }
  
  Future<void> _markAsRead(NotificationItem notification) async {
    // Find document with matching id
    final snapshot = await _firestore
        .collection('notifications')
        .where(FieldPath.documentId, isEqualTo: notification.id)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      await _firestore
          .collection('notifications')
          .doc(snapshot.docs.first.id)
          .update({'isRead': true});
      
      setState(() {
        notification.isRead = true;
      });
    }
  }
  
  Future<void> _markAllAsRead() async {
    // Get all unread notifications
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    
    // Update each document in a batch
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    // Commit the batch
    await batch.commit();
    
    // Update UI immediately
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All notifications marked as read'))
    );
  }
  
  Future<void> _deleteNotification(NotificationItem notification) async {
    // Find document with matching id
    final snapshot = await _firestore
        .collection('notifications')
        .where(FieldPath.documentId, isEqualTo: notification.id)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      await _firestore
          .collection('notifications')
          .doc(snapshot.docs.first.id)
          .delete();
      
      setState(() {
        notifications.remove(notification);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.purple),
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.purple),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(notifications[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 70,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "No Notifications",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted'))
        );
      },
      child: GestureDetector(
        onTap: () {
          // Mark as read when tapped
          _markAsRead(notification);
          
          // Show full notification details
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(notification.title),
                content: Text(notification.message),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _getNotificationIcon(notification.type),
            title: Text(
              notification.title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  notification.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  _getFormattedTime(notification.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.transaction:
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.green;
        break;
      case NotificationType.alert:
        iconData = Icons.warning_amber;
        iconColor = Colors.orange;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = Colors.blue;
        break;
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getFormattedTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}