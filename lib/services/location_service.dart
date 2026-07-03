import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PoliceStationInfo {
  final String name;
  final double distanceKm;
  final double? latitude;
  final double? longitude;

  PoliceStationInfo({
    required this.name,
    required this.distanceKm,
    this.latitude,
    this.longitude,
  });
}

class LocationResult {
  final String city;
  final List<PoliceStationInfo> nearbyStations;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.city,
    required this.nearbyStations,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static final List<String> fallbackStations = [
    'COMISARÍA PNP MIRAFLORES',
    'COMISARÍA PNP SAN ISIDRO',
    'COMISARÍA PNP BARRANCO',
    'COMISARÍA PNP SANTIAGO DE SURCO',
    'COMISARÍA PNP CHORRILLOS',
    'COMISARÍA PNP SAN BORJA',
    'COMISARÍA PNP SURQUILLO',
    'COMISARÍA PNP LINCE',
    'COMISARÍA PNP SAN MIGUEL',
    'COMISARÍA PNP MAGDALENA DEL MAR',
    'COMISARÍA PNP LA MOLINA',
    'COMISARÍA PNP ATE',
    'COMISARÍA PNP SANTA ANITA',
    'COMISARÍA PNP SAN JUAN DE LURIGANCHO',
    'COMISARÍA PNP SAN MARTÍN DE PORRES',
    'COMISARÍA PNP COMAS',
    'COMISARÍA PNP LOS OLIVOS',
    'COMISARÍA PNP INDEPENDENCIA',
    'COMISARÍA PNP CALLAO',
    'COMISARÍA PNP BELLAVISTA',
    'COMISARÍA PNP LA PERLA',
    'COMISARÍA PNP CARABAYLLO',
    'COMISARÍA PNP PUENTE PIEDRA',
    'COMISARÍA PNP CERCADO DE LIMA',
    'COMISARÍA PNP ALFONSO UGARTE',
    'COMISARÍA PNP COTABAMBAS',
    'COMISARÍA PNP PETIT THOUARS',
    'COMISARÍA PNP CHACLACAYO',
    'COMISARÍA PNP LURÍN',
    'COMISARÍA PNP CHOSICA'
  ];

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const r = 6371; // Radio de la Tierra en km
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 2 * r * asin(sqrt(a));
  }

  /// Obtiene la ubicación y datos geográficos del operador (ciudad y comisarías PNP cercanas).
  static Future<LocationResult> getOperatorLocationData() async {
    // 1. Verificar si el servicio está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de localización está desactivado en el sistema.');
    }

    // 2. Verificar y solicitar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos de ubicación están denegados permanentemente.');
    }

    // 3. Obtener coordenadas con timeout de 8 segundos
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );

    final double lat = position.latitude;
    final double lng = position.longitude;

    // 4. Intentar obtener ciudad actual vía Nominatim API (OpenStreetMap)
    String detectedCity = 'LIMA';
    try {
      final reverseGeocodingUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1'
      );
      final response = await http.get(
        reverseGeocodingUrl,
        headers: {'User-Agent': 'ActiumPNPApp/1.0 (operator-profile)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final rawCity = address['city'] ?? 
                           address['town'] ?? 
                           address['village'] ?? 
                           address['county'] ?? 
                           address['state'] ?? 
                           'LIMA';
          detectedCity = rawCity.toString().toUpperCase().trim();
        }
      }
    } catch (_) {
      // Ignorar fallos de red y usar default
    }

    // 5. Intentar obtener comisarías cercanas vía Overpass API (OpenStreetMap)
    List<PoliceStationInfo> nearbyStations = [];
    try {
      final overpassUrl = Uri.parse('https://overpass-api.de/api/interpreter');
      // Buscamos comisarías (amenity=police) en un radio de 5km
      final query = '''
        [out:json][timeout:8];
        (
          node["amenity"="police"](around:5000, $lat, $lng);
          way["amenity"="police"](around:5000, $lat, $lng);
        );
        out body center;
      ''';

      final response = await http.post(
        overpassUrl,
        body: query,
        headers: {'User-Agent': 'ActiumPNPApp/1.0 (operator-profile)'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];

        for (var item in elements) {
          final tags = item['tags'];
          if (tags != null && tags['name'] != null) {
            String name = tags['name'].toString().toUpperCase().trim();
            // Asegurarnos de que tenga "COMISARÍA" o "PNP" para dar contexto oficial
            if (!name.contains('COMISARÍA') && !name.contains('COMISARIA')) {
              name = 'COMISARÍA PNP $name';
            }

            // Coordenadas
            double? itemLat;
            double? itemLng;
            if (item['type'] == 'node') {
              itemLat = item['lat'];
              itemLng = item['lon'];
            } else if (item['center'] != null) {
              itemLat = item['center']['lat'];
              itemLng = item['center']['lon'];
            }

            double dist = 0.0;
            if (itemLat != null && itemLng != null) {
              dist = _calculateDistance(lat, lng, itemLat, itemLng);
            }

            nearbyStations.add(PoliceStationInfo(
              name: name,
              distanceKm: dist,
              latitude: itemLat,
              longitude: itemLng,
            ));
          }
        }

        // Ordenar por distancia
        nearbyStations.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }
    } catch (_) {
      // Ignorar fallos de red
    }

    // 6. Si no se detectaron comisarías de Overpass, generar fallback
    if (nearbyStations.isEmpty) {
      // Usar la lista precargada con distancias ficticias o simbólicas
      nearbyStations = fallbackStations.map((stationName) {
        return PoliceStationInfo(
          name: stationName,
          distanceKm: 0.0, // Indefinido
        );
      }).toList();
    }

    return LocationResult(
      city: detectedCity,
      nearbyStations: nearbyStations,
      latitude: lat,
      longitude: lng,
    );
  }
}
