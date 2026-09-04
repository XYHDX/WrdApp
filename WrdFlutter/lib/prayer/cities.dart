/// Offline city list — the fallback when location is off or denied.
/// Each city carries its ISO country code so the right convention is chosen.
class City {
  final String name;
  final String arabicName;
  final String countryCode;
  final double latitude;
  final double longitude;

  const City({
    required this.name,
    required this.arabicName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  static const List<City> all = [
    City(name: 'Damascus', arabicName: 'دمشق', countryCode: 'SY', latitude: 33.5138, longitude: 36.2765),
    City(name: 'Aleppo', arabicName: 'حلب', countryCode: 'SY', latitude: 36.2021, longitude: 37.1343),
    City(name: 'Homs', arabicName: 'حمص', countryCode: 'SY', latitude: 34.7324, longitude: 36.7137),
    City(name: 'Latakia', arabicName: 'اللاذقية', countryCode: 'SY', latitude: 35.5317, longitude: 35.7915),
    City(name: 'Amman', arabicName: 'عمّان', countryCode: 'JO', latitude: 31.9539, longitude: 35.9106),
    City(name: 'Beirut', arabicName: 'بيروت', countryCode: 'LB', latitude: 33.8938, longitude: 35.5018),
    City(name: 'Jerusalem', arabicName: 'القدس', countryCode: 'PS', latitude: 31.7683, longitude: 35.2137),
    City(name: 'Gaza', arabicName: 'غزة', countryCode: 'PS', latitude: 31.5017, longitude: 34.4668),
    City(name: 'Baghdad', arabicName: 'بغداد', countryCode: 'IQ', latitude: 33.3152, longitude: 44.3661),
    City(name: 'Cairo', arabicName: 'القاهرة', countryCode: 'EG', latitude: 30.0444, longitude: 31.2357),
    City(name: 'Alexandria', arabicName: 'الإسكندرية', countryCode: 'EG', latitude: 31.2001, longitude: 29.9187),
    City(name: 'Khartoum', arabicName: 'الخرطوم', countryCode: 'SD', latitude: 15.5007, longitude: 32.5599),
    City(name: 'Tripoli', arabicName: 'طرابلس', countryCode: 'LY', latitude: 32.8872, longitude: 13.1913),
    City(name: 'Tunis', arabicName: 'تونس', countryCode: 'TN', latitude: 36.8065, longitude: 10.1815),
    City(name: 'Algiers', arabicName: 'الجزائر', countryCode: 'DZ', latitude: 36.7538, longitude: 3.0588),
    City(name: 'Casablanca', arabicName: 'الدار البيضاء', countryCode: 'MA', latitude: 33.5731, longitude: -7.5898),
    City(name: 'Makkah', arabicName: 'مكة المكرمة', countryCode: 'SA', latitude: 21.4225, longitude: 39.8262),
    City(name: 'Madinah', arabicName: 'المدينة المنورة', countryCode: 'SA', latitude: 24.4672, longitude: 39.6111),
    City(name: 'Riyadh', arabicName: 'الرياض', countryCode: 'SA', latitude: 24.7136, longitude: 46.6753),
    City(name: 'Jeddah', arabicName: 'جدة', countryCode: 'SA', latitude: 21.4858, longitude: 39.1925),
    City(name: 'Dubai', arabicName: 'دبي', countryCode: 'AE', latitude: 25.2048, longitude: 55.2708),
    City(name: 'Abu Dhabi', arabicName: 'أبوظبي', countryCode: 'AE', latitude: 24.4539, longitude: 54.3773),
    City(name: 'Kuwait City', arabicName: 'الكويت', countryCode: 'KW', latitude: 29.3759, longitude: 47.9774),
    City(name: 'Doha', arabicName: 'الدوحة', countryCode: 'QA', latitude: 25.2854, longitude: 51.5310),
    City(name: 'Manama', arabicName: 'المنامة', countryCode: 'BH', latitude: 26.2285, longitude: 50.5860),
    City(name: 'Muscat', arabicName: 'مسقط', countryCode: 'OM', latitude: 23.5880, longitude: 58.3829),
    City(name: 'Sanaa', arabicName: 'صنعاء', countryCode: 'YE', latitude: 15.3694, longitude: 44.1910),
    City(name: 'Istanbul', arabicName: 'إسطنبول', countryCode: 'TR', latitude: 41.0082, longitude: 28.9784),
    City(name: 'Ankara', arabicName: 'أنقرة', countryCode: 'TR', latitude: 39.9334, longitude: 32.8597),
    City(name: 'Tehran', arabicName: 'طهران', countryCode: 'IR', latitude: 35.6892, longitude: 51.3890),
    City(name: 'Karachi', arabicName: 'كراتشي', countryCode: 'PK', latitude: 24.8607, longitude: 67.0011),
    City(name: 'Lahore', arabicName: 'لاهور', countryCode: 'PK', latitude: 31.5204, longitude: 74.3587),
    City(name: 'Delhi', arabicName: 'دلهي', countryCode: 'IN', latitude: 28.6139, longitude: 77.2090),
    City(name: 'Dhaka', arabicName: 'دكا', countryCode: 'BD', latitude: 23.8103, longitude: 90.4125),
    City(name: 'Kabul', arabicName: 'كابل', countryCode: 'AF', latitude: 34.5553, longitude: 69.2075),
    City(name: 'Kuala Lumpur', arabicName: 'كوالالمبور', countryCode: 'MY', latitude: 3.1390, longitude: 101.6869),
    City(name: 'Jakarta', arabicName: 'جاكرتا', countryCode: 'ID', latitude: -6.2088, longitude: 106.8456),
    City(name: 'Singapore', arabicName: 'سنغافورة', countryCode: 'SG', latitude: 1.3521, longitude: 103.8198),
    City(name: 'London', arabicName: 'لندن', countryCode: 'GB', latitude: 51.5074, longitude: -0.1278),
    City(name: 'Paris', arabicName: 'باريس', countryCode: 'FR', latitude: 48.8566, longitude: 2.3522),
    City(name: 'Berlin', arabicName: 'برلين', countryCode: 'DE', latitude: 52.5200, longitude: 13.4050),
    City(name: 'Stockholm', arabicName: 'ستوكهولم', countryCode: 'SE', latitude: 59.3293, longitude: 18.0686),
    City(name: 'Moscow', arabicName: 'موسكو', countryCode: 'RU', latitude: 55.7558, longitude: 37.6173),
    City(name: 'New York', arabicName: 'نيويورك', countryCode: 'US', latitude: 40.7128, longitude: -74.0060),
    City(name: 'Los Angeles', arabicName: 'لوس أنجلوس', countryCode: 'US', latitude: 34.0522, longitude: -118.2437),
    City(name: 'Toronto', arabicName: 'تورونتو', countryCode: 'CA', latitude: 43.6532, longitude: -79.3832),
    City(name: 'Sydney', arabicName: 'سيدني', countryCode: 'AU', latitude: -33.8688, longitude: 151.2093),
  ];

  static const City defaultCity = City(
    name: 'Damascus',
    arabicName: 'دمشق',
    countryCode: 'SY',
    latitude: 33.5138,
    longitude: 36.2765,
  );

  static City byName(String? name) {
    for (final c in all) {
      if (c.name == name) return c;
    }
    return defaultCity;
  }
}
