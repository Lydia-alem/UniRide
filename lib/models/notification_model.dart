import 'package:uuid/uuid.dart';

enum NotificationType {
  reservation,
  cancellation,
  penalty,
  busUpdate,
  extraBus,
  admin,
  chat,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  AppNotification({
    String? id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = NotificationType.reservation,
    this.isRead = false,
    DateTime? createdAt,
    this.data,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  AppNotification copyWith({
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'data': data,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        body: json['body'],
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.reservation,
        ),
        isRead: json['isRead'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        data: json['data'] != null
            ? Map<String, dynamic>.from(json['data'])
            : null,
      );
}

class ExtraBusRequest {
  final String id;
  final String userId;
  final String routeId;
  final String destination;
  final DateTime requestedDate;
  final String requestedTime;
  final DateTime createdAt;
  final bool isProcessed;

  ExtraBusRequest({
    String? id,
    required this.userId,
    required this.routeId,
    required this.destination,
    required this.requestedDate,
    required this.requestedTime,
    DateTime? createdAt,
    this.isProcessed = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'routeId': routeId,
        'destination': destination,
        'requestedDate': requestedDate.toIso8601String(),
        'requestedTime': requestedTime,
        'createdAt': createdAt.toIso8601String(),
        'isProcessed': isProcessed,
      };

  factory ExtraBusRequest.fromJson(Map<String, dynamic> json) =>
      ExtraBusRequest(
        id: json['id'],
        userId: json['userId'],
        routeId: json['routeId'],
        destination: json['destination'],
        requestedDate: DateTime.parse(json['requestedDate']),
        requestedTime: json['requestedTime'],
        createdAt: DateTime.parse(json['createdAt']),
        isProcessed: json['isProcessed'] ?? false,
      );

  ExtraBusRequest copyWith({bool? isProcessed}) {
    return ExtraBusRequest(
      id: id,
      userId: userId,
      routeId: routeId,
      destination: destination,
      requestedDate: requestedDate,
      requestedTime: requestedTime,
      createdAt: createdAt,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
}

class ClassSchedule {
  final String id;
  final String userId;
  final String courseName;
  final String location;
  final List<int> weekdays; // 1=Monday..7=Sunday
  final String startTime;
  final String endTime;
  final String color;

  ClassSchedule({
    String? id,
    required this.userId,
    required this.courseName,
    required this.location,
    required this.weekdays,
    required this.startTime,
    required this.endTime,
    this.color = '#8B5CF6',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'courseName': courseName,
        'location': location,
        'weekdays': weekdays,
        'startTime': startTime,
        'endTime': endTime,
        'color': color,
      };

  factory ClassSchedule.fromJson(Map<String, dynamic> json) => ClassSchedule(
        id: json['id'],
        userId: json['userId'],
        courseName: json['courseName'],
        location: json['location'],
        weekdays: List<int>.from(json['weekdays']),
        startTime: json['startTime'],
        endTime: json['endTime'],
        color: json['color'] ?? '#8B5CF6',
      );
}
