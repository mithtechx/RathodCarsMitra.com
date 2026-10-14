class DriverModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? licenseNumber;
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleType;
  final bool isOnDuty;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.licenseNumber,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.vehicleType,
    this.isOnDuty = true,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      fullName: json['full_name'] ?? 'Unknown Driver',
      phoneNumber: json['phone_number'] ?? '',
      licenseNumber: json['license_number'],
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'Sedan',
      isOnDuty: json['is_on_duty'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'license_number': licenseNumber,
      'vehicle_number': vehicleNumber,
      'vehicle_model': vehicleModel,
      'vehicle_type': vehicleType,
      'is_on_duty': isOnDuty,
    };
  }
}