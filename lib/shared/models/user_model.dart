class UserModel {
  final String id;
  final String phone;
  final String role; // HOUSEHOLD | COLLECTOR | ADMIN
  final String? fullName;
  final String? address;
  final String status; // PENDING | ACTIVE | SUSPENDED
  final bool isOnline;
  final double rating;
  final int totalPickups;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? lastLat;
  final double? lastLng;

  const UserModel({
    required this.id,
    required this.phone,
    required this.role,
    this.fullName,
    this.address,
    this.status = 'ACTIVE',
    this.isOnline = false,
    this.rating = 5.0,
    this.totalPickups = 0,
    this.vehicleType,
    this.vehiclePlate,
    this.lastLat,
    this.lastLng,
  });

  bool get isHousehold => role == 'HOUSEHOLD';
  bool get isCollector => role == 'COLLECTOR';
  bool get isAdmin => role == 'ADMIN';
  bool get isPending => status == 'PENDING';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:           json['id'] as String,
      phone:        json['phone'] as String,
      role:         json['role'] as String? ?? 'HOUSEHOLD',
      fullName:     json['fullName'] as String?,
      address:      json['address'] as String?,
      status:       json['status'] as String? ?? 'ACTIVE',
      isOnline:     json['isOnline'] as bool? ?? false,
      rating:       (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalPickups: json['totalPickups'] as int? ?? 0,
      vehicleType:  json['vehicleType'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      lastLat:      (json['lastLat'] as num?)?.toDouble(),
      lastLng:      (json['lastLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'phone': phone, 'role': role,
    'fullName': fullName, 'address': address, 'status': status,
    'isOnline': isOnline, 'rating': rating, 'totalPickups': totalPickups,
    'vehicleType': vehicleType, 'vehiclePlate': vehiclePlate,
    'lastLat': lastLat, 'lastLng': lastLng,
  };

  UserModel copyWith({
    String? fullName, String? address, bool? isOnline,
    String? vehicleType, String? vehiclePlate,
    double? lastLat, double? lastLng,
  }) {
    return UserModel(
      id: id, phone: phone, role: role, status: status,
      rating: rating, totalPickups: totalPickups,
      fullName:    fullName    ?? this.fullName,
      address:     address     ?? this.address,
      isOnline:    isOnline    ?? this.isOnline,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
    );
  }
}
