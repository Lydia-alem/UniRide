import 'package:uuid/uuid.dart';

enum UserRole { student, driver, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password; // hashed in real app
  final UserRole role;
  final String? studentId;
  final String? university;
  final String? phone;
  final int cancellationCount;
  final DateTime? penaltyUntil;
  final List<String> scheduleIds;
  final DateTime createdAt;

  AppUser({
    String? id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.studentId,
    this.university,
    this.phone,
    this.cancellationCount = 0,
    this.penaltyUntil,
    List<String>? scheduleIds,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        scheduleIds = scheduleIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get isPenalized =>
      penaltyUntil != null && penaltyUntil!.isAfter(DateTime.now());

  AppUser copyWith({
    String? name,
    String? email,
    String? password,
    UserRole? role,
    String? studentId,
    String? university,
    String? phone,
    int? cancellationCount,
    DateTime? penaltyUntil,
    List<String>? scheduleIds,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      university: university ?? this.university,
      phone: phone ?? this.phone,
      cancellationCount: cancellationCount ?? this.cancellationCount,
      penaltyUntil: penaltyUntil ?? this.penaltyUntil,
      scheduleIds: scheduleIds ?? this.scheduleIds,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role.name,
        'studentId': studentId,
        'university': university,
        'phone': phone,
        'cancellationCount': cancellationCount,
        'penaltyUntil': penaltyUntil?.toIso8601String(),
        'scheduleIds': scheduleIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        role: UserRole.values.firstWhere((r) => r.name == json['role']),
        studentId: json['studentId'],
        university: json['university'],
        phone: json['phone'],
        cancellationCount: json['cancellationCount'] ?? 0,
        penaltyUntil: json['penaltyUntil'] != null
            ? DateTime.parse(json['penaltyUntil'])
            : null,
        scheduleIds: List<String>.from(json['scheduleIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
      );
}
