class CoachModel {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? specialization;
  final String? availabilityStatus;
  final String? hireDate;

  CoachModel({
    this.id, required this.firstName, required this.lastName,
    required this.email, this.phone, this.specialization,
    this.availabilityStatus, this.hireDate,
  });

  String get fullName => '$firstName $lastName';

  factory CoachModel.fromJson(Map<String, dynamic> j) => CoachModel(
    id: j['id'],
    firstName: j['firstName'] ?? '',
    lastName:  j['lastName']  ?? '',
    email:     j['email']     ?? '',
    phone:     j['phone'],
    specialization:     j['specialization'],
    availabilityStatus: j['availabilityStatus'],
    hireDate:           j['hireDate'],
  );
}
