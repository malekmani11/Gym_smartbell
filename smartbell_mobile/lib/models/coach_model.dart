class CoachModel {
  final int? id;
  final int? userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? specialization;
  final String? bio;
  final String? certification;
  final String? availabilityStatus;
  final String? hireDate;
  final double? ratingAvg;

  CoachModel({
    this.id, this.userId, required this.firstName, required this.lastName,
    required this.email, this.phone, this.specialization,
    this.bio, this.certification,
    this.availabilityStatus, this.hireDate, this.ratingAvg,
  });

  String get fullName => '$firstName $lastName';

  static String specializationLabel(String? s) {
    const labels = {
      'BODYBUILDING': 'Musculation',
      'YOGA':         'Yoga',
      'PILATES':      'Pilates',
      'CROSSFIT':     'CrossFit',
      'HIIT':         'HIIT',
      'CARDIO':       'Cardio',
      'NUTRITION':    'Nutrition',
      'STRETCHING':   'Stretching',
      'FUNCTIONAL':   'Fonctionnel',
    };
    return labels[s?.toUpperCase()] ?? s ?? '';
  }

  factory CoachModel.fromJson(Map<String, dynamic> j) => CoachModel(
    id:     (j['id']     as num?)?.toInt(),
    userId: (j['userId'] as num?)?.toInt(),
    firstName: j['firstName'] ?? '',
    lastName:  j['lastName']  ?? '',
    email:     j['email']     ?? '',
    phone:     j['phone'] as String?,
    specialization:     j['specialization'] as String?,
    bio:                j['bio']            as String?,
    certification:      j['certification']  as String?,
    availabilityStatus: j['availabilityStatus'] as String?,
    hireDate:           j['hireDate']?.toString(),
    ratingAvg: (j['ratingAvg'] as num?)?.toDouble(),
  );
}
