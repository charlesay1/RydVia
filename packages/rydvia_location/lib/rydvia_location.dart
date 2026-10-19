class Coordinates {
  Coordinates(this.latitude, this.longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid coordinates');
    }
  }
  final double latitude;
  final double longitude;
}

abstract interface class LocationRepository {
  /// Implement only after explicit OS permission; never request on app launch.
  Future<Coordinates> currentPosition();
}

enum MapAppearance { light, dark }

abstract interface class MapStyleAdapter {
  Future<void> setAppearance(MapAppearance appearance);
}
