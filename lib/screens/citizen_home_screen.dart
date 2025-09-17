import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'report_issue_screen.dart';
import '../models/report_model.dart';
import 'dart:async';
import 'notifications_screen.dart';
import '../services/notification_service.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _currentIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Report> _userReports = [];
  StreamSubscription<QuerySnapshot>? _reportsSubscription;
  String? _currentUserId;
  int _notificationCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  // Mock data for nearby reports (for demo purposes)
  final List<Map<String, dynamic>> _nearbyReports = [
    {
      'title': 'Pothole on Main Road',
      'description': 'Large pothole causing traffic issues near city center',
      'distance': '0.5 km away',
      'status': 'In Progress',
      'image': 'https://images.unsplash.com/photo-1566272590246-68b5c6dc47a3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      'date': '2 hours ago',
      'upvotes': 12,
      'comments': 5,
    },
    {
      'title': 'Garbage Overflow',
      'description': 'Community bin overflowing with trash attracting pests',
      'distance': '0.8 km away',
      'status': 'Reported',
      'image': 'https://images.unsplash.com/photo-1587334274527-b67651d78723?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      'date': '5 hours ago',
      'upvotes': 8,
      'comments': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _loadUserReports();
    _loadNotifications();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserReports() async {
    if (_currentUserId != null) {
      try {
        _reportsSubscription = _firestore
            .collection('reports')
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          if (mounted) {
            setState(() {
              _userReports = snapshot.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return Report(
                  id: doc.id,
                  userId: data['userId'],
                  category: data['category'],
                  description: data['description'],
                  imageUrl: data['imageUrl'],
                  latitude: data['latitude'],
                  longitude: data['longitude'],
                  status: data['status'],
                  timestamp: data['timestamp'].toDate(),
                  assignedTo: data['assignedTo'],
                  department: data['department'],
                  resolvedAt: data['resolvedAt']?.toDate(),
                );
              }).toList();
            });
          }
        }, onError: (error) {
          print('Error loading reports: $error');
        });
      } catch (e) {
        print('Error setting up reports listener: $e');
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId != null) {
      try {
        _notificationsSubscription = _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _currentUserId)
            .where('read', isEqualTo: false)
            .snapshots()
            .listen((snapshot) {
          if (mounted) {
            setState(() {
              _notificationCount = snapshot.docs.length;
            });
          }
        }, onError: (error) {
          print('Error loading notifications: $error');
        });
      } catch (e) {
        print('Error setting up notifications listener: $e');
      }
    }
  }

  Future<void> _refreshReports() async {
    // Cancel existing subscription and reload
    _reportsSubscription?.cancel();
    await _loadUserReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CivicLink',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Real notifications badge
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .where('userId', isEqualTo: _currentUserId)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Feather.bell),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Feather.map),
            onPressed: () {
              // Navigate to map view
            },
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                );
              },
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              child: const Icon(Feather.plus),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Feather.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Feather.camera),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Feather.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildReportScreen();
      case 2:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1160&q=80'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    FutureBuilder(
                      future: _getUserName(),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Citizen User!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Feather.filter, color: Colors.blue.shade700),
                onPressed: () {
                  // Show filter options
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'My Reports'),
                    Tab(text: 'Nearby Issues'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // My Reports Tab
                      RefreshIndicator(
                        onRefresh: _refreshReports,
                        child: _userReports.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Feather.file_text,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reports yet',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Report your first civic issue!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentIndex = 1; // Switch to Report tab
                                        });
                                      },
                                      child: const Text('Report Issue'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _userReports.length,
                                itemBuilder: (context, index) {
                                  return _buildReportCard(_userReports[index]);
                                },
                              ),
                      ),

                      // Nearby Issues Tab
                      ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _nearbyReports.length,
                        itemBuilder: (context, index) {
                          return _buildMockReportCard(_nearbyReports[index]);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _getUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        var userDoc = await _firestore.collection('users').doc(user.uid).get();
        return userDoc['name'] ?? 'Citizen User';
      } catch (e) {
        return 'Citizen User';
      }
    }
    return 'Citizen User';
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Use conditional rendering with ternary operator
          report.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    report.imageUrl,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey.shade200,
                        child: const Icon(Feather.image, size: 48, color: Colors.grey),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(), // Empty widget if no image
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        report.category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(report.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.status,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (report.department != null)
                  Text(
                    'Department: ${report.department}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reported ${_formatDate(report.timestamp)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (report.assignedTo != null) const SizedBox(height: 8),
                if (report.assignedTo != null)
                  FutureBuilder(
                    future: _getWorkerName(report.assignedTo!),
                    builder: (context, snapshot) {
                      return Row(
                        children: [
                          Icon(
                            Feather.user,
                            size: 14,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Assigned to: ${snapshot.data ?? 'Worker'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (report.resolvedAt != null) const SizedBox(height: 8),
                if (report.resolvedAt != null)
                  Text(
                    'Resolved: ${_formatDate(report.resolvedAt!)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              report['image'],
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        report['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(report['status']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report['status'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report['description'],
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Feather.map_pin,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report['distance'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      report['date'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(Feather.thumbs_up, '${report['upvotes']}', () {}),
                    _buildActionButton(Feather.message_circle, '${report['comments']}', () {}),
                    _buildActionButton(Feather.share, 'Share', () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue.shade700,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Assigned':
        return Colors.blue;
      case 'In Progress':
        return Colors.blue.shade600;
      case 'Resolved':
        return Colors.green;
      case 'Reported':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildReportScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Feather.camera,
            size: 64,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'Report an Issue',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo of the civic issue to report it',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Report Issue',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1160&q=80'),
          ),
          const SizedBox(height: 16),
          Text(
            'Citizen User',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: _getUserEmail(),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'user@example.com',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildProfileButton('Edit Profile', Feather.edit),
          _buildProfileButton('My Reports', Feather.file_text),
          _buildProfileButton('Settings', Feather.settings),
          _buildProfileButton('Help & Support', Feather.help_circle),
          _buildProfileButton('Logout', Feather.log_out, onTap: _logout),
        ],
      ),
    );
  }

  Future<String> _getUserEmail() async {
    User? user = _auth.currentUser;
    return user?.email ?? 'user@example.com';
  }

  Widget _buildProfileButton(String text, IconData icon, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),
        title: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Feather.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey.shade100,
      ),
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<String> _getWorkerName(String workerId) async {
    try {
      var workerDoc = await _firestore.collection('users').doc(workerId).get();
      return workerDoc['name'] ?? 'Municipal Worker';
    } catch (e) {
      return 'Municipal Worker';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}