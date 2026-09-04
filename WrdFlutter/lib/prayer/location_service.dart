import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Where the user is — resolved once, kept on the device, never sent anywhere.
class ResolvedLocation {
  final double latitude;
  final double longitude;
  final String? countryCode; // ISO 3166-1 alpha-2, e.g. "SY"
  final String? placeName; // "دمشق" / "Damascus" as the platform returns it

  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    this.countryCode,
    this.placeName,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (countryCode != null) 'countryCode': countryCode,
        if (placeName != null) 'placeName': placeName,
      };

  factory ResolvedLocation.fromJson(Map<String, dynamic> json) => ResolvedLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        countryCode: json['countryCode'] as String?,
        placeName: json['placeName'] as String?,
      );
}

enum LocationOutcome { resolved, denied, unavailable }

class LocationService {
  LocationService._();

  /// Asks for permission (once) and resolves the device position to a
  /// coordinate + country. Reverse geocoding may need a network round-trip
  /// on some platforms; the coordinate alone is still returned if it fails.
  static Future<(LocationOutcome, ResolvedLocation?)> resolve() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (LocationOutcome.unavailable, null);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (LocationOutcome.denied, null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // a city is enough for prayer times
          timeLimit: Duration(seconds: 20),
        ),
      );

      String? countryCode;
      String? placeName;
      try {
        final marks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (marks.isNotEmpty) {
          final mark = marks.first;
          countryCode = mark.isoCountryCode;
          placeName = _firstNonEmpty([
            mark.locality,
            mark.subAdministrativeArea,
            mark.administrativeArea,
            mark.country,
          ]);
        }
      } catch (_) {
        // Offline or geocoder unavailable — coordinate still useful.
      }

      return (
        LocationOutcome.resolved,
        ResolvedLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          countryCode: countryCode,
          placeName: placeName,
        ),
      );
    } catch (_) {
      return (LocationOutcome.unavailable, null);
    }
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
