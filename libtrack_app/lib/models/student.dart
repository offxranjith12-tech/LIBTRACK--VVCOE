class Student {
  final String id;
  final String name;
  final String registerNumber;
  final String department;
  final String semester;
  final String email;
  final String phone;
  final String libraryCardNumber;
  final String? photoUrl;

  const Student({
    required this.id,
    required this.name,
    required this.registerNumber,
    required this.department,
    required this.semester,
    required this.email,
    required this.phone,
    required this.libraryCardNumber,
    this.photoUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        registerNumber: json['registerNumber'] ?? '',
        department: json['department'] ?? '',
        semester: json['semester'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        libraryCardNumber: json['libraryCardNumber'] ?? '',
        photoUrl: json['photoUrl'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'registerNumber': registerNumber,
        'department': department,
        'semester': semester,
        'email': email,
        'phone': phone,
        'libraryCardNumber': libraryCardNumber,
        'photoUrl': photoUrl,
      };

  Student copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) =>
      Student(
        id: id,
        name: name ?? this.name,
        registerNumber: registerNumber,
        department: department,
        semester: semester,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        libraryCardNumber: libraryCardNumber,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}
