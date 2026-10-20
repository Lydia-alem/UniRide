import 'package:uuid/uuid.dart';

class BusRoute {
  final String id;
  final String name;
  final String lineNumber;
  final List<String> stops;
  final String origin;
  final String destination;
  final List<String> departureTimes;
  final bool isActive;
  final int totalSeats;
  final bool standingAllowed;
  final int maxStanding;

  BusRoute({
    String? id,
    required this.name,
    required this.lineNumber,
    required this.stops,
    required this.origin,
    required this.destination,
    required this.departureTimes,
    this.isActive = true,
    this.totalSeats = 40,
    this.standingAllowed = false,
    this.maxStanding = 10,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lineNumber': lineNumber,
        'stops': stops,
        'origin': origin,
        'destination': destination,
        'departureTimes': departureTimes,
        'isActive': isActive,
        'totalSeats': totalSeats,
        'standingAllowed': standingAllowed,
        'maxStanding': maxStanding,
      };

  factory BusRoute.fromJson(Map<String, dynamic> json) => BusRoute(
        id: json['id'],
        name: json['name'],
        lineNumber: json['lineNumber'],
        stops: List<String>.from(json['stops']),
        origin: json['origin'],
        destination: json['destination'],
        departureTimes: List<String>.from(json['departureTimes']),
        isActive: json['isActive'] ?? true,
        totalSeats: json['totalSeats'] ?? 40,
        standingAllowed: json['standingAllowed'] ?? false,
        maxStanding: json['maxStanding'] ?? 10,
      );

  BusRoute copyWith({
    String? name,
    String? lineNumber,
    List<String>? stops,
    String? origin,
    String? destination,
    List<String>? departureTimes,
    bool? isActive,
    int? totalSeats,
    bool? standingAllowed,
    int? maxStanding,
  }) {
    return BusRoute(
      id: id,
      name: name ?? this.name,
      lineNumber: lineNumber ?? this.lineNumber,
      stops: stops ?? this.stops,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      departureTimes: departureTimes ?? this.departureTimes,
      isActive: isActive ?? this.isActive,
      totalSeats: totalSeats ?? this.totalSeats,
      standingAllowed: standingAllowed ?? this.standingAllowed,
      maxStanding: maxStanding ?? this.maxStanding,
    );
  }
}

class Bus {
  final String id;
  final String routeId;
  final String plateNumber;
  final String driverId;
  final String departureTime;
  final DateTime departureDate;
  final int totalSeats;
  final int bookedSeats;
  final int standingBooked;
  final bool standingAllowed;
  final int maxStanding;
  final bool isActive;
  final String status; // 'scheduled', 'boarding', 'en_route', 'arrived'

  Bus({
    String? id,
    required this.routeId,
    required this.plateNumber,
    required this.driverId,
    required this.departureTime,
    required this.departureDate,
    this.totalSeats = 40,
    this.bookedSeats = 0,
    this.standingBooked = 0,
    this.standingAllowed = false,
    this.maxStanding = 10,
    this.isActive = true,
    this.status = 'scheduled',
  }) : id = id ?? const Uuid().v4();

  int get availableSeats => totalSeats - bookedSeats;
  int get availableStanding => maxStanding - standingBooked;
  bool get isFull => availableSeats <= 0;
  double get occupancyRate => totalSeats > 0 ? bookedSeats / totalSeats : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeId': routeId,
        'plateNumber': plateNumber,
        'driverId': driverId,
        'departureTime': departureTime,
        'departureDate': departureDate.toIso8601String(),
        'totalSeats': totalSeats,
        'bookedSeats': bookedSeats,
        'standingBooked': standingBooked,
        'standingAllowed': standingAllowed,
        'maxStanding': maxStanding,
        'isActive': isActive,
        'status': status,
      };

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
        id: json['id'],
        routeId: json['routeId'],
        plateNumber: json['plateNumber'],
        driverId: json['driverId'],
        departureTime: json['departureTime'],
        departureDate: DateTime.parse(json['departureDate']),
        totalSeats: json['totalSeats'] ?? 40,
        bookedSeats: json['bookedSeats'] ?? 0,
        standingBooked: json['standingBooked'] ?? 0,
        standingAllowed: json['standingAllowed'] ?? false,
        maxStanding: json['maxStanding'] ?? 10,
        isActive: json['isActive'] ?? true,
        status: json['status'] ?? 'scheduled',
      );

  Bus copyWith({
    String? routeId,
    String? plateNumber,
    String? driverId,
    String? departureTime,
    DateTime? departureDate,
    int? totalSeats,
    int? bookedSeats,
    int? standingBooked,
    bool? standingAllowed,
    int? maxStanding,
    bool? isActive,
    String? status,
  }) {
    return Bus(
      id: id,
      routeId: routeId ?? this.routeId,
      plateNumber: plateNumber ?? this.plateNumber,
      driverId: driverId ?? this.driverId,
      departureTime: departureTime ?? this.departureTime,
      departureDate: departureDate ?? this.departureDate,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      standingBooked: standingBooked ?? this.standingBooked,
      standingAllowed: standingAllowed ?? this.standingAllowed,
      maxStanding: maxStanding ?? this.maxStanding,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
    );
  }
}
