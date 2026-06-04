import 'package:equatable/equatable.dart';

class AcademyEntity extends Equatable {
  final String id;
  final String name;
  final String? logoUrl;
  final String phone;
  final String address;
  final DateTime createdAt;
  final int? playerCount;

  const AcademyEntity({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.phone,
    required this.address,
    required this.createdAt,
    this.playerCount,
  });

  @override
  List<Object?> get props => [id, name, logoUrl, phone, address, createdAt, playerCount];
}
