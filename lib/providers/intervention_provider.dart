import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/intervention_session.dart';
import '../services/intervention_service.dart';
import '../models/manifestacion.dart';
import '../models/registro_personal.dart';
import '../models/default_templates.dart';
import '../services/pdf_service.dart';
import '../services/empaquetador_service.dart';
import '../services/ai_tactical_service.dart';
import '../widgets/export_config_dialog.dart';
import '../services/dni_service.dart';


import 'package:shared_preferences/shared_preferences.dart';

class InterventionProvider extends ChangeNotifier {
  InterventionSession? _currentSession;
  String? _currentTypificationName;
  Map<String, String> _sharedTags = {};
  final Map<String, bool> _conditions = {
    'VEHICULO': false,
    'FISCAL': true,
    'DETENIDO': true,
    'COMISARIA': false,
    'ACOMPANANTE': false,
    'MENOR': false,
    'EXTRANJERO': false,
    'HERIDO': false,
  };
  List<SavedSession> _savedSessions = [];
  Set<String> _pinnedIds = {};
  ManifestacionData _manifestacionData = ManifestacionData();
  RegistroPersonalData _registroPersonalData = RegistroPersonalData();
  int _assistantStep = 0;

  String _operatorName = '';
  String _operatorFirstSurname = '';
  String _operatorSecondSurname = '';
  String _operatorGrade = '';
  String _operatorCip = '';
  String _operatorUnit = '';
  String _operatorCity = '';

  final InterventionService _service = InterventionService();

  InterventionProvider() {
    loadSavedSessions();
  }

  InterventionSession? get currentSession => _currentSession;
  String? get currentTypificationName => _currentTypificationName;
  Map<String, String> get sharedTags => Map.unmodifiable(_sharedTags);
  List<SavedSession> get savedSessions => _savedSessions;
  Set<String> get pinnedIds => _pinnedIds;
  ManifestacionData get manifestacionData => _manifestacionData;
  RegistroPersonalData get registroPersonalData => _registroPersonalData;
  String get operatorUnit => _operatorUnit;
  int get assistantStep => _assistantStep;

  void updateAssistantStep(int step) {
    _assistantStep = step;
    notifyListeners();
    saveCurrentSession();
  }

  void updateManifestacionData(ManifestacionData data) {
    _manifestacionData = data;
    notifyListeners();
  }

  void updateRegistroPersonalData(RegistroPersonalData data) {
    _registroPersonalData = data;
    notifyListeners();
  }

  Future<void> loadSavedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    _pinnedIds = (prefs.getStringList('pinned_sessions') ?? []).toSet();
    
    _operatorName = prefs.getString('operator_name') ?? '';
    _operatorFirstSurname = prefs.getString('operator_first_surname') ?? '';
    _operatorSecondSurname = prefs.getString('operator_second_surname') ?? '';
    _operatorGrade = prefs.getString('operator_grade') ?? '';
    _operatorCip = prefs.getString('operator_cip') ?? '';
    _operatorUnit = prefs.getString('operator_unit') ?? '';

    final all = await _service.loadAll();
    all.sort((a, b) {
      final aPinned = _pinnedIds.contains(a.id);
      final bPinned = _pinnedIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return b.savedAt.compareTo(a.savedAt);
    });
    _savedSessions = all;
    notifyListeners();
  }

  Future<void> reloadOperatorInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final oldName = _operatorName;
    final oldFirst = _operatorFirstSurname;
    final oldSecond = _operatorSecondSurname;
    final oldGrade = _operatorGrade;
    final oldCip = _operatorCip;
    final oldUnit = _operatorUnit;
    final oldCity = _operatorCity;

    _operatorName = prefs.getString('operator_name') ?? '';
    _operatorFirstSurname = prefs.getString('operator_first_surname') ?? '';
    _operatorSecondSurname = prefs.getString('operator_second_surname') ?? '';
    _operatorGrade = prefs.getString('operator_grade') ?? '';
    _operatorCip = prefs.getString('operator_cip') ?? '';
    _operatorUnit = prefs.getString('operator_unit') ?? '';
    _operatorCity = prefs.getString('operator_city') ?? '';

    // Update active session tags if they match old values, are empty, or use default placeholders
    if (_currentSession != null) {
      final oldCombined = '$oldGrade $oldFirst $oldSecond $oldName'.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
      final newGrade = _operatorGrade.toUpperCase().trim();
      final newSurnames = '${_operatorFirstSurname.toUpperCase()} ${_operatorSecondSurname.toUpperCase()}'.trim();
      final newNames = _operatorName.toUpperCase().trim();
      final newCombined = '$newGrade $newSurnames $newNames'.trim().replaceAll(RegExp(r'\s+'), ' ');

      final currentInstName = _sharedTags['[instructor.grado_nombres]'] ?? '';
      if (currentInstName.isEmpty || currentInstName == oldCombined || currentInstName == '_______________') {
        if (newCombined.isNotEmpty) {
          _sharedTags['[instructor.grado_nombres]'] = newCombined;
        }
      }

      final currentCip = _sharedTags['[instructor.cip]'] ?? '';
      if (currentCip.isEmpty || currentCip == oldCip.toUpperCase() || currentCip == '_______________') {
        if (_operatorCip.isNotEmpty) {
          _sharedTags['[instructor.cip]'] = _operatorCip.toUpperCase();
        }
      }

      final currentLugar = _sharedTags['[acta.lugar_redaccion]'] ?? '';
      if (currentLugar.isEmpty || currentLugar == oldUnit.toUpperCase() || currentLugar == '_______________') {
        if (_operatorUnit.isNotEmpty) {
          _sharedTags['[acta.lugar_redaccion]'] = _operatorUnit.toUpperCase();
        }
      }

      final currentCity = _sharedTags['[lugar.provincia]'] ?? '';
      if (currentCity.isEmpty || currentCity == oldCity.toUpperCase() || currentCity == '_______________') {
        if (_operatorCity.isNotEmpty) {
          _sharedTags['[lugar.provincia]'] = _operatorCity.toUpperCase();
        }
      }
    }

    notifyListeners();
  }

  Future<void> togglePinSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (_pinnedIds.contains(id)) {
      _pinnedIds.remove(id);
    } else {
      _pinnedIds.add(id);
    }
    await prefs.setStringList('pinned_sessions', _pinnedIds.toList());
    await loadSavedSessions();
  }

  void _prepopulateOperatorInfo() {
    final grade = _operatorGrade.toUpperCase().trim();
    final surnames = '${_operatorFirstSurname.toUpperCase()} ${_operatorSecondSurname.toUpperCase()}'.trim();
    final names = _operatorName.toUpperCase().trim();
    final combined = '$grade $surnames $names'.trim();
    if (combined.isNotEmpty) {
      _sharedTags['[instructor.grado_nombres]'] = combined;
    }
    if (_operatorCip.isNotEmpty) {
      _sharedTags['[instructor.cip]'] = _operatorCip.toUpperCase();
    }
    if (_operatorUnit.isNotEmpty) {
      _sharedTags['[acta.lugar_redaccion]'] = _operatorUnit.toUpperCase();
    }
    if (_operatorCity.isNotEmpty) {
      _sharedTags['[lugar.provincia]'] = _operatorCity.toUpperCase();
    }
  }

  void startNewSession(InterventionSession session, {String? typificationName, bool conDetenido = true}) {
    _currentSession = session;
    _currentTypificationName = typificationName;
    _sharedTags = {};
    _sharedTags['[intervencion.con_detenido]'] = conDetenido ? 'SI' : 'NO';
    _prepopulateOperatorInfo();
    _manifestacionData = ManifestacionData();
    _registroPersonalData = RegistroPersonalData();
    _assistantStep = 0;
    notifyListeners();
  }

  void resumeSession(SavedSession saved, List<InterventionDocument> docs) {
    _currentSession = InterventionSession(
      id: saved.id,
      name: saved.name,
      typificationId: saved.typificationId,
      documents: docs,
    );
    _currentTypificationName = saved.typificationName;
    _sharedTags = Map.from(saved.tagValues);
    _assistantStep = saved.assistantStep;
    
    // If the resumed session does not have operator tags, pre-populate them
    if ((_sharedTags['[instructor.grado_nombres]'] ?? '').isEmpty) {
      final grade = _operatorGrade.toUpperCase().trim();
      final surnames = '${_operatorFirstSurname.toUpperCase()} ${_operatorSecondSurname.toUpperCase()}'.trim();
      final names = _operatorName.toUpperCase().trim();
      final combined = '$grade $surnames $names'.trim();
      if (combined.isNotEmpty) {
        _sharedTags['[instructor.grado_nombres]'] = combined;
      }
    }
    if ((_sharedTags['[instructor.cip]'] ?? '').isEmpty && _operatorCip.isNotEmpty) {
      _sharedTags['[instructor.cip]'] = _operatorCip.toUpperCase();
    }
    if ((_sharedTags['[acta.lugar_redaccion]'] ?? '').isEmpty && _operatorUnit.isNotEmpty) {
      _sharedTags['[acta.lugar_redaccion]'] = _operatorUnit.toUpperCase();
    }
    if ((_sharedTags['[lugar.provincia]'] ?? '').isEmpty && _operatorCity.isNotEmpty) {
      _sharedTags['[lugar.provincia]'] = _operatorCity.toUpperCase();
    }

    _manifestacionData = saved.manifestacionData ?? ManifestacionData();
    _registroPersonalData = saved.registroPersonalData ?? RegistroPersonalData();
    _syncBienesTags();
    notifyListeners();
  }

  void startExpressSession(String typificationName, List<String> documentTitles) {
    List<InterventionDocument> documents = documentTitles.map((title) {
      return InterventionDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString() + title.hashCode.toString(),
        title: title,
        content: DefaultTemplates.getFallbackContent(title),
      );
    }).toList();

    _currentSession = InterventionSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: typificationName,
      documents: documents,
    );
    _currentTypificationName = typificationName;
    _sharedTags = {};
    _sharedTags['[intervencion.con_detenido]'] = 'SI';
    _prepopulateOperatorInfo();
    _manifestacionData = ManifestacionData();
    _registroPersonalData = RegistroPersonalData();
    _assistantStep = 0;
    _syncBienesTags();
    notifyListeners();
  }

  void updateTagValue(String tag, String value) {
    _sharedTags[tag] = value;
    
    // Sincronización bidireccional de nombres
    if (tag == '[imputado.nombres_apellidos]') {
      final parts = value.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final surnames = parts.sublist(parts.length - 2).join(' ');
        final names = parts.sublist(0, parts.length - 2).join(' ');
        _sharedTags['[imputado.nombres]'] = names;
        _sharedTags['[imputado.apellidos]'] = surnames;
      } else {
        _sharedTags['[imputado.nombres]'] = value;
        _sharedTags['[imputado.apellidos]'] = '';
      }
    } else if (tag == '[imputado.nombres]' || tag == '[imputado.apellidos]') {
      final names = _sharedTags['[imputado.nombres]'] ?? '';
      final surnames = _sharedTags['[imputado.apellidos]'] ?? '';
      _sharedTags['[imputado.nombres_apellidos]'] = '$names $surnames'.trim();
    }

    else if (tag == '[testigo.nombres_apellidos]') {
      final parts = value.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final surnames = parts.sublist(parts.length - 2).join(' ');
        final names = parts.sublist(0, parts.length - 2).join(' ');
        _sharedTags['[testigo.nombres]'] = names;
        _sharedTags['[testigo.apellidos]'] = surnames;
      } else {
        _sharedTags['[testigo.nombres]'] = value;
        _sharedTags['[testigo.apellidos]'] = '';
      }
    } else if (tag == '[testigo.nombres]' || tag == '[testigo.apellidos]') {
      final names = _sharedTags['[testigo.nombres]'] ?? '';
      final surnames = _sharedTags['[testigo.apellidos]'] ?? '';
      _sharedTags['[testigo.nombres_apellidos]'] = '$names $surnames'.trim();
    }

    else if (tag == '[agraviado.nombres_apellidos]') {
      final parts = value.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final surnames = parts.sublist(parts.length - 2).join(' ');
        final names = parts.sublist(0, parts.length - 2).join(' ');
        _sharedTags['[agraviado.nombres]'] = names;
        _sharedTags['[agraviado.apellidos]'] = surnames;
      } else {
        _sharedTags['[agraviado.nombres]'] = value;
        _sharedTags['[agraviado.apellidos]'] = '';
      }
    } else if (tag == '[agraviado.nombres]' || tag == '[agraviado.apellidos]') {
      final names = _sharedTags['[agraviado.nombres]'] ?? '';
      final surnames = _sharedTags['[agraviado.apellidos]'] ?? '';
      _sharedTags['[agraviado.nombres_apellidos]'] = '$names $surnames'.trim();
    }

    // Sincronización recíproca de fechas
    else if (tag == '[tiempo.fecha_hecho]') {
      _sharedTags['[tiempo.fecha_intervencion]'] = value;
    } else if (tag == '[tiempo.fecha_intervencion]') {
      _sharedTags['[tiempo.fecha_hecho]'] = value;
    }

    _syncGenericTags();
    if (tag == '[registro.bienes_detalle]' ||
        tag == '[registro.descripcion_bien_buscado]' ||
        tag == '[registro.bienes_hallados]' ||
        tag == '[registro.bienes_recepcionados]' ||
        tag == '[registro.bienes_hallados_vehiculo]') {
      _syncBienesTags();
    }
    notifyListeners();
  }

  void populateDniData(String type, DniResultado data) {
    final address = data.direccionCompleta.isNotEmpty ? data.direccionCompleta : data.direccion;
    if (type == 'imputado') {
      _sharedTags['[imputado.dni]'] = data.id;
      _sharedTags['[imputado.nombres_apellidos]'] = data.nombreCompleto;
      _sharedTags['[imputado.nombres]'] = data.nombres;
      _sharedTags['[imputado.apellidos]'] = '${data.apellidoPaterno} ${data.apellidoMaterno}'.trim();
      _sharedTags['[imputado.fecha_nacimiento]'] = data.fechaNacimiento;
      if (address.isNotEmpty) {
        _sharedTags['[imputado.domicilio]'] = address;
      }
      if (data.nacionalidad.isNotEmpty) {
        _sharedTags['[imputado.nacionalidad]'] = data.nacionalidad;
      }
      
      final age = _calculateAge(data.fechaNacimiento);
      if (age > 0) {
        _sharedTags['[imputado.edad]'] = '$age';
      }
    } else if (type == 'testigo') {
      _sharedTags['[testigo.dni]'] = data.id;
      _sharedTags['[testigo.nombres_apellidos]'] = data.nombreCompleto;
      if (address.isNotEmpty) {
        _sharedTags['[testigo.domicilio]'] = address;
      }
    } else if (type == 'agraviado') {
      _sharedTags['[agraviado.dni]'] = data.id;
      _sharedTags['[agraviado.nombres_apellidos]'] = data.nombreCompleto;
      if (address.isNotEmpty) {
        _sharedTags['[agraviado.domicilio]'] = address;
      }
    }
    notifyListeners();
  }

  int _calculateAge(String birthDateStr) {
    try {
      // Format: DD/MM/YYYY
      final parts = birthDateStr.split('/');
      if (parts.length != 3) return 0;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  void populatePlacaData(PlacaResultado data) {
    _sharedTags['[vehiculo.placa_unica_nacional_rodaje]'] = data.placa;
    _sharedTags['[vehiculo.placa]'] = data.placa;
    _sharedTags['[vehiculo.marca]'] = data.marca;
    _sharedTags['[vehiculo.modelo]'] = data.modelo;
    _sharedTags['[vehiculo.color]'] = data.color;
    _sharedTags['[vehiculo.motor]'] = data.motor;
    _sharedTags['[vehiculo.serie]'] = data.serie;
    notifyListeners();
  }



  
  void _syncGenericTags() {
    final typificationId = _currentSession?.typificationId ?? '';
    
    // Default fallback
    String objetos = _sharedTags['[registro.bienes_detalle]'] ?? '_______________';
    String ubicacion = 'En poder del intervenido';
    String cantidad = 'Según descripción';
    String caracteristicas = '_______________';
    String bienesHallados = _sharedTags['[registro.bienes_detalle]'] ?? '_______________';

    if (typificationId == 'tid_microcomercializacion') {
      final droga = _sharedTags['[droga.tipo_sustancia]'] ?? '_______________';
      final ubi = _sharedTags['[droga.ubicacion]'] ?? '_______________';
      final cant = _sharedTags['[droga.cantidad]'] ?? '_______________';
      
      objetos = droga;
      ubicacion = ubi;
      cantidad = cant;
      caracteristicas = 'Sustancia ilícita ($droga)';
      bienesHallados = 'Durante el registro personal se le halló en $ubi, la cantidad de $cant conteniendo una sustancia con características a $droga.';
    } else if (typificationId == 'tenencia_armas') {
      final tipo = _sharedTags['[arma.tipo]'] ?? '_______________';
      final marca = _sharedTags['[arma.marca_calibre]'] ?? '_______________';
      final serie = _sharedTags['[arma.serie]'] ?? '_______________';
      final mun = _sharedTags['[arma.municiones]'] ?? '_______________';

      objetos = 'Un arma de fuego tipo $tipo';
      ubicacion = 'En posesión del intervenido';
      cantidad = '01 arma y $mun';
      caracteristicas = 'Marca/Calibre: $marca, Serie: $serie';
      bienesHallados = 'Se halló un arma de fuego tipo $tipo, marca y calibre $marca, con serie $serie y $mun.';
    } else if (typificationId == 'robo_agravado' || typificationId == 'hurto_agravado' || typificationId == 'receptacion') {
      final bienes = _sharedTags['[robo.bienes]'] ?? '_______________';
      final inst = _sharedTags['[robo.instrumento]'] ?? '_______________';

      objetos = bienes;
      ubicacion = 'En poder del intervenido';
      cantidad = 'Especies descritas';
      caracteristicas = 'Arma/Instrumento usado: $inst';
      bienesHallados = 'Se recuperó: $bienes. Se halló como instrumento del delito: $inst.';
    } else if (typificationId == 'peligro_comun') {
      final placa = _sharedTags['[vehiculo.placa_unica_nacional_rodaje]'] ?? '_______________';
      final sintomas = _sharedTags['[peligro.sintomas]'] ?? '_______________';

      objetos = 'Vehículo intervenido';
      ubicacion = 'En la vía pública';
      cantidad = '01 vehículo';
      caracteristicas = 'Placa: $placa, Síntomas etílicos: $sintomas';
      bienesHallados = 'Se incautó/retuvo el vehículo de placa $placa. El conductor presentó: $sintomas.';
    } else if (typificationId == 'violencia_mujer_grupo_familiar' || typificationId == 'lesiones') {
      final vinc = _sharedTags['[violencia.vinculo]'] ?? '_______________';
      final les = _sharedTags['[violencia.lesiones_victima]'] ?? '_______________';

      objetos = 'Ninguno ilícito';
      ubicacion = 'No aplica';
      cantidad = 'No aplica';
      caracteristicas = 'Vínculo: $vinc, Lesiones: $les';
      bienesHallados = 'Registro personal negativo para bienes ilícitos. Se constata vínculo con víctima: $vinc, y estado: $les.';
    }

    _sharedTags['[evi.objetos]'] = objetos;
    _sharedTags['[evi.ubicacion]'] = ubicacion;
    _sharedTags['[evi.cantidad]'] = cantidad;
    _sharedTags['[evi.caracteristicas]'] = caracteristicas;
    _sharedTags['[registro.bienes_hallados]'] = bienesHallados;
    _sharedTags['[registro.bienes_recepcionados]'] = bienesHallados;
    _sharedTags['[registro.bienes_hallados_vehiculo]'] = bienesHallados;
  }

  void _syncBienesTags() {
    String rawBienes = (_sharedTags['[registro.bienes_detalle]'] ?? '').trim();
    if (rawBienes.isEmpty || rawBienes == '_______________') {
      rawBienes = (_sharedTags['[registro.bienes_hallados]'] ?? '').trim();
    }
    if (rawBienes.isEmpty || rawBienes == '_______________') {
      rawBienes = (_sharedTags['[registro.bienes_recepcionados]'] ?? '').trim();
    }
    if (rawBienes.isEmpty || rawBienes == '_______________') {
      rawBienes = (_sharedTags['[registro.bienes_hallados_vehiculo]'] ?? '').trim();
    }
    if (rawBienes.isEmpty || rawBienes == '_______________') {
      rawBienes = (_sharedTags['[registro.descripcion_bien_buscado]'] ?? '').trim();
    }

    if (rawBienes.isEmpty || rawBienes == '_______________') {
      _sharedTags['[bien.numero_hallazgo]'] = '01';
      _sharedTags['[bien.cantidad]'] = '_______________';
      _sharedTags['[bien.unidadMedida]'] = '_______________';
      _sharedTags['[bien.descripcion]'] = '_______________';
      return;
    }

    final lines = rawBienes.split(RegExp(r'[\n\r]+'));
    String firstLine = '';
    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        firstLine = line.trim();
        break;
      }
    }

    if (firstLine.isEmpty) return;

    // Clean leading bullet and number indicators
    firstLine = firstLine.replaceFirst(RegExp(r'^[-*•●■]\s*'), '');
    firstLine = firstLine.replaceFirst(RegExp(r'^\d+\s*[\.\)]\s*'), '');
    firstLine = firstLine.trim();

    final match = RegExp(
      r'^(\d+)\s+(gramos|g|kg|kilos|unidades|und|paquetes|bolsas|bolsa|sobres|sobre|envoltorios|ketes|kete|unid|unidades|celulares|celular|botellas|botella|teléfonos|teléfono|telefono|telefonos|equipos|equipo|paquete|bolsitas|bolsita)\s*(?:de\s+)?(.*)$',
      caseSensitive: false,
    ).firstMatch(firstLine);

    String cantidad = '1';
    String unidad = 'UNIDAD';
    String descripcion = firstLine;

    if (match != null) {
      cantidad = match.group(1) ?? '1';
      unidad = (match.group(2) ?? 'UNIDAD').toUpperCase();
      descripcion = match.group(3) ?? '';
      if (descripcion.isEmpty) descripcion = firstLine;
    } else {
      final wordMatch = RegExp(
        r'^(un|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez)\s+(gramos|g|kg|kilos|unidades|und|paquetes|bolsas|bolsa|sobres|sobre|envoltorios|ketes|kete|unid|unidades|celulares|celular|botellas|botella|teléfonos|teléfono|telefono|telefonos|equipos|equipo|paquete|bolsitas|bolsita)\s*(?:de\s+)?(.*)$',
        caseSensitive: false,
      ).firstMatch(firstLine);
      if (wordMatch != null) {
        var wordNum = wordMatch.group(1)?.toLowerCase() ?? '1';
        final wordMap = {
          'un': '1', 'una': '1', 'dos': '2', 'tres': '3', 'cuatro': '4',
          'cinco': '5', 'seis': '6', 'siete': '7', 'ocho': '8', 'nueve': '9', 'diez': '10'
        };
        cantidad = wordMap[wordNum] ?? wordNum;
        unidad = (wordMatch.group(2) ?? 'UNIDAD').toUpperCase();
        descripcion = wordMatch.group(3) ?? '';
        if (descripcion.isEmpty) descripcion = firstLine;
      } else {
        final simpleNumMatch = RegExp(r'^(\d+)\s+(.*)$').firstMatch(firstLine);
        if (simpleNumMatch != null) {
          cantidad = simpleNumMatch.group(1) ?? '1';
          unidad = 'UNIDAD';
          descripcion = simpleNumMatch.group(2) ?? '';
        } else {
          cantidad = '1';
          unidad = 'UNIDAD';
          descripcion = firstLine;
        }
      }
    }

    _sharedTags['[bien.numero_hallazgo]'] = '01';
    _sharedTags['[bien.cantidad]'] = cantidad;
    _sharedTags['[bien.unidadMedida]'] = unidad;
    _sharedTags['[bien.descripcion]'] = descripcion;
  }

  String? getTagValue(String tag) => _sharedTags[tag];

  bool getCondition(String key) => _conditions[key] ?? false;

  void updateCondition(String key, bool value) {
    _conditions[key] = value;
    if (key == 'FISCAL') {
      _sharedTags['[intervencion.requiere_fiscal]'] = value ? 'SI' : 'NO';
    }
    notifyListeners();
  }

  String? getTagValueWithContext(String tag) {
    if (tag == '[instructor.grado_nombres]') {
      final value = _sharedTags[tag];
      if (value != null && value.isNotEmpty) return value;
      final grade = _operatorGrade.toUpperCase().trim();
      final surnames = '${_operatorFirstSurname.toUpperCase()} ${_operatorSecondSurname.toUpperCase()}'.trim();
      final names = _operatorName.toUpperCase().trim();
      final combined = '$grade $surnames $names'.trim();
      return combined.isNotEmpty ? combined : null;
    }
    if (tag == '[instructor.cip]') {
      final value = _sharedTags[tag];
      if (value != null && value.isNotEmpty) return value;
      return _operatorCip.isNotEmpty ? _operatorCip.toUpperCase() : null;
    }
    if (tag == '[lugar.provincia]') {
      final value = _sharedTags[tag];
      if (value != null && value.isNotEmpty && value != '_______________') return value;
      return _operatorCity.isNotEmpty ? _operatorCity.toUpperCase() : null;
    }
    return _sharedTags[tag];
  }

  /// Returns how many tags in a document are filled
  int countFilledTags(InterventionDocument doc) {
    final regex = RegExp(r'\[(.*?)\]');
    final tags = regex.allMatches(doc.content).map((m) => m.group(0)!).toSet();
    return tags.where((t) => (_sharedTags[t]?.isNotEmpty ?? false)).length;
  }

  /// Returns total tag count in a document
  int countTotalTags(InterventionDocument doc) {
    final regex = RegExp(r'\[(.*?)\]');
    return regex.allMatches(doc.content).map((m) => m.group(0)!).toSet().length;
  }

  Future<void> saveCurrentSession() async {
    if (_currentSession == null) return;
    final saved = SavedSession(
      id: _currentSession!.id,
      name: _currentSession!.name,
      typificationId: _currentSession!.typificationId,
      typificationName: _currentTypificationName,
      documentTitles: _currentSession!.documents.map((d) => d.title).toList(),
      tagValues: Map.from(_sharedTags),
      savedAt: DateTime.now(),
      manifestacionData: _manifestacionData,
      registroPersonalData: _registroPersonalData,
      assistantStep: _assistantStep,
    );
    await _service.save(saved);
    await loadSavedSessions();
  }

  Future<void> deleteSavedSession(String id) async {
    await _service.delete(id);
    await loadSavedSessions();
  }

  // ═══════════════════════════════════════════════════════════════
  // ALGORITMO DE RESTRICCIÓN PROCESAL — CONSTANCIA DE BUEN TRATO
  // Doctrina PNP: Solo aplica en Violencia Familiar y Control de
  // Identidad. Bloqueado para Robo, TID, Extorsión, Requisitoria, etc.
  // Referencia normativa: Manual de Documentación Policial PNP.
  // ═══════════════════════════════════════════════════════════════

  /// Determina si el tipo de intervención habilita la generación de
  /// la "Constancia de Buen Trato". Devuelve [true] solo para los
  /// dos escenarios donde la norma exige dicho documento.
  bool permiteConstanciaBuenTrato(String typificationId) {
    const permitidos = <String>{
      'VIOLENCIA_FAMILIAR',
      'CONTROL_IDENTIDAD',
    };
    return permitidos.contains(typificationId.toUpperCase().trim());
  }

  /// Retorna el mensaje de bloqueo que se mostrará en la UI cuando
  /// el efectivo intente añadir la constancia en un caso no permitido.
  String mensajeBloqueoConstancia(String typificationId) {
    if (permiteConstanciaBuenTrato(typificationId)) return '';
    return 'La "Constancia de Buen Trato" no aplica para este tipo de '
        'intervención ($typificationId). Solo es válida en casos de '
        'Violencia Familiar y Control de Identidad. '
        'Redactar este documento en otros escenarios puede ser '
        'objetado por el Fiscal como desviación de procedimiento.';
  }

  // ═══════════════════════════════════════════════════════════════
  // MOTOR DE EXPORTACIÓN — CARPETA FISCAL UNIFICADA
  // Genera los bytes PDF de cada acta de la sesión, los empaqueta
  // con EmpaquetadorService y retorna el documento maestro sellado.
  // ═══════════════════════════════════════════════════════════════

  /// Genera la Carpeta Fiscal completa en memoria.
  /// Cada documento en la sesión activa es convertido a bytes usando
  /// el generador PDF correspondiente según su título. Los títulos no
  /// reconocidos se renderizan como páginas de texto plano genéricas.
  Future<Uint8List> generarCarpetaFiscal({ExportConfig? config}) async {
    if (_currentSession == null) {
      throw Exception('No hay sesión activa para empaquetar.');
    }

    final tags = Map<String, String>.from(_sharedTags);
    final nombre = _currentSession!.name;
    final docs = _currentSession!.documents;

    // ── 1. GENERAR BYTES PDF POR TIPO DE ACTA ──────────────────
    final List<ActaParaEmpaquetar> actas = [];

    for (final doc in docs) {
      final titulo = doc.title;
      final hora = tags['[tiempo.acta_hora_inicio]'] ?? '00:00';
      Uint8List bytes;

      try {
        bytes = await generarActaPdf(doc);
      } catch (_) {
        // Si un generador falla, usamos bytes vacíos para no bloquear el paquete
        bytes = Uint8List(0);
      }

      actas.add(ActaParaEmpaquetar(
        pdfBytes: bytes,
        titulo: titulo,
        horaInicio: hora,
      ));
    }

    // ── 2. EMPAQUETAR CON REGLAS DOCTRINALES ─────────────────────
    return EmpaquetadorService.empaquetarCarpetaFiscal(
      actas: actas,
      tags: tags,
      nombreIntervencion: nombre,
      config: config,
    );
  }

  /// Genera el PDF de una sola acta basándose en su título.
  Future<Uint8List> generarActaPdf(InterventionDocument doc) async {
    final titulo = doc.title;
    final tipificacion = _currentTypificationName ?? '';
    final tags = Map<String, String>.from(_sharedTags);
    final docs = _currentSession?.documents ?? [doc];
    
    if (titulo.contains('Manifestación')) {
      return await PdfService.generateManifestacionPdf(tags);
    } else if (titulo.contains('Detención')) {
      return await PdfService.generateDetencionPdf(tags, tipificacion);
    } else if (titulo.contains('Registro Personal')) {
      return await PdfService.generateRegistroPersonalPdf(tags);
    } else if (titulo.contains('Hallazgo')) {
      return await PdfService.generateHallazgoRecojoPdf(tags);
    } else if (titulo.contains('Lacrado')) {
      return await PdfService.generateLacradoPdf(tags);
    } else if (titulo.toLowerCase().contains('registro de vehículo') ||
        titulo.toLowerCase().contains('registro vehicular') ||
        titulo.toLowerCase().contains('registro de vehiculo')) {
      return await PdfService.generateRegistroVehicularPdf(tags);
    } else if (titulo.contains('Vehicular') || titulo.contains('Situación Vehicular')) {
      return await PdfService.generateSituacionVehicularPdf(tags);
    } else if (titulo.contains('Domiciliario') || titulo.contains('Allanamiento')) {
      return await PdfService.generateRegistroDomiciliarioPdf(tags);
    } else if (titulo.contains('Escena')) {
      return await PdfService.generateLlegadaEscenaPdf(tags);
    } else if (titulo.contains('Reconocimiento')) {
      return await PdfService.generateReconocimientoFisicoPdf(tags);
    } else if (titulo.contains('Recepción') || titulo.contains('Recepcion') || titulo.contains('Entrega')) {
      return await PdfService.generateActaRecepcionPdf(tags);
    } else if (titulo.contains('Identificación') || titulo.contains('Hoja de Datos')) {
      return await PdfService.generateHojaIdentificacionPdf(tags);
    } else if (titulo.contains('Requisitoria') || titulo.contains('Hoja Básica de Requisitoria')) {
      return await PdfService.generateHojaRequisitoriaPdf(tags);
    } else if (titulo.contains('Rótulo') || titulo.contains('Formato A-6') || titulo.contains('A-6')) {
      return await PdfService.generateRotuloA6Pdf(tags);
    } else if (titulo.contains('Acta de Intervención') || titulo.contains('Intervención Policial')) {
      final docTitles = docs.map((d) => d.title).toList();
      return await PdfService.generateActaIntervencionPdf(tags, tipificacion, docTitles);
    } else if (titulo.contains('Parte Policial')) {
      final resumenAi = await AiTacticalService.sintetizarPartePolicial(tags);
      if (resumenAi != null && resumenAi.isNotEmpty) {
        tags['[parte.resumen_ai]'] = resumenAi;
      }
      final docTitles = docs.map((d) => d.title).toList();
      return await PdfService.generatePartePolicialPdf(tags, tipificacion, docTitles);
    } else {
      return await PdfService.generateManifestacionPdf(tags);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MOTOR DE ANEXOS ADMINISTRATIVOS — Mesa de Partes e Investigaciones
  // Detecta inteligentemente si hay testigo, agraviado o detenido en
  // los tags de la sesión y genera solo los documentos que aplican.
  // ═══════════════════════════════════════════════════════════════

  /// Genera el PDF de Anexos Administrativos (Oficios, Citaciones,
  /// Notificaciones y Derechos de Víctima) basándose en los datos
  /// ingresados en el formulario de la sesión activa.
  Future<Uint8List> generarAnexosAdministrativos() async {
    if (_currentSession == null) {
      throw Exception('No hay sesión activa para generar anexos.');
    }

    final tags = Map<String, String>.from(_sharedTags);
    final tipificacion = _currentTypificationName ?? '';
    final pdf = pw.Document(
      title: 'Anexos Administrativos — ${_currentSession!.name}',
    );

    // ── DETECCIÓN AUTOMÁTICA DE PARTICIPANTES ─────────────────────
    final hayTestigo =
        (tags['[testigo.nombres_apellidos]'] ?? '').trim().isNotEmpty;
    final hayAgraviado =
        (tags['[agraviado.nombres_apellidos]'] ?? '').trim().isNotEmpty;
    final hayImputado =
        (tags['[imputado.nombres_apellidos]'] ?? '').trim().isNotEmpty;

    // ── PORTADA DE ANEXOS ──────────────────────────────────────────
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(50),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Column(children: [
              pw.Text('POLICÍA NACIONAL DEL PERÚ',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 4),
              pw.Text(tags['[dependencia.nombre]'] ?? '_______________',
                  style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 30),
              pw.Text('ANEXOS ADMINISTRATIVOS',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Mesa de Partes e Investigaciones\n${_currentSession!.name}',
                  style: pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.center),
            ]),
          ),
          pw.SizedBox(height: 40),
          pw.Text('DOCUMENTOS INCLUIDOS EN ESTE PAQUETE:',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 10),
          if (hayImputado)
            pw.Text('• Oficio Petitorio de Reconocimiento Médico Legal (F-56)',
                style: const pw.TextStyle(fontSize: 10)),
          if (hayTestigo)
            pw.Text('• Citación Policial al Testigo / Agraviado (F-30)',
                style: const pw.TextStyle(fontSize: 10)),
          if (hayImputado)
            pw.Text('• Notificación Policial al Intervenido (F-54)',
                style: const pw.TextStyle(fontSize: 10)),
          if (hayAgraviado)
            pw.Text('• Acta de Información de Derechos de la Víctima (F-09)',
                style: const pw.TextStyle(fontSize: 10)),
          if (!hayTestigo && !hayAgraviado && !hayImputado)
            pw.Text(
                '⚠ No se detectaron participantes en el formulario. '
                'Complete los campos de imputado, testigo o agraviado.',
                style: pw.TextStyle(color: PdfColors.red, fontSize: 10)),
          pw.Spacer(),
          pw.Divider(thickness: 0.3),
          pw.Text(
              'Generado por ACTIUM — Sistema de Gestión Policial',
              style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8)),
        ],
      ),
    ));

    // ── DOCUMENTO 1: OFICIO PETITORIO (si hay imputado) ───────────
    if (hayImputado) {
      await PdfService.addOficioPetitorioPages(pdf, tags, tipificacion, includeFoliation: false);
    }

    // ── DOCUMENTO 2: CITACIÓN POLICIAL (si hay testigo) ───────────
    if (hayTestigo) {
      await PdfService.addCitacionPolicialPages(pdf, tags, includeFoliation: false);
    }

    // ── DOCUMENTO 3: NOTIFICACIÓN (si hay imputado) ───────────────
    if (hayImputado) {
      await PdfService.addNotificacionPolicialPages(pdf, tags, includeFoliation: false);
    }

    // ── DOCUMENTO 4: DERECHOS DE VÍCTIMA (si hay agraviado) ───────
    if (hayAgraviado) {
      await PdfService.addDerechosVictimaPages(pdf, tags, includeFoliation: false);
    }

    return pdf.save();
  }

  void updateDocumentContent(String documentId, String newContent) {
    if (_currentSession == null) return;
    for (var doc in _currentSession!.documents) {
      if (doc.id == documentId) {
        doc.content = newContent;
        break;
      }
    }
    notifyListeners();
    saveCurrentSession();
  }
}
