import 'package:json_annotation/json_annotation.dart';

part 'building_model.g.dart'; // This will be generated later

@JsonSerializable()
class Building {
  final String name;
  final double lat;
  final double lng;
  final String description;

  Building({required this.name, required this.lat, required this.lng, required this.description});

  factory Building.fromJson(Map<String, dynamic> json) => _$BuildingFromJson(json);
  Map<String, dynamic> toJson() => _$BuildingToJson(this);
}