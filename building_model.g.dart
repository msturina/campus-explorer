// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'building_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Building _$BuildingFromJson(Map<String, dynamic> json) => Building(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$BuildingToJson(Building instance) => <String, dynamic>{
      'name': instance.name,
      'lat': instance.lat,
      'lng': instance.lng,
      'description': instance.description,
    };
