import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manifestacion.dart';
import '../models/registro_personal.dart';

class SavedSession {
  final String id;
  final String name;
  final String? typificationId;
  final String? typificationName;
  final List<String> documentTitles;
  final Map<String, String> tagValues;
  final DateTime savedAt;
  final ManifestacionData? manifestacionData;
  final RegistroPersonalData? registroPersonalData;
  final int assistantStep;

  SavedSession({
    required this.id,
    required this.name,
    this.typificationId,
    this.typificationName,
    required this.documentTitles,
    required this.tagValues,
    required this.savedAt,
    this.manifestacionData,
    this.registroPersonalData,
    this.assistantStep = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'typificationId': typificationId,
        'typificationName': typificationName,
        'documentTitles': documentTitles,
        'tagValues': tagValues,
        'savedAt': savedAt.toIso8601String(),
        'manifestacionData': manifestacionData?.toJson(),
        'registroPersonalData': registroPersonalData?.toJson(),
        'assistantStep': assistantStep,
      };

  factory SavedSession.fromMap(Map<String, dynamic> map) => SavedSession(
        id: map['id'],
        name: map['name'],
        typificationId: map['typificationId'],
        typificationName: map['typificationName'],
        documentTitles: List<String>.from(map['documentTitles']),
        tagValues: Map<String, String>.from(map['tagValues']),
        savedAt: DateTime.parse(map['savedAt']),
        manifestacionData: map['manifestacionData'] != null ? ManifestacionData.fromJson(map['manifestacionData']) : null,
        registroPersonalData: map['registroPersonalData'] != null ? RegistroPersonalData.fromJson(map['registroPersonalData']) : null,
        assistantStep: map['assistantStep'] ?? 0,
      );

  String toJson() => json.encode(toMap());
  factory SavedSession.fromJson(String source) =>
      SavedSession.fromMap(json.decode(source));
}

class InterventionService {
  static const _key = 'saved_sessions';

  Future<List<SavedSession>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.map((e) => SavedSession.fromMap(e)).toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> save(SavedSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadAll();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }
    await prefs.setString(
        _key, json.encode(sessions.map((s) => s.toMap()).toList()));
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadAll();
    sessions.removeWhere((s) => s.id == id);
    await prefs.setString(
        _key, json.encode(sessions.map((s) => s.toMap()).toList()));
  }
}
