import 'dart:math' as math;

/// Jarak lingkaran besar (Haversine) dalam kilometer.
double jarakKm(double lat1, double lng1, double lat2, double lng2) {
  const radiusBumi = 6371.0088;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * radiusBumi * math.asin(math.min(1, math.sqrt(a)));
}

/// "850 m", "4,2 km", "128 km" (format Indonesia: koma desimal).
String formatJarak(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}
