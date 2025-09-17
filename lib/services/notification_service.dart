import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
      
      // Get device token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _saveDeviceToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveDeviceToken);

      // Handle background messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle when app is in background but opened
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  // Save device token to user document
  Future<void> _saveDeviceToken(String token) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    // You can show a local notification here if needed
  }

  // Handle background messages when app is opened
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message opened: ${message.notification?.title}');
    // Handle navigation to specific screen based on message data
  }

  // CREATE a notification in Firestore
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String reportId,
    required String category,
    String? workerName,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'reportId': reportId,
        'category': category,
        'workerName': workerName,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      print('Notification created for user: $userId');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // SEND assignment notification (sends to Firestore)
  static Future<void> sendAssignmentNotification({
    required String reportId,
    required String citizenUserId,
    required String category,
    required String workerName,
  }) async {
    await createNotification(
      userId: citizenUserId,
      title: 'Issue Assigned! 🛠️',
      body: 'Your $category issue has been assigned to $workerName',
      type: 'assignment',
      reportId: reportId,
      category: category,
      workerName: workerName,
    );
  }

  // SEND resolution notification (sends to Firestore)
  static Future<void> sendResolutionNotification({
    required String reportId,
    required String citizenUserId,
    required String category,
  }) async {
    await createNotification(
      userId: citizenUserId,
      title: 'Issue Resolved! ✅',
      body: 'Your $category issue has been resolved successfully',
      type: 'resolution',
      reportId: reportId,
      category: category,
    );
  }

  // GET notifications stream for a user
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // MARK notification as read
  static Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  // MARK all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }
}