import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_link/models/report_model.dart';
import 'package:civic_link/screens/debug_screen.dart';
import '../services/notification_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  String? _adminDepartment;
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _adminId = _auth.currentUser?.uid;
    _getAdminDepartment();
  }

  Future<void> _getAdminDepartment() async {
    if (_adminId != null) {
      final userDoc = await _firestore.collection('users').doc(_adminId).get();
      if (userDoc.exists) {
        setState(() {
          _adminDepartment = userDoc['department'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _adminDepartment != null 
            ? '$_adminDepartment Dashboard' 
            : 'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Feather.info),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DebugScreen()));
            },
            tooltip: 'Debug Information',
          ),
          IconButton(
            icon: const Icon(Feather.log_out),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Assigned'),
                Tab(text: 'Resolved'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildReportsList('Pending'),
                  _buildReportsList('Assigned'),
                  _buildReportsList('Resolved'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Feather.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Feather.alert_circle),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Feather.user_check),
            label: 'Assigned',
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(String status) {
    // If admin has no department assigned, show all reports
    Stream<QuerySnapshot> stream;
    if (_adminDepartment == null || _adminDepartment!.isEmpty) {
      stream = _firestore
          .collection('reports')
          .where('status', isEqualTo: status)
          .snapshots();
    } else {
      stream = _firestore
          .collection('reports')
          .where('status', isEqualTo: status)
          .where('department', isEqualTo: _adminDepartment)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _adminDepartment == null || _adminDepartment!.isEmpty
                ? 'No $status reports'
                : 'No $status reports for $_adminDepartment department',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            Report report = Report.fromMap(doc.data() as Map<String, dynamic>);
            report.id = doc.id;
            return _buildReportCard(report);
          },
        );
      },
    );
  }

  Widget _buildReportCard(Report report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  report.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Category: ${report.category}',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Description: ${report.description}',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Department: ${report.department ?? "Not assigned"}',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${report.status}',
              style: GoogleFonts.poppins(
                color: _getStatusColor(report.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (report.status == 'Pending')
              ElevatedButton(
                onPressed: () => _autoAssignReport(report),
                child: Text(
                  'Auto-Assign with AI',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Assigned':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.black;
    }
  }

Future<void> _autoAssignReport(Report report) async {
  try {
    // Get all workers first
    QuerySnapshot allWorkers = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'Worker')
        .get();

    // Find the best matching worker based on department
    var assignedWorker;
    
    // First try to find worker in same department
    if (report.department != null && report.department!.isNotEmpty) {
      for (var workerDoc in allWorkers.docs) {
        var workerData = workerDoc.data() as Map<String, dynamic>;
        String workerDept = (workerData['department'] ?? '').toString();
        
        if (workerDept == report.department) {
          assignedWorker = workerDoc;
          break;
        }
      }
    }

    // If no department match found, assign to any available worker
    if (assignedWorker == null && allWorkers.docs.isNotEmpty) {
      assignedWorker = allWorkers.docs.first;
    }

// Update this part in _autoAssignReport method:
if (assignedWorker != null) {
  var workerData = assignedWorker.data() as Map<String, dynamic>;
  
  // Update the report
  await _firestore.collection('reports').doc(report.id).update({
    'assignedTo': assignedWorker.id,
    'status': "Assigned",
    'assignedAt': FieldValue.serverTimestamp(),
  });

  // Send notification to citizen - ADD NULL CHECK
  if (report.id != null) {
    await NotificationService.sendAssignmentNotification(
      reportId: report.id!, // Use ! to assert non-null
      citizenUserId: report.userId,
      category: report.category,
      workerName: workerData['name'] ?? 'Municipal Worker',
    );
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Successfully assigned to ${workerData['name']}'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
} else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No workers available for ${report.department} department'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error assigning report: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
}