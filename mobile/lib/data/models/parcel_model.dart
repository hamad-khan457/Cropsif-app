import 'package:latlong2/latlong.dart';

class ParcelModel {
  final String  id;
  final String  name;
  final String? location;
  final double? areaAcres;
  final String? soilType;
  final double? phLevel;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final String? irrigation;
  final List<LatLng> coordinates;
  final String? activeCrop;
  final double? ndviScore;
  final bool    isActive;
  final String? managerName;
  final DateTime createdAt;

  const ParcelModel({
    required this.id,
    required this.name,
    this.location,
    this.areaAcres,
    this.soilType,
    this.phLevel,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.irrigation,
    this.coordinates = const [],
    this.activeCrop,
    this.ndviScore,
    this.isActive = true,
    this.managerName,
    required this.createdAt,
  });

  factory ParcelModel.fromJson(Map<String, dynamic> j) {
    final rawCoords = j['coordinates'];
    List<LatLng> coords = [];
    if (rawCoords is List) {
      coords = rawCoords
          .whereType<Map>()
          .map((c) => LatLng(
                _d(c['lat'])!,
                _d(c['lng'])!,
              ))
          .toList();
    }

    return ParcelModel(
      id:          j['id']          as String,
      name:        j['name']        as String,
      location:    j['location']    as String?,
      areaAcres:   _d(j['area_acres']),
      soilType:    j['soil_type']   as String?,
      phLevel:     _d(j['ph_level']),
      nitrogen:    _d(j['nitrogen']),
      phosphorus:  _d(j['phosphorus']),
      potassium:   _d(j['potassium']),
      irrigation:  j['irrigation']  as String?,
      coordinates: coords,
      activeCrop:   j['active_crop']  as String?,
      ndviScore:    _d(j['ndvi_score']),
      isActive:     j['is_active']    as bool? ?? true,
      managerName:  j['manager_name'] as String?,
      createdAt:    DateTime.parse(j['created_at'] as String),
    );
  }

  // PostgreSQL DECIMAL/NUMERIC columns come back as strings via the pg driver.
  // This helper safely parses both num and String to double.
  static double? _d(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  /// NDVI badge colour
  NdviBadge get ndviBadge {
    if (ndviScore == null) return NdviBadge.unknown;
    if (ndviScore! >= 0.6) return NdviBadge.healthy;
    if (ndviScore! >= 0.4) return NdviBadge.moderate;
    return NdviBadge.stressed;
  }
}

enum NdviBadge { healthy, moderate, stressed, unknown }
