class MemberModel {
  final int? id;
  final int? userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? membershipStatus;
  final String? joinDate;
  final String? emergencyContact;
  final String? medicalNotes;

  MemberModel({
    this.id, this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone, this.membershipStatus, this.joinDate,
    this.emergencyContact, this.medicalNotes,
  });

  String get fullName => '$firstName $lastName';

  factory MemberModel.fromJson(Map<String, dynamic> j) => MemberModel(
    id: j['id'], userId: j['userId'],
    firstName: j['firstName'] ?? '',
    lastName:  j['lastName']  ?? '',
    email:     j['email']     ?? '',
    phone:     j['phone'],
    membershipStatus: j['membershipStatus'],
    joinDate:  j['joinDate'],
    emergencyContact: j['emergencyContact'],
    medicalNotes: j['medicalNotes'],
  );
}
