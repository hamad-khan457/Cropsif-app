import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/parcel_model.dart';

class ParcelRepository {
  final _api = ApiService();

  Future<List<ParcelModel>> getMyParcels() async {
    final res  = await _api.authGet(ApiConstants.parcels);
    final data = res['data'] as Map<String, dynamic>;
    final list = data['parcels'] as List;
    return list.map((j) => ParcelModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<ParcelModel> getParcel(String id) async {
    final res  = await _api.authGet(ApiConstants.parcel(id));
    final data = res['data'] as Map<String, dynamic>;
    return ParcelModel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  Future<ParcelModel> createParcel({
    required String name,
    String? location,
    double? areaAcres,
    String? soilType,
    double? phLevel,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    String? irrigation,
    List<LatLng> coordinates = const [],
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (location   != null) 'location':   location,
      if (areaAcres  != null) 'areaAcres':  areaAcres,
      if (soilType   != null) 'soilType':   soilType,
      if (phLevel    != null) 'phLevel':    phLevel,
      if (nitrogen   != null) 'nitrogen':   nitrogen,
      if (phosphorus != null) 'phosphorus': phosphorus,
      if (potassium  != null) 'potassium':  potassium,
      if (irrigation != null) 'irrigation': irrigation,
      'coordinates': coordinates.map((c) => {'lat': c.latitude, 'lng': c.longitude}).toList(),
    };
    final res  = await _api.authPost(ApiConstants.parcels, body);
    final data = res['data'] as Map<String, dynamic>;
    return ParcelModel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  Future<ParcelModel> updateParcel(String id, Map<String, dynamic> fields) async {
    final res  = await _api.authPatch(ApiConstants.parcel(id), fields);
    final data = res['data'] as Map<String, dynamic>;
    return ParcelModel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  Future<void> deleteParcel(String id) async {
    await _api.authDelete(ApiConstants.parcel(id), {});
  }
}
