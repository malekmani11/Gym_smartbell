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
  final int? assignedCoachId;
  final String? assignedCoachName;
  final bool messagingEnabled;

  MemberModel({
    this.id, this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone, this.membershipStatus, this.joinDate,
    this.emergencyContact, this.medicalNotes,
    this.assignedCoachId, this.assignedCoachName,
    this.messagingEnabled = false,
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
    assignedCoachId:   j['assignedCoachId'] != null ? (j['assignedCoachId'] as num).toInt() : null,
    assignedCoachName: j['assignedCoachName'],
    messagingEnabled:  j['messagingEnabled'] ?? false,
  );
}
