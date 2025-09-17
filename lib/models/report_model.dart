class Report {
  String? id;
  String userId;
  String category;
  String description;
  String imageUrl; // Before image
  String? afterImageUrl; // After image (new field)
  double latitude;
  double longitude;
  String status;
  String? assignedTo;
  DateTime timestamp;
  String? department;
  int? priority;
  String? locationAddress;
  DateTime? resolvedAt; // New field for resolution timestamp

  Report({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.imageUrl,
    this.afterImageUrl,
    required this.latitude,
    required this.longitude,
    this.status = 'Pending',
    this.assignedTo,
    required this.timestamp,
    this.department,
    this.priority,
    this.locationAddress,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'afterImageUrl': afterImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'assignedTo': assignedTo,
      'timestamp': timestamp,
      'department': department,
      'priority': priority,
      'locationAddress': locationAddress,
      'resolvedAt': resolvedAt,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      userId: map['userId'],
      category: map['category'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      afterImageUrl: map['afterImageUrl'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
      assignedTo: map['assignedTo'],
      timestamp: map['timestamp'].toDate(),
      department: map['department'],
      priority: map['priority'],
      locationAddress: map['locationAddress'],
      resolvedAt: map['resolvedAt']?.toDate(),
    );
  }
}