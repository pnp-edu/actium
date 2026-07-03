import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── MODELOS DE RESPUESTA DE DNI ─────────────────────────────────────────────
class DniResponse {
  final bool success;
  final String message;
  final DniResultado? resultado;

  DniResponse({
    required this.success,
    required this.message,
    this.resultado,
  });

  bool get estado => success;
  String get mensaje => message;

  factory DniResponse.fromJson(Map<String, dynamic> json) {
    final isSuccess = json['success'] ?? false;
    return DniResponse(
      success: isSuccess,
      message: json['message'] ?? '',
      resultado: isSuccess && json['data'] != null
          ? DniResultado.fromJson(json['data'])
          : null,
    );
  }
}

class DniResultado {
  final String id;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String nombreCompleto;
  final String genero;
  final String fechaNacimiento;
  final String codigoVerificacion;
  final String departamento;
  final String provincia;
  final String distrito;
  final String direccion;
  final String direccionCompleta;
  final String nacionalidad;

  DniResultado({
    required this.id,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nombreCompleto,
    required this.genero,
    required this.fechaNacimiento,
    required this.codigoVerificacion,
    required this.departamento,
    required this.provincia,
    required this.distrito,
    required this.direccion,
    required this.direccionCompleta,
    required this.nacionalidad,
  });

  factory DniResultado.fromJson(Map<String, dynamic> json) {
    final rawNumero = json['numero'] ?? '';
    final rawNombres = json['nombres'] ?? '';
    final rawPaterno = json['apellido_paterno'] ?? '';
    final rawMaterno = json['apellido_materno'] ?? '';
    final rawNombreCompleto = json['nombre_completo'] ?? '';
    final rawSexo = json['sexo'] ?? '';
    final rawNacimiento = json['fecha_nacimiento'] ?? '';
    final rawDepartamento = json['departamento'] ?? '';
    final rawProvincia = json['provincia'] ?? '';
    final rawDistrito = json['distrito'] ?? '';
    final rawDireccion = json['direccion'] ?? '';
    final rawDireccionCompleta = json['direccion_completa'] ?? '';

    // Reformat name to "Nombres ApellidoPaterno ApellidoMaterno"
    String finalNombreCompleto = '';
    if (rawNombres.isNotEmpty && rawPaterno.isNotEmpty) {
      finalNombreCompleto = "$rawNombres $rawPaterno $rawMaterno".trim().replaceAll(RegExp(r'\s+'), ' ');
    } else if (rawNombreCompleto.contains(',')) {
      final parts = rawNombreCompleto.split(',');
      if (parts.length == 2) {
        finalNombreCompleto = "${parts[1].trim()} ${parts[0].trim()}";
      } else {
        finalNombreCompleto = rawNombreCompleto;
      }
    } else {
      finalNombreCompleto = rawNombreCompleto;
    }

    // Reformat fecha_nacimiento from YYYY-MM-DD to DD/MM/YYYY
    String finalFechaNacimiento = '';
    if (rawNacimiento.isNotEmpty) {
      try {
        if (rawNacimiento.contains('-')) {
          final parts = rawNacimiento.split('-');
          if (parts.length == 3) {
            finalFechaNacimiento = "${parts[2]}/${parts[1]}/${parts[0]}";
          } else {
            finalFechaNacimiento = rawNacimiento;
          }
        } else {
          finalFechaNacimiento = rawNacimiento;
        }
      } catch (_) {
        finalFechaNacimiento = rawNacimiento;
      }
    }

    // Map genero: MASCULINO/FEMENINO to M/F
    String finalGenero = '';
    if (rawSexo.isNotEmpty) {
      final upperSexo = rawSexo.toUpperCase();
      if (upperSexo.startsWith('M')) {
        finalGenero = 'M';
      } else if (upperSexo.startsWith('F')) {
        finalGenero = 'F';
      } else {
        finalGenero = rawSexo;
      }
    }

    return DniResultado(
      id: rawNumero,
      nombres: rawNombres,
      apellidoPaterno: rawPaterno,
      apellidoMaterno: rawMaterno,
      nombreCompleto: finalNombreCompleto,
      genero: finalGenero,
      fechaNacimiento: finalFechaNacimiento,
      codigoVerificacion: '',
      departamento: rawDepartamento,
      provincia: rawProvincia,
      distrito: rawDistrito,
      direccion: rawDireccion,
      direccionCompleta: rawDireccionCompleta,
      nacionalidad: 'PERUANA',
    );
  }
}

// ─── MODELOS DE RESPUESTA DE PLACA ───────────────────────────────────────────
class PlacaResponse {
  final bool success;
  final String message;
  final PlacaResultado? resultado;

  PlacaResponse({
    required this.success,
    required this.message,
    this.resultado,
  });

  bool get estado => success;
  String get mensaje => message;

  factory PlacaResponse.fromJson(Map<String, dynamic> json) {
    final isSuccess = json['success'] ?? false;
    return PlacaResponse(
      success: isSuccess,
      message: json['message'] ?? '',
      resultado: isSuccess && json['data'] != null
          ? PlacaResultado.fromJson(json['data'])
          : null,
    );
  }
}

class PlacaResultado {
  final String placa;
  final String marca;
  final String modelo;
  final String serie;
  final String color;
  final String motor;
  final String vin;

  PlacaResultado({
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.serie,
    required this.color,
    required this.motor,
    required this.vin,
  });

  factory PlacaResultado.fromJson(Map<String, dynamic> json) {
    return PlacaResultado(
      placa: json['placa'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      serie: json['serie'] ?? '',
      color: json['color'] ?? '',
      motor: json['motor'] ?? '',
      vin: json['vin'] ?? '',
    );
  }
}

// ─── MODELOS DE RESPUESTA DE CARNET DE EXTRANJERÍA (CEE) ──────────────────────
class CeResponse {
  final bool success;
  final String message;
  final CeResultado? resultado;

  CeResponse({
    required this.success,
    required this.message,
    this.resultado,
  });

  bool get estado => success;
  String get mensaje => message;

  factory CeResponse.fromJson(Map<String, dynamic> json) {
    final isSuccess = json['success'] ?? false;
    return CeResponse(
      success: isSuccess,
      message: json['message'] ?? '',
      resultado: isSuccess && json['data'] != null
          ? CeResultado.fromJson(json['data'])
          : null,
    );
  }
}

class CeResultado {
  final String numero;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;

  CeResultado({
    required this.numero,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
  });

  factory CeResultado.fromJson(Map<String, dynamic> json) {
    return CeResultado(
      numero: json['numero'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidoPaterno: json['apellido_paterno'] ?? '',
      apellidoMaterno: json['apellido_materno'] ?? '',
    );
  }
}

// ─── SERVICIO DE CONSULTAS FACTILIZA ─────────────────────────────────────────
class DniService {
  static const String _apiKeyPrefsKey = 'factiliza_api_token';
  static const String _defaultFactilizaKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI0MTE5NSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6ImNvbnN1bHRvciJ9.Utpytbk8yMUZdPC39vjmDRKMxgiVDblYplnUH8ZXriE';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_apiKeyPrefsKey);
    if (saved == null || saved.isEmpty) {
      return _defaultFactilizaKey;
    }
    return saved;
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, key);
  }

  // Consulta DNI
  Future<DniResponse> consultarDni(String document, String key) async {
    if (document.length != 8 || int.tryParse(document) == null) {
      return DniResponse(success: false, message: 'El DNI debe tener exactamente 8 dígitos numéricos.');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'dni_cache_$document';
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        final Map<String, dynamic> decoded = json.decode(cachedJson);
        return DniResponse.fromJson(decoded);
      }
    } catch (_) {}

    final effectiveKey = key.trim().isEmpty ? _defaultFactilizaKey : key;
    if (effectiveKey.trim().isEmpty) {
      return DniResponse(success: false, message: 'Se requiere un Token/API Key de Factiliza.');
    }

    try {
      final url = Uri.parse('https://api.factiliza.com/v1/dni/info/$document');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $effectiveKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> decoded = json.decode(responseBody);
        final isSuccess = decoded['success'] ?? false;
        if (isSuccess && decoded['data'] != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('dni_cache_$document', responseBody);
          } catch (_) {}
        }
        return DniResponse.fromJson(decoded);
      } else {
        String errMsg = 'Error de servidor: código ${response.statusCode}';
        try {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded['message'] != null) {
            errMsg = decoded['message'];
          }
        } catch (_) {}
        return DniResponse(success: false, message: errMsg);
      }
    } catch (e) {
      return DniResponse(success: false, message: 'Error al conectar con el servicio: $e');
    }
  }

  // Consulta Placa
  Future<PlacaResponse> consultarPlaca(String placa, String key) async {
    final cleanPlaca = placa.replaceAll('-', '').trim();
    if (cleanPlaca.isEmpty) {
      return PlacaResponse(success: false, message: 'Ingresa un número de placa válido.');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'placa_cache_$cleanPlaca';
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        final Map<String, dynamic> decoded = json.decode(cachedJson);
        return PlacaResponse.fromJson(decoded);
      }
    } catch (_) {}

    final effectiveKey = key.trim().isEmpty ? _defaultFactilizaKey : key;
    if (effectiveKey.trim().isEmpty) {
      return PlacaResponse(success: false, message: 'Se requiere un Token/API Key de Factiliza.');
    }

    try {
      final url = Uri.parse('https://api.factiliza.com/v1/placa/info/$cleanPlaca');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $effectiveKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> decoded = json.decode(responseBody);
        final isSuccess = decoded['success'] ?? false;
        if (isSuccess && decoded['data'] != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('placa_cache_$cleanPlaca', responseBody);
          } catch (_) {}
        }
        return PlacaResponse.fromJson(decoded);
      } else {
        String errMsg = 'Error de servidor: código ${response.statusCode}';
        try {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded['message'] != null) {
            errMsg = decoded['message'];
          }
        } catch (_) {}
        return PlacaResponse(success: false, message: errMsg);
      }
    } catch (e) {
      return PlacaResponse(success: false, message: 'Error al conectar con el servicio: $e');
    }
  }

  // Consulta Carnet de Extranjería (CEE)
  Future<CeResponse> consultarCe(String cee, String key) async {
    final cleanCe = cee.trim();
    if (cleanCe.isEmpty) {
      return CeResponse(success: false, message: 'Ingresa un número de CE válido.');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'ce_cache_$cleanCe';
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        final Map<String, dynamic> decoded = json.decode(cachedJson);
        return CeResponse.fromJson(decoded);
      }
    } catch (_) {}

    final effectiveKey = key.trim().isEmpty ? _defaultFactilizaKey : key;
    if (effectiveKey.trim().isEmpty) {
      return CeResponse(success: false, message: 'Se requiere un Token/API Key de Factiliza.');
    }

    try {
      final url = Uri.parse('https://api.factiliza.com/v1/cee/info/$cleanCe');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $effectiveKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> decoded = json.decode(responseBody);
        final isSuccess = decoded['success'] ?? false;
        if (isSuccess && decoded['data'] != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ce_cache_$cleanCe', responseBody);
          } catch (_) {}
        }
        return CeResponse.fromJson(decoded);
      } else {
        String errMsg = 'Error de servidor: código ${response.statusCode}';
        try {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          if (decoded['message'] != null) {
            errMsg = decoded['message'];
          }
        } catch (_) {}
        return CeResponse(success: false, message: errMsg);
      }
    } catch (e) {
      return CeResponse(success: false, message: 'Error al conectar con el servicio: $e');
    }
  }
}
