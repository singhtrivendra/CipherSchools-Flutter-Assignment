import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Sample notification data - in a real app, this would come from a service or database
  List<NotificationItem> notifications = [
    NotificationItem(
      title: "New Transaction Added",
      message: "You've added ₹2,500.00 to your income.",
      timestamp: DateTime.now().subtract(Duration(hours: 1)),
      isRead: false,
      type: NotificationType.transaction,
    ),
    NotificationItem(
      title: "Budget Alert",
      message: "You've exceeded your shopping budget by 15%.",
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
      isRead: true,
      type: NotificationType.alert,
    ),
    NotificationItem(
      title: "Account Update",
      message: "Your account details have been updated successfully.",
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      isRead: true,
      type: NotificationType.system,
    ),
    NotificationItem(
      title: "Welcome to Finance Tracker",
      message: "Thank you for downloading our app. Start tracking your finances today!",
      timestamp: DateTime.now().subtract(Duration(days: 2)),
      isRead: true,
      type: NotificationType.system,
    ),
  ];

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
            onPressed: () {
              // Mark all as read
              setState(() {
                for (var notification in notifications) {
                  notification.isRead = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('All notifications marked as read'))
              );
            },
          ),
        ],
      ),
      body: notifications.isEmpty
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
      key: Key(notification.timestamp.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted'))
        );
      },
      child: GestureDetector(
        onTap: () {
          // Mark as read when tapped
          setState(() {
            notification.isRead = true;
          });
          
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

// Notification data model
class NotificationItem {
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });
}

// Notification types for different icons and colors
enum NotificationType {
  transaction,
  alert,
  system,
}