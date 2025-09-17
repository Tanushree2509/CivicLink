import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Import your screen files
import 'screens/login_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/citizen_home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDuwdPAylkCj8yUOli7_Xk76GYzMd_Blj0",
        authDomain: "civiclink-8ca46.firebaseapp.com",
        projectId: "civiclink-8ca46",
        storageBucket: "civiclink-8ca46.firebasestorage.app",
        messagingSenderId: "1058297290954",
        appId: "1:1058297290954:web:b6080e7c5f4b0ba5579433",
      ),
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  // Initialize notifications
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Notification service initialization error: $e');
  }
  
  // Create demo users for testing
  await _createDemoUsers();
  
  runApp(const MyApp());
}

Future<void> _createDemoUsers() async {
  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final messaging = FirebaseMessaging.instance;
    
    // Get FCM token for notifications
    String? fcmToken = await messaging.getToken();
    
    // Check if demo users already exist
    final usersSnapshot = await firestore.collection('users').limit(1).get();
    
    if (usersSnapshot.docs.isEmpty) {
      print('Creating demo users...');
      
      // Demo users data
      final demoUsers = [
        {
          'email': 'citizen@demo.com',
          'password': 'demo123',
          'name': 'Demo Citizen',
          'role': 'Citizen',
          'department': null,
          'fcmToken': fcmToken,
        },
        {
          'email': 'roads.admin@civiclink.com',
          'password': 'admin123',
          'name': 'Roads Department Admin',
          'role': 'Admin',
          'department': 'Roads & Infrastructure',
          'fcmToken': fcmToken,
        },
        {
          'email': 'sanitation.admin@civiclink.com',
          'password': 'admin123',
          'name': 'Sanitation Department Admin',
          'role': 'Admin',
          'department': 'Sanitation',
          'fcmToken': fcmToken,
        },
        {
          'email': 'electricity.admin@civiclink.com',
          'password': 'admin123',
          'name': 'Electricity Department Admin',
          'role': 'Admin',
          'department': 'Electricity',
          'fcmToken': fcmToken,
        },
        {
          'email': 'roads.worker@civiclink.com',
          'password': 'worker123',
          'name': 'Road Repair Worker',
          'role': 'Worker',
          'department': 'Roads & Infrastructure',
          'fcmToken': fcmToken,
        },
        {
          'email': 'sanitation.worker@civiclink.com',
          'password': 'worker123',
          'name': 'Sanitation Worker',
          'role': 'Worker',
          'department': 'Sanitation',
          'fcmToken': fcmToken,
        },
        {
          'email': 'electricity.worker@civiclink.com',
          'password': 'worker123',
          'name': 'Lighting Technician',
          'role': 'Worker',
          'department': 'Electricity',
          'fcmToken': fcmToken,
        },
      ];
      
      for (var userData in demoUsers) {
        try {
          // Create auth user
          final userCredential = await auth.createUserWithEmailAndPassword(
            email: userData['email']!,
            password: userData['password']!,
          );
          
          // Create user document in Firestore
          await firestore.collection('users').doc(userCredential.user!.uid).set({
            'email': userData['email'],
            'name': userData['name'],
            'role': userData['role'],
            'department': userData['department'],
            'fcmToken': userData['fcmToken'],
            'fcmTokenUpdated': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('Created user: ${userData['email']}');
        } catch (e) {
          print('Error creating user ${userData['email']}: $e');
          // User might already exist, continue with next
        }
      }
      
      print('Demo users created successfully!');
      
      // Create some sample reports for testing
      await _createSampleReports();
      
    } else {
      print('Demo users already exist');
    }
  } catch (e) {
    print('Error creating demo users: $e');
  }
}

Future<void> _createSampleReports() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Get citizen user for reports
    final citizenQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: 'citizen@demo.com')
        .get();
    
    if (citizenQuery.docs.isNotEmpty) {
      final citizen = citizenQuery.docs.first;
      final citizenId = citizen.id;
      
      // Sample reports data
      final sampleReports = [
        {
          'userId': citizenId,
          'category': 'Pothole',
          'description': 'Large pothole on Main Road near MIT-WPU campus',
          'imageUrl': 'https://images.unsplash.com/photo-1566272590246-68b5c6dc47a3',
          'latitude': 18.5074,
          'longitude': 73.8077,
          'status': 'Pending',
          'department': 'Roads & Infrastructure',
          'timestamp': FieldValue.serverTimestamp(),
        },
        {
          'userId': citizenId,
          'category': 'Garbage Overflow',
          'description': 'Garbage bin overflowing near college entrance',
          'imageUrl': 'https://images.unsplash.com/photo-1587334274527-b67651d78723',
          'latitude': 18.5078,
          'longitude': 73.8080,
          'status': 'Assigned',
          'department': 'Sanitation',
          'assignedTo': await _getWorkerId('sanitation.worker@civiclink.com'),
          'assignedAt': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
        },
        {
          'userId': citizenId,
          'category': 'Street Light Not Working',
          'description': 'Street light out on campus road',
          'imageUrl': 'https://images.unsplash.com/photo-1518837695005-2083093ee35b',
          'latitude': 18.5070,
          'longitude': 73.8070,
          'status': 'Resolved',
          'department': 'Electricity',
          'assignedTo': await _getWorkerId('electricity.worker@civiclink.com'),
          'resolvedAt': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
        },
      ];
      
      for (var reportData in sampleReports) {
        await firestore.collection('reports').add(reportData);
      }
      
      print('Sample reports created successfully!');
    }
  } catch (e) {
    print('Error creating sample reports: $e');
  }
}

Future<String?> _getWorkerId(String email) async {
  try {
    final workerQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    
    if (workerQuery.docs.isNotEmpty) {
      return workerQuery.docs.first.id;
    }
  } catch (e) {
    print('Error getting worker ID: $e');
  }
  return null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Link',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const HomeSelectorScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminHomeScreen(),
        '/worker-dashboard': (context) => const WorkerHomeScreen(),
        '/citizen-dashboard': (context) => const CitizenHomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeSelectorScreen extends StatelessWidget {
  const HomeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(Icons.report_problem, size: 60, color: Colors.blue),
              ),
              const SizedBox(height: 30),
              
              Text(
                'CivicLink',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Community Issue Reporting',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 50),
              
              // Citizen Login Button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Citizen Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Admin Login Button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    'Admin Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Worker Login Button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    // Workers can login through the main login screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    'Worker Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Demo Info
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Demo Credentials',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Citizen: citizen@demo.com / demo123\n'
                      'Admin: [department].admin@civiclink.com / admin123\n'
                      'Worker: [department].worker@civiclink.com / worker123',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}