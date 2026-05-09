import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../data/repositories/parcel_repository.dart';
import '../data/models/parcel_model.dart';

class ParcelProvider extends ChangeNotifier {
  final _repo = ParcelRepository();

  List<ParcelModel> _parcels = [];
  bool    _loading = false;
  String? _error;

  List<ParcelModel> get parcels => _parcels;
  bool              get loading => _loading;
  String?           get error   => _error;

  void _setLoading(bool v) { _loading = v; _error = null; notifyListeners(); }
  void _setError(dynamic e) { _loading = false; _error = e.toString(); notifyListeners(); }

  Future<void> loadParcels() async {
    _setLoading(true);
    try {
      _parcels = await _repo.getMyParcels();
      _loading = false;
      notifyListeners();
    } catch (e) { _setError(e); }
  }

  Future<ParcelModel?> createParcel({
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
    _setLoading(true);
    try {
      final parcel = await _repo.createParcel(
        name: name, location: location, areaAcres: areaAcres,
        soilType: soilType, phLevel: phLevel, nitrogen: nitrogen,
        phosphorus: phosphorus, potassium: potassium,
        irrigation: irrigation, coordinates: coordinates,
      );
      _parcels.insert(0, parcel);
      _loading = false;
      notifyListeners();
      return parcel;
    } catch (e) { _setError(e); return null; }
  }

  Future<bool> deleteParcel(String id) async {
    _setLoading(true);
    try {
      await _repo.deleteParcel(id);
      _parcels.removeWhere((p) => p.id == id);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) { _setError(e); return false; }
  }

  void clearError() { _error = null; notifyListeners(); }
}
