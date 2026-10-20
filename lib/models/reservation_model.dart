import 'package:uuid/uuid.dart';

enum ReservationStatus {
  pending,
  confirmed,
  cancelled,
  boarded,
  noShow,
}

enum SeatType { seated, standing }

class Reservation {
  final String id;
  final String userId;
  final String busId;
  final String routeId;
  final String seatNumber;
  final SeatType seatType;
  final ReservationStatus status;
  final String qrCode;
  final DateTime reservedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? boardedAt;
  final String departureTime;
  final DateTime departureDate;
  final String origin;
  final String destination;
  final String? cancellationReason;

  Reservation({
    String? id,
    required this.userId,
    required this.busId,
    required this.routeId,
    required this.seatNumber,
    this.seatType = SeatType.seated,
    this.status = ReservationStatus.pending,
    String? qrCode,
    DateTime? reservedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.boardedAt,
    required this.departureTime,
    required this.departureDate,
    required this.origin,
    required this.destination,
    this.cancellationReason,
  })  : id = id ?? const Uuid().v4(),
        qrCode = qrCode ?? const Uuid().v4(),
        reservedAt = reservedAt ?? DateTime.now();

  bool get isActive =>
      status == ReservationStatus.confirmed ||
      status == ReservationStatus.pending;

  bool get canBoard =>
      status == ReservationStatus.confirmed &&
      departureDate.difference(DateTime.now()).inHours < 2;

  Reservation copyWith({
    String? userId,
    String? busId,
    String? routeId,
    String? seatNumber,
    SeatType? seatType,
    ReservationStatus? status,
    String? qrCode,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    DateTime? boardedAt,
    String? departureTime,
    DateTime? departureDate,
    String? origin,
    String? destination,
    String? cancellationReason,
  }) {
    return Reservation(
      id: id,
      userId: userId ?? this.userId,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      seatNumber: seatNumber ?? this.seatNumber,
      seatType: seatType ?? this.seatType,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      reservedAt: reservedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      boardedAt: boardedAt ?? this.boardedAt,
      departureTime: departureTime ?? this.departureTime,
      departureDate: departureDate ?? this.departureDate,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'busId': busId,
        'routeId': routeId,
        'seatNumber': seatNumber,
        'seatType': seatType.name,
        'status': status.name,
        'qrCode': qrCode,
        'reservedAt': reservedAt.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
        'boardedAt': boardedAt?.toIso8601String(),
        'departureTime': departureTime,
        'departureDate': departureDate.toIso8601String(),
        'origin': origin,
        'destination': destination,
        'cancellationReason': cancellationReason,
      };

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'],
        userId: json['userId'],
        busId: json['busId'],
        routeId: json['routeId'],
        seatNumber: json['seatNumber'],
        seatType: SeatType.values.firstWhere(
          (t) => t.name == json['seatType'],
          orElse: () => SeatType.seated,
        ),
        status: ReservationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ReservationStatus.pending,
        ),
        qrCode: json['qrCode'],
        reservedAt: DateTime.parse(json['reservedAt']),
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'])
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'])
            : null,
        boardedAt: json['boardedAt'] != null
            ? DateTime.parse(json['boardedAt'])
            : null,
        departureTime: json['departureTime'],
        departureDate: DateTime.parse(json['departureDate']),
        origin: json['origin'],
        destination: json['destination'],
        cancellationReason: json['cancellationReason'],
      );
}
