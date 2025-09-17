import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/department_helper.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isAnalyzing = false;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;
  String _aiAnalysisResult = '';
  String _detectedIssueType = '';
  Position? _currentPosition;
  String _locationAddress = '';
  double _confidenceLevel = 0.0;

  final List<String> _issueTypes = [
    'Pothole',
    'Garbage Overflow',
    'Street Light Not Working',
    'Water Pipeline Leakage',
    'Broken Drainage',
    'Road Damage',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _issueTypes.first;
  }

  Future<void> _simulateAIAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _aiAnalysisResult = '';
      _detectedIssueType = '';
      _confidenceLevel = 0.0;
    });

    await Future.delayed(const Duration(seconds: 2));

    final imageName = _image?.name.toLowerCase() ?? '';
    final fileSize = 1000000;

    final detectionResult = _smartImageAnalysis(imageName, fileSize);

    setState(() {
      _isAnalyzing = false;
      _detectedIssueType = detectionResult['type'] ?? 'Other';
      _aiAnalysisResult = detectionResult['analysis'] ?? 'Analysis complete';
      _confidenceLevel = detectionResult['confidence'] ?? 0.7;
      _selectedCategory = _detectedIssueType;
    });
  }

  Map<String, dynamic> _smartImageAnalysis(String imageName, int fileSize) {
    if (imageName.contains('pothole') || imageName.contains('road')) {
      return {
        'type': 'Pothole',
        'confidence': 0.92,
        'analysis': '✅ Confirmed: Road Surface Damage\n• Type: Deep pothole\n• Urgency: HIGH - Immediate repair needed'
      };
    }

    if (imageName.contains('garbage') || imageName.contains('trash')) {
      return {
        'type': 'Garbage Overflow',
        'confidence': 0.88,
        'analysis': '✅ Confirmed: Waste Management Issue\n• Bin status: Overflowing\n• Cleanup urgency: Within 24 hours'
      };
    }

    if (imageName.contains('light') || imageName.contains('streetlight')) {
      return {
        'type': 'Street Light Not Working',
        'confidence': 0.82,
        'analysis': '✅ Confirmed: Lighting Infrastructure Issue\n• Safety concern: HIGH at night\n• Repair priority: Medium'
      };
    }

    if (imageName.contains('water') || imageName.contains('pipe')) {
      return {
        'type': 'Water Pipeline Leakage',
        'confidence': 0.87,
        'analysis': '✅ Confirmed: Water Infrastructure Issue\n• Urgency: HIGH - immediate repair'
      };
    }

    if (imageName.contains('drain') || imageName.contains('sewer')) {
      return {
        'type': 'Broken Drainage',
        'confidence': 0.85,
        'analysis': '✅ Confirmed: Drainage Issue\n• Urgency: HIGH during rainfall'
      };
    }

    return {
      'type': 'Other',
      'confidence': 0.65,
      'analysis': '🔍 Analysis Complete\n• Please confirm the issue type'
    };
  }

Future<void> _getCurrentLocation() async {
  setState(() {
    _isGettingLocation = true;
  });

  try {
    // For web demo
    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        // MIT-WPU, Pune coordinates
        _locationAddress = 'MIT-WPU, Pune\nKothrud, Pune, Maharashtra';
        _locationController.text = _locationAddress;
        _currentPosition = Position(
          latitude: 18.5074,  // MIT-WPU latitude
          longitude: 73.8077, // MIT-WPU longitude
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _isGettingLocation = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using MIT-WPU, Pune location for demo'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // For mobile devices - keep the real location code
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    final address = await _simulateReverseGeocoding(position.latitude, position.longitude);

    setState(() {
      _currentPosition = position;
      _locationAddress = address;
      _locationController.text = address;
      _isGettingLocation = false;
    });

  } catch (e) {
    setState(() {
      _isGettingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error getting location: $e')),
    );
  }
}

  Future<String> _simulateReverseGeocoding(double lat, double lng) async {
    await Future.delayed(const Duration(seconds: 1));
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}\nNearby area';
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _image = image;
          _aiAnalysisResult = '';
          _detectedIssueType = '';
        });

        _simulateAIAnalysis();
        _getCurrentLocation();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _image = image;
          _aiAnalysisResult = '';
          _detectedIssueType = '';
        });

        _simulateAIAnalysis();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a photo of the issue')),
        );
        return;
      }

      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please get your current location')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to submit a report')),
          );
          return;
        }

        // Upload image to Firebase Storage (simplified for demo)
        final String imageUrl = 'https://example.com/uploaded-image.jpg';

        // Get the correct department for the category
        final String category = _selectedCategory ?? 'Other';
        final String department = DepartmentHelper.getDepartmentForCategory(category);

        // Create report data
        final reportData = {
          'userId': user.uid,
          'category': category,
          'description': _descriptionController.text,
          'imageUrl': imageUrl,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
          'assignedTo': null,
          'department': department, // This is the key fix - using display name
          'priority': _calculatePriority(category, _descriptionController.text),
          'locationAddress': _locationAddress,
        };

        // Save to Firestore
        await FirebaseFirestore.instance.collection('reports').add(reportData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!')),
        );

        Navigator.pop(context);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  int _calculatePriority(String issueType, String description) {
    if (issueType.toLowerCase().contains('emergency') ||
        description.toLowerCase().contains('urgent')) {
      return 5;
    } else if (issueType.toLowerCase().contains('water') ||
        issueType.toLowerCase().contains('electr')) {
      return 4;
    }
    return 3;
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _aiAnalysisResult = '';
      _detectedIssueType = '';
    });
  }

  Color _getResultColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.blue;
  }

  IconData _getResultIcon(double confidence) {
    if (confidence > 0.8) return Feather.check_circle;
    if (confidence > 0.6) return Feather.alert_circle;
    return Feather.info;
  }

  Widget _buildAnalysisInProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI is analyzing the image...',
              style: GoogleFonts.poppins(
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final resultColor = _getResultColor(_confidenceLevel);
    final resultIcon = _getResultIcon(_confidenceLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: resultColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(resultIcon, size: 18, color: resultColor),
              const SizedBox(width: 8),
              Text(
                'AI Analysis Complete',
                style: GoogleFonts.poppins(
                  color: resultColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_confidenceLevel * 100).toStringAsFixed(0)}% confident',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: resultColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Detected: $_detectedIssueType',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: resultColor,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _aiAnalysisResult,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report an Issue',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isAnalyzing) _buildAnalysisInProgress(),
              if (_aiAnalysisResult.isNotEmpty) _buildAnalysisResult(),

              Text(
                'Issue Type',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(Feather.chevron_down, color: Colors.blue.shade700),
                    items: _issueTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Add Photo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: _image == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Feather.camera,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No photo added',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.network(
                                    _image!.path,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_image!.path),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Feather.x,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Feather.camera, size: 18),
                      label: Text('Take Photo', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectFromGallery,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(Feather.image, size: 18),
                      label: Text('From Gallery', style: GoogleFonts.poppins()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Location',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_currentPosition == null)
                    TextButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: Icon(
                        Feather.map_pin,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      label: Text(
                        'Get Current Location',
                        style: GoogleFonts.poppins(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Location will be automatically detected...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _isGettingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),

              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the issue in detail...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: _isSubmitting
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting Report...'),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Submit Report',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}