import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Information'),
      ),
      body: FutureBuilder(
        future: _getDebugData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final data = snapshot.data as Map<String, dynamic>;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Current User', data['userData']),
                const SizedBox(height: 20),
                _buildSection('All Reports', data['reportsData']),
                const SizedBox(height: 20),
                _buildSection('All Workers', data['workersData']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            content,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getDebugData() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    // Get current user data
    Map<String, dynamic> userData = {'id': currentUser?.uid ?? 'No user'};
    if (currentUser != null) {
      final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        userData['id'] = currentUser.uid;
      }
    }

    // Get all reports
    final reportsSnapshot = await firestore.collection('reports').get();
    final reportsData = reportsSnapshot.docs.map((doc) {
      final data = doc.data();
      return 'ID: ${doc.id}\n${data.toString()}\n---';
    }).join('\n');

    // Get all workers
    final workersSnapshot = await firestore.collection('users').where('role', isEqualTo: 'Worker').get();
    final workersData = workersSnapshot.docs.map((doc) {
      final data = doc.data();
      return 'ID: ${doc.id}\n${data.toString()}\n---';
    }).join('\n');

    return {
      'userData': userData.toString(),
      'reportsData': reportsData,
      'workersData': workersData,
    };
  }
}