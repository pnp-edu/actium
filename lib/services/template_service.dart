import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template.dart';

import '../models/default_templates.dart';

class TemplateService {
  static const String _key = 'saved_templates';
  // Bump this number whenever the default template list changes.
  // On first run or when version is outdated, defaults are re-seeded
  // while preserving any user-created (non-system) templates.
  static const int _seedVersion = 4;
  static const String _seedVersionKey = 'template_seed_version';

  static List<Template> _buildDefaults() => [
        Template(id: 't1',  name: 'Acta de Intervención',                        content: DefaultTemplates.actaIntervencion,       isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't2',  name: 'Acta de Registro Personal e Incautación',      content: DefaultTemplates.actaRegistroPersonal,  isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't3',  name: 'Acta de Detención y Lectura de Derechos',      content: DefaultTemplates.actaDetencion,         isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't4',  name: 'Acta de Recepción',                            content: DefaultTemplates.actaRecepcion,         isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't5',  name: 'Cartilla de Derechos',                         content: DefaultTemplates.cartillaDerechos,      isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't6',  name: 'Oficio Petitorio',                             content: DefaultTemplates.oficioPetitorio,       isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't7',  name: 'Acta de Lacrado',                              content: DefaultTemplates.actaLacrado,           isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't8',  name: 'Rótulo de Evidencias (Formato A-6)',           content: DefaultTemplates.rotuloA6,             isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't9',  name: 'Hoja de Datos de Identificación (Formato 38)', content: DefaultTemplates.hojaIdentificacion,    isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't10', name: 'Acta de Registro de Vehículo e Incautación',   content: DefaultTemplates.actaRegistroVehiculo,  isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't11', name: 'Acta de Situación Vehicular',                  content: DefaultTemplates.actaSituacionVehicular,isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't12', name: 'Oficio para Dosaje Etílico',                   content: DefaultTemplates.oficioDosajeEtilico,   isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't13', name: 'Constancia de Buen Trato',                     content: '',                                    isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't14', name: 'Hoja Básica de Requisitoria (Formato 37)',     content: DefaultTemplates.hojaRequisitoria,     isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't15', name: 'Acta de Llegada a la Escena del Delito',       content: DefaultTemplates.actaLlegadaEscena,    isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't16', name: 'Acta de Levantamiento de Cadáver',             content: '',                                    isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't17', name: 'Acta de Hallazgo y Recojo',                    content: DefaultTemplates.actaHallazgoRecojo,   isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't18', name: 'Acta de Reconocimiento',                       content: DefaultTemplates.actaReconocimiento,   isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't19', name: 'Acta de Allanamiento y Registro',              content: DefaultTemplates.actaAllanamiento,     isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't20', name: 'Parte Policial',                               content: DefaultTemplates.partePolicial,        isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't21', name: 'Acta de Manifestación',                        content: DefaultTemplates.actaManifestacion,    isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't22', name: 'Citación Policial',                            content: DefaultTemplates.citacionPolicial,     isSystem: true, createdBy: 'SISTEMA'),
        Template(id: 't23', name: 'Notificación Policial',                        content: DefaultTemplates.notificacionPolicial, isSystem: true, createdBy: 'SISTEMA'),
      ];

  static List<Template> deduplicateTemplates(List<Template> rawList) {
    final Map<String, Template> uniqueMap = {};
    for (final t in rawList) {
      final nameKey = t.name.trim().toLowerCase();
      final existing = uniqueMap[nameKey];
      if (existing == null) {
        uniqueMap[nameKey] = t;
      } else {
        int existingPriority = _getTemplatePriority(existing);
        int currentPriority = _getTemplatePriority(t);
        if (currentPriority > existingPriority) {
          uniqueMap[nameKey] = t;
        }
      }
    }
    return uniqueMap.values.toList();
  }

  static int _getTemplatePriority(Template t) {
    if (t.isSystem) return 1;
    final cb = t.createdBy?.trim().toUpperCase() ?? '';
    if (cb == '' || cb == 'CIP-PROPIO' || cb == 'COMUNIDAD') {
      return 3;
    }
    return 2; // Imported
  }

  Future<List<Template>> _loadRawTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_seedVersionKey) ?? 0;
    final String? jsonString = prefs.getString(_key);

    if (jsonString == null || storedVersion < _seedVersion) {
      // First run or outdated seed: merge defaults with any user-created templates.
      final defaults = _buildDefaults();
      List<Template> userTemplates = [];
      if (jsonString != null) {
        try {
          final List<dynamic> existing = json.decode(jsonString);
          userTemplates = existing
              .map((e) => Template.fromMap(e))
              .where((t) => !t.isSystem)
              .toList();
        } catch (_) {}
      }
      final merged = [...defaults, ...userTemplates];
      await prefs.setString(_key, json.encode(merged.map((t) => t.toMap()).toList()));
      await prefs.setInt(_seedVersionKey, _seedVersion);
      return merged;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => Template.fromMap(e)).toList();
    } catch (_) {
      return _buildDefaults();
    }
  }

  Future<List<Template>> loadTemplates() async {
    final raw = await _loadRawTemplates();
    return deduplicateTemplates(raw);
  }

  Future<void> saveTemplate(Template template) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await _loadRawTemplates();
    
    final existingIndex = templates.indexWhere((t) => t.id == template.id);
    if (existingIndex >= 0) {
      templates[existingIndex] = template;
    } else {
      templates.add(template);
    }
    
    await prefs.setString(_key, json.encode(templates.map((t) => t.toMap()).toList()));
  }

  Future<void> deleteTemplate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final templates = await _loadRawTemplates();
    templates.removeWhere((t) => t.id == id);
    await prefs.setString(_key, json.encode(templates.map((t) => t.toMap()).toList()));
  }
}
