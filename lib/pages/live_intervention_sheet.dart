import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/intervention_provider.dart';
import '../services/dni_service.dart';
import '../services/ai_tactical_service.dart';
import '../widgets/ai_grill_sheet.dart';
import '../models/intervention_session.dart';
import '../models/typification.dart';
import '../models/typification_repository.dart';
import '../models/wizard_step.dart';
import '../models/tags.dart';


class LiveInterventionSheet extends StatefulWidget {
  final ScrollController? scrollController;
  const LiveInterventionSheet({super.key, this.scrollController});

  @override
  State<LiveInterventionSheet> createState() => _LiveInterventionSheetState();
}

class _LiveInterventionSheetState extends State<LiveInterventionSheet> {
  int _currentStep = 0;
  String? _activeStepTag;
  late final PageController _pageController;
  final TextEditingController _dniController = TextEditingController();
  bool _isDniLoading = false;
  bool _isAiReviewLoading = false;
  AuditMaestroResult? _cachedAuditResult;

  // ── Speech-to-text ─────────────────────────────────────────────
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String? _listeningTag; // which tag is currently recording

  // ── Recent comisarías for lugar_redaccion step ───────────────────────
  List<String> _recentComisarias = [];

  // Cached controllers to avoid rebuild focus resets
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<InterventionProvider>();
    _currentStep = provider.assistantStep;
    _pageController = PageController(initialPage: _currentStep);
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadRecentComisarias();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final visibleSteps = _getVisibleSteps(context.read<InterventionProvider>());
      if (visibleSteps.isNotEmpty) {
        setState(() => _activeStepTag = visibleSteps[_currentStep].tag);
      }
    });
  }

  Future<void> _loadRecentComisarias() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('saved_comisarias') ?? [];
    if (mounted) {
      setState(() {
        // Last 2 used comisarías (most recent first)
        _recentComisarias = list.reversed.take(2).toList();
      });
    }
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (_) => setState(() { _isListening = false; _listeningTag = null; }),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() { _isListening = false; _listeningTag = null; });
        }
      },
    );
  }

  @override
  void dispose() {
    _dniController.dispose();
    _pageController.dispose();
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    if (_speech.isListening) _speech.stop();
    super.dispose();
  }





  
  List<WizardStep> _getVisibleSteps(InterventionProvider provider) {
    final allSteps = getWizardSteps(provider);
    return allSteps.where((step) {
      if (step.isConditional) {
        final condVal = provider.getCondition(step.conditionKey!);
        if (condVal != step.conditionValue) return false;
      }
      // Skip imputado fields if they already have data (except DNI)
      if (step.tag.startsWith('[imputado.') && step.tag != '[imputado.dni]') {
        if (step.tag == _activeStepTag) {
          return true;
        }
        final val = provider.getTagValue(step.tag);
        if (val != null && val.trim().isNotEmpty) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _next(int totalVisibleSteps) async {
    if (_isDniLoading) return;
    if (_currentStep < totalVisibleSteps - 1) {
      final provider = context.read<InterventionProvider>();
      final visibleSteps = _getVisibleSteps(provider);
      final currentWizardStep = visibleSteps[_currentStep];

      if (!currentWizardStep.isConditionSelector) {
        final val = provider.getTagValue(currentWizardStep.tag);
        if (currentWizardStep.tag != '[imputado.dni]' && (val == null || val.trim().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este campo es obligatorio. Por favor, complételo antes de continuar.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      // Check if current step is DNI lookup
      if (currentWizardStep.tag == '[imputado.dni]') {
        final dniVal = _dniController.text.trim();
        if (dniVal.isEmpty || dniVal.length != 8 || int.tryParse(dniVal) == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El DNI debe tener exactamente 8 dígitos numéricos')),
          );
          return;
        }

        final existingDni = provider.getTagValue('[imputado.dni]') ?? '';
        final existingName = provider.getTagValue('[imputado.nombres_apellidos]') ?? '';
        
        if (dniVal == existingDni && existingName.trim().isNotEmpty) {
          // Skip lookup since we already fetched it for this DNI
        } else {
          setState(() => _isDniLoading = true);
          final service = DniService();
          final key = await service.getApiKey();
          if (key == null || key.isEmpty) {
            setState(() => _isDniLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No hay API Key configurada para DNI.")),
              );
            }
          } else {
            final result = await service.consultarDni(dniVal, key);
            setState(() => _isDniLoading = false);

            if (result.success && result.resultado != null) {
              provider.updateTagValue('[imputado.dni]', dniVal);
              provider.updateTagValue(
                '[imputado.nombres_apellidos]',
                "${result.resultado!.nombres} ${result.resultado!.apellidoPaterno} ${result.resultado!.apellidoMaterno}",
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("DNI Encontrado: ${result.resultado!.nombres}")),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message.isNotEmpty ? result.message : "Error al consultar DNI.")),
                );
              }
            }
          }
        }
      }

      setState(() {
        final currentSteps = _getVisibleSteps(provider);
        _activeStepTag = currentSteps[_currentStep + 1].tag;
        final newSteps = _getVisibleSteps(provider);
        _currentStep = newSteps.indexWhere((s) => s.tag == _activeStepTag);
      });
      context.read<InterventionProvider>().updateAssistantStep(_currentStep);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      final provider = context.read<InterventionProvider>();
      setState(() {
        final currentSteps = _getVisibleSteps(provider);
        _activeStepTag = currentSteps[_currentStep - 1].tag;
        final newSteps = _getVisibleSteps(provider);
        _currentStep = newSteps.indexWhere((s) => s.tag == _activeStepTag);
      });
      context.read<InterventionProvider>().updateAssistantStep(_currentStep);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  String _compileDocumentText(InterventionDocument doc, InterventionProvider provider) {
    final conditionRegex = RegExp(r'<IF_([A-Z0-9_]+)>(.*?)</IF_\1>', dotAll: true);
    String text = doc.content.replaceAllMapped(conditionRegex, (match) {
      final condition = match.group(1)!;
      final innerText = match.group(2)!;
      if (provider.getCondition(condition)) {
        return innerText;
      }
      return '';
    });

    final conditionNotRegex = RegExp(r'<IF_NOT_([A-Z0-9_]+)>(.*?)</IF_NOT_\1>', dotAll: true);
    text = text.replaceAllMapped(conditionNotRegex, (match) {
      final condition = match.group(1)!;
      final innerText = match.group(2)!;
      if (!provider.getCondition(condition)) {
        return innerText;
      }
      return '';
    });

    final tagRegex = RegExp(r'\[(.*?)\]');
    text = text.replaceAllMapped(tagRegex, (match) {
      final tagString = match.group(0)!;
      
      if (tagString == '[hechos.concomitantes]') {
        String baseHechos = provider.getTagValue(tagString) ?? '';
        
        final steps = getWizardSteps(provider);
        String specificDetails = "";
        for (var step in steps) {
          if (step.tag.startsWith('[') && !doc.content.contains(step.tag) && step.tag != '[hechos.concomitantes]') {
            final val = provider.getTagValue(step.tag);
            if (val != null && val.isNotEmpty) {
              specificDetails += "\n- ${step.title.replaceFirst(RegExp(r'^\d+\.\s*'), '')}: $val";
            }
          }
        }
        
        if (specificDetails.isNotEmpty) {
           return "$baseHechos\n\n[DETALLES ESPECÍFICOS DE LA INTERVENCIÓN]:$specificDetails";
        }
        return baseHechos.isEmpty ? tagString : baseHechos;
      }

      final val = provider.getTagValue(tagString);
      if (val != null && val.isNotEmpty) {
        return val;
      }
      return tagString;
    });

    return text;
  }

  Future<void> _runAiReview(BuildContext context, InterventionProvider provider, {bool forceReaudit = false}) async {
    final session = provider.currentSession;
    if (session == null || session.documents.isEmpty) return;

    final doc = session.documents.firstWhere(
      (d) => d.title.toLowerCase().contains('intervención'),
      orElse: () => session.documents.first,
    );

    // ══════════════════════════════════════════════════════════
    // BLOQUEO ESTRICTO: nada pasa a la IA si faltan campos
    // ══════════════════════════════════════════════════════════
    List<String> faltantes = [];

    // 1. Validar PASOS DEL ASISTENTE activos (texto de preguntas clave)
    final steps = getWizardSteps(provider);
    for (var step in steps) {
      if (step.isConditionSelector) continue; // selector SÍ/NO no necesita valor
      
      bool isActive = true;
      if (step.isConditional && step.conditionKey != null) {
        final condVal = provider.getCondition(step.conditionKey!);
        if (condVal != step.conditionValue) isActive = false;
      }
      if (!isActive) continue;

      final val = provider.sharedTags[step.tag]?.trim();
      if (val == null || val.isEmpty || val.startsWith('_')) {
        if (!faltantes.contains(step.title)) {
          faltantes.add(step.title);
        }
      }
    }

    // 2. Validar ETIQUETAS DEL DOCUMENTO (Modo Completar)
    // Resolvemos condiciones IF manualmente sin backreferences
    String activeText = doc.content;
    // Extraer todas las claves de condicion y resolverlas una por una
    final condKeys = RegExp(r'<IF_([A-Z0-9_]+)>').allMatches(activeText).map((m) => m.group(1)!).toSet();
    for (final key in condKeys) {
      final isTrue = provider.getCondition(key);
      // Strip IF blocks: if condition true, keep inner text; if false, remove entirely
      activeText = activeText.replaceAllMapped(
        RegExp('<\\s*IF_$key\\s*>(.*?)<\\s*/\\s*IF_$key\\s*>', dotAll: true, caseSensitive: false),
        (m) => isTrue ? m.group(1)! : '',
      );
      // For negative conditions
      activeText = activeText.replaceAllMapped(
        RegExp('<\\s*IF_NOT_$key\\s*>(.*?)<\\s*/\\s*IF_NOT_$key\\s*>', dotAll: true, caseSensitive: false),
        (m) => !isTrue ? m.group(1)! : '',
      );
    }
    // Fallback: remove any remaining IF blocks
    activeText = activeText.replaceAll(RegExp(r'<IF[^>]*>.*?</IF[^>]*>', dotAll: true), '');

    final tagExp = RegExp(r'\[([^\]]+)\]');
    for (final m in tagExp.allMatches(activeText)) {
      final tagKey = m.group(0)!; // "[lugar.provincia]"
      final tagLabel = m.group(1)!; // "lugar.provincia"
      final val = provider.sharedTags[tagKey]?.trim();
      if (val == null || val.isEmpty || val.startsWith('_')) {
        if (!faltantes.contains(tagLabel)) {
          faltantes.add(tagLabel);
        }
      }
    }

    if (faltantes.isNotEmpty) {
      // Map raw tag/title to human-readable names
      String _humanize(String raw) {
        final Map<String, String> fieldNames = {
          'tiempo.fecha_hecho': 'Fecha de la intervención',
          'acta.lugar_redaccion': 'Lugar de redacción del acta',
          'lugar.provincia': 'Provincia',
          'lugar.distrito': 'Distrito / Ciudad',
          'lugar.calle': 'Dirección / Calle',
          'tiempo.acta_hora_inicio': 'Hora de inicio de los hechos',
          'imputado.dni': 'DNI del intervenido',
          'imputado.nombres_apellidos': 'Nombre del intervenido',
          'hechos.previos': 'Hechos precedentes',
          'hechos.concomitantes': 'Hechos concomitantes',
          'hechos.fuerza': 'Nivel de fuerza / resistencia',
          'registro.bienes_detalle': 'Evidencia hallada',
          'fiscal.grado_nombres': 'Nombre del fiscal',
          'fiscal.resultado_comunicacion': 'Disposición fiscal',
          'fiscal.motivo_no_comunicacion': 'Motivo de no comunicación al fiscal',
          'tiempo.acta_hora_cierre': 'Hora de cierre del acta',
          'instructor.grado_nombres': 'Datos del instructor (perfil)',
          'instructor.cip': 'Número de CIP del instructor',
          'acompanante.grado': 'Grado del acompañante',
          'acompanante.apellidos_nombres': 'Nombre del acompañante',
          'acompanante.cip': 'CIP del acompañante',
        };
        // Remove step numbering prefix if present
        final cleanRaw = raw.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        return fieldNames[cleanRaw] ?? fieldNames.entries
            .where((e) => cleanRaw.toLowerCase().contains(e.key.split('.').last))
            .map((e) => e.value)
            .firstOrNull ?? cleanRaw;
      }

      final humanFields = faltantes.map(_humanize).toList();
      final progressVal = 1.0 - (faltantes.length / (faltantes.length + 5).clamp(1, 999));

      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 560),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with animated lock icon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.redAccent, width: 1.5),
                          ),
                          child: const Icon(Icons.lock_outline, color: Colors.redAccent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auditoría Bloqueada',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Completa todos los campos para continuar',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso del acta',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            Text(
                              '${faltantes.length} campo${faltantes.length == 1 ? '' : 's'} pendiente${faltantes.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressVal.clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Missing fields list
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Campos que debes completar:',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...humanFields.take(8).map((f) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6, height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            f,
                                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  if (faltantes.length > 8)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '...y ${faltantes.length - 8} campo(s) más.',
                                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // CTA Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D7EFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          'Completar ahora →',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return;
    }

    if (!forceReaudit && _cachedAuditResult != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Auditoría Existente', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Ya tienes una auditoría generada. ¿Deseas verla o gastar tokens para re-auditar el texto actual?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'ver'),
              child: const Text('Ver actual', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D7EFF)),
              onPressed: () => Navigator.pop(ctx, 'reauditar'),
              child: const Text('Re-auditar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (choice == 'ver') {
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: AiGrillSheet(auditResult: _cachedAuditResult!, document: doc),
            ),
          );
        }
        return;
      } else if (choice == 'reauditar') {
        // proceed
      } else {
        return; // canceled
      }
    }

    if (_isAiReviewLoading) return;

    final apiKey = await AiTacticalService.getOrLoadToken();
    if (apiKey == null || apiKey.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registre su Groq API Key en Perfil para auditar el Acta.")),
        );
      }
      return;
    }

    final typificationId = session.typificationId ?? '';
    final typification = TypificationRepository.all.firstWhere(
      (t) => t.id == typificationId,
      orElse: () => const Typification(id: '', name: '', logic: '', recommendedTemplateNames: []),
    );

    setState(() => _isAiReviewLoading = true);

    final compiledText = _compileDocumentText(doc, provider);
    final result = await AiTacticalService.pulirRedaccionLegal(
      compiledText,
      typificationName: typification.name,
      typificationLogic: typification.logic,
    );

    setState(() => _isAiReviewLoading = false);

    if (result == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al comunicarse con la Inteligencia Artificial.")),
        );
      }
      return;
    }

    _cachedAuditResult = result;

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: AiGrillSheet(auditResult: result, document: doc),
        ),
      );
    }
  }

  Future<void> _showAiSuggestionsForMissingFields(BuildContext context, InterventionProvider provider) async {
    final session = provider.currentSession;
    if (session == null || session.documents.isEmpty) return;

    final doc = session.documents.firstWhere(
      (d) => d.title.toLowerCase().contains('intervención'),
      orElse: () => session.documents.first,
    );

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'ai_suggestion_${session.id}';
    final countKey = 'ai_suggestion_count_${session.id}';
    
    final existingSuggestion = prefs.getString(cacheKey);
    final count = prefs.getInt(countKey) ?? 0;

    Future<void> showSuggestionDialog(String text) async {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF3D7EFF))),
          title: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF3D7EFF)),
              SizedBox(width: 8),
              Expanded(child: Text('Sugerencias de IA', style: TextStyle(color: Colors.white))),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            if (count < 2)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetchNewAiSuggestion(context, provider, doc, session, cacheKey, countKey, count);
                },
                child: Text('Volver a sugerir (${2 - count} restantes)', style: const TextStyle(color: Color(0xFF3D7EFF))),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D7EFF)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (existingSuggestion != null && existingSuggestion.isNotEmpty) {
      await showSuggestionDialog(existingSuggestion);
    } else {
      await _fetchNewAiSuggestion(context, provider, doc, session, cacheKey, countKey, count);
    }
  }

  Future<void> _fetchNewAiSuggestion(
    BuildContext context,
    InterventionProvider provider,
    InterventionDocument doc,
    InterventionSession session,
    String cacheKey,
    String countKey,
    int currentCount,
  ) async {
    List<String> faltantes = [];

    final steps = getWizardSteps(provider);
    for (var step in steps) {
      if (step.isConditionSelector) continue;
      
      bool isActive = true;
      if (step.isConditional && step.conditionKey != null) {
        final condVal = provider.getCondition(step.conditionKey!);
        if (condVal != step.conditionValue) isActive = false;
      }
      if (!isActive) continue;

      final val = provider.sharedTags[step.tag]?.trim();
      if (val == null || val.isEmpty || val.startsWith('_')) {
        if (!faltantes.contains(step.title)) {
          faltantes.add(step.title);
        }
      }
    }

    String activeText = doc.content;
    final condKeys = RegExp(r'<IF_([A-Z0-9_]+)>').allMatches(activeText).map((m) => m.group(1)!).toSet();
    for (final key in condKeys) {
      final isTrue = provider.getCondition(key);
      activeText = activeText.replaceAllMapped(
        RegExp('<\\s*IF_$key\\s*>(.*?)<\\s*/\\s*IF_$key\\s*>', dotAll: true, caseSensitive: false),
        (m) => isTrue ? m.group(1)! : '',
      );
      activeText = activeText.replaceAllMapped(
        RegExp('<\\s*IF_NOT_$key\\s*>(.*?)<\\s*/\\s*IF_NOT_$key\\s*>', dotAll: true, caseSensitive: false),
        (m) => !isTrue ? m.group(1)! : '',
      );
    }
    activeText = activeText.replaceAll(RegExp(r'<IF[^>]*>.*?</IF[^>]*>', dotAll: true), '');
    
    final tagsEnTexto = RegExp(r'\[(.*?)\]').allMatches(activeText).map((m) => m.group(1)!).toSet();
    for (final tag in tagsEnTexto) {
      final val = provider.getTagValue('[$tag]')?.trim();
      if (val == null || val.isEmpty || val.startsWith('_')) {
        final tDef = TagsRepository.tagMap['[$tag]'];
        final title = tDef?.name ?? tag;
        if (!faltantes.contains(title)) {
          faltantes.add(title);
        }
      }
    }

    if (faltantes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay campos faltantes.')),
        );
      }
      return;
    }

    final typificationId = session.typificationId ?? '';
    final typification = TypificationRepository.all.firstWhere(
      (t) => t.id == typificationId,
      orElse: () => const Typification(id: '', name: '', logic: '', recommendedTemplateNames: []),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF2C2C2C),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF3D7EFF)),
            SizedBox(width: 20),
            Expanded(child: Text("Generando sugerencias con IA...", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );

    final sugerencia = await AiTacticalService.sugerirCompletadoFaltantes(faltantes, typification.name);
    
    if (context.mounted) {
      Navigator.pop(context); // close loading
      if (sugerencia == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al generar sugerencias.")),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, sugerencia);
      final newCount = currentCount + 1;
      await prefs.setInt(countKey, newCount);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF3D7EFF))),
          title: const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF3D7EFF)),
              SizedBox(width: 8),
              Expanded(child: Text('Sugerencias de IA', style: TextStyle(color: Colors.white))),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              sugerencia,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            if (newCount < 2)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetchNewAiSuggestion(context, provider, doc, session, cacheKey, countKey, newCount);
                },
                child: Text('Volver a sugerir (${2 - newCount} restantes)', style: const TextStyle(color: Color(0xFF3D7EFF))),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D7EFF)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _requestClose(BuildContext context) async {
    final provider = context.read<InterventionProvider>();
    // Auto save without asking
    await provider.saveCurrentSession();
    if (context.mounted) {
      Navigator.pop(context); // Cierra el sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progreso guardado automáticamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterventionProvider>();
    final visibleSteps = _getVisibleSteps(provider);
    final totalSteps = visibleSteps.length;

    if (_activeStepTag != null) {
      final newIndex = visibleSteps.indexWhere((s) => s.tag == _activeStepTag);
      if (newIndex != -1 && newIndex != _currentStep) {
        _currentStep = newIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(_currentStep);
          }
        });
      }
    }

    if (_currentStep >= totalSteps) {
      _currentStep = totalSteps > 0 ? totalSteps - 1 : 0;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18), onPressed: _prev)
                    else
                      const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        "Asistente Policial",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => _requestClose(context)),
                  ],
                ),
              ),
              if (_currentStep < totalSteps)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (totalSteps > 0) ? (_currentStep / totalSteps) : 0,
                          backgroundColor: Colors.white10,
                          color: const Color(0xFF3D7EFF),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Paso ${_currentStep + 1} de $totalSteps",
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalSteps + 1,
                  itemBuilder: (context, index) {
                    if (index == totalSteps) {
                      return _buildSummaryPage(provider);
                    }
                    final step = visibleSteps[index];
                    return _buildStepBody(step, provider);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D7EFF),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isDniLoading ? null : () => _next(totalSteps),
                  child: _isDniLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _currentStep < totalSteps ? "Siguiente" : "Finalizar y Cerrar",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              )
            ],
          ),
          if (_isAiReviewLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF3D7EFF)),
                    SizedBox(height: 16),
                    Text(
                      "El Perito IA está auditando el acta...",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStepBody(WizardStep step, InterventionProvider provider) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: step.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    children: const [
                      TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent, fontSize: 18)),
                    ],
                  ),
                ),
              ),
              if (step.helpText != null)
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.amber, size: 22),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Ayuda'),
                        content: Text(step.helpText!),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
                      ),
                    );
                  },
                )
            ],
          ),
          const SizedBox(height: 12),
          Text(step.description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 24),
          if (step.isDni)
            _buildApiDniFieldLocal(provider)
          else if (step.isConditionSelector)
            _buildConditionSelector(step.conditionKey!, provider)
          else
            _buildStandardField(step, provider),
        ],
      ),
    );
  }

  Widget _buildConditionSelector(String key, InterventionProvider provider) {
    final val = provider.getCondition(key);
    return Row(
      children: [
        _chipChoice("SÍ", val, () => provider.updateCondition(key, true)),
        const SizedBox(width: 12),
        _chipChoice("NO", !val, () => provider.updateCondition(key, false)),
      ],
    );
  }

  Widget _buildStandardField(WizardStep step, InterventionProvider provider) {
    final tag = step.tag;
    final currentVal = provider.getTagValue(tag) ?? '';
    final controller = _controllers.putIfAbsent(tag, () => TextEditingController(text: currentVal));
    if (controller.text != currentVal) {
      controller.text = currentVal;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    }

    // Build effective suggestions: static + recent comisarías for lugar_redaccion step
    List<String>? suggestions = step.suggestions;
    if (step.loadRecentComisarias && _recentComisarias.isNotEmpty) {
      final base = (suggestions ?? []).toSet();
      final extra = _recentComisarias.where((c) => c.isNotEmpty && !base.contains(c)).toList();
      suggestions = [...(suggestions ?? []), ...extra];
    }

    // Filter out empty strings
    suggestions = suggestions?.where((s) => s.trim().isNotEmpty).toList();
    if (suggestions != null && suggestions.isEmpty) suggestions = null;

    final hasSuggestions = suggestions != null && suggestions.isNotEmpty;
    // Determine if a suggestion has already been selected
    final isLocked = hasSuggestions && currentVal.isNotEmpty &&
        suggestions.any((s) => s.trim() == currentVal.trim());
    // Voice dictation is shown when there are NO preset suggestions (free-narration fields) and it is not explicitly disabled
    final showVoice = !hasSuggestions && !step.disableVoiceInput;
    final isThisListening = _isListening && _listeningTag == tag;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white12,
                  border: const OutlineInputBorder(),
                  hintText: showVoice ? 'Narre los hechos o use el micrófono...' : null,
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  // Animated red border when listening
                  enabledBorder: isThisListening
                      ? OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent, width: 2))
                      : const OutlineInputBorder(),
                  focusedBorder: isThisListening
                      ? OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent, width: 2))
                      : const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3D7EFF))),
                ),
                onChanged: (val) => provider.updateTagValue(tag, val),
              ),
            ),
            if (showVoice) ...[
              const SizedBox(width: 10),
              Column(
                children: [
                  // Mic button
                  GestureDetector(
                    onTap: () async {
                      if (isThisListening) {
                        // Stop listening
                        await _speech.stop();
                        setState(() { _isListening = false; _listeningTag = null; });
                      } else {
                        // Stop any other active session first
                        if (_speech.isListening) await _speech.stop();
                        final available = _speech.isAvailable || await _speech.initialize();
                        if (!available) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('El micrófono no está disponible o no se otorgaron permisos.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          return;
                        }
                        setState(() { _isListening = true; _listeningTag = tag; });
                        _speech.listen(
                          localeId: 'es_PE',
                          onResult: (result) {
                            if (result.recognizedWords.isNotEmpty) {
                              final existing = provider.getTagValue(tag) ?? '';
                              final newText = existing.isEmpty
                                  ? result.recognizedWords
                                  : '$existing ${result.recognizedWords}';
                              provider.updateTagValue(tag, newText);
                              controller.text = newText;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: newText.length),
                              );
                            }
                          },
                          listenFor: const Duration(minutes: 2),
                          pauseFor: const Duration(seconds: 5),
                          partialResults: false,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isThisListening
                            ? Colors.redAccent.withValues(alpha: 0.2)
                            : const Color(0xFF3D7EFF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isThisListening ? Colors.redAccent : const Color(0xFF3D7EFF),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isThisListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: isThisListening ? Colors.redAccent : const Color(0xFF3D7EFF),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isThisListening ? 'Detener' : 'Voz',
                    style: TextStyle(
                      fontSize: 9,
                      color: isThisListening ? Colors.redAccent : Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (isThisListening) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 4),
              const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 10),
              const SizedBox(width: 6),
              const Text(
                'Escuchando... Hable claramente en español.',
                style: TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ],
          ),
        ],
        // Suggestions chips - only shown if not locked
        if (hasSuggestions && !isLocked) ...[
          const SizedBox(height: 16),
          const Text("Sugerencias rápidas:", style: TextStyle(color: Colors.white30, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) => GestureDetector(
              onTap: () {
                provider.updateTagValue(tag, s);
                controller.text = s;
                controller.selection = TextSelection.fromPosition(TextPosition(offset: s.length));
                setState(() {}); // triggers rebuild -> isLocked becomes true -> chips hide
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            )).toList(),
          ),
        ],
        // If locked: show a small note that they can still edit manually
        if (isLocked) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Sugerencia aplicada. Puedes editar el texto manualmente si lo necesitas.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildApiDniFieldLocal(InterventionProvider provider) {
    final currentDni = provider.getTagValue('[imputado.dni]') ?? '';
    if (_dniController.text.isEmpty && currentDni.isNotEmpty) {
      _dniController.text = currentDni;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _dniController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(),
            hintText: "Ej. 71234567",
            hintStyle: TextStyle(color: Colors.white30),
          ),
          onChanged: (val) => provider.updateTagValue('[imputado.dni]', val),
        ),
      ],
    );
  }

  Widget _buildSummaryPage(InterventionProvider provider) {
    final session = provider.currentSession;
    if (session == null || session.documents.isEmpty) {
      return const Center(child: Text("Cargando resumen...", style: TextStyle(color: Colors.white)));
    }

    final doc = session.documents.firstWhere(
      (d) => d.title.toLowerCase().contains('intervención'),
      orElse: () => session.documents.first,
    );

    final filled = provider.countFilledTags(doc);
    final total = provider.countTotalTags(doc);
    final percent = total > 0 ? (filled / total * 100).toInt() : 0;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumen de Avance", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Estado de completitud del Acta de Intervención:", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white10,
                    color: percent > 75 ? Colors.greenAccent : (percent > 40 ? Colors.amberAccent : Colors.redAccent),
                  ),
                ),
                Text(
                  "$percent%",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard("Llenados", "$filled", Colors.greenAccent),
              _buildMetricCard("Faltantes", "${total - filled}", Colors.amberAccent),
              _buildMetricCard("Total", "$total", Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 32),
          Builder(builder: (ctx) {
            // Calcular campos faltantes en tiempo real
            final steps = getWizardSteps(provider);
            int missingSteps = 0;
            for (var step in steps) {
              if (step.isConditionSelector) continue;
              bool isActive = true;
              if (step.isConditional && step.conditionKey != null) {
                if (provider.getCondition(step.conditionKey!) != step.conditionValue) isActive = false;
              }
              if (!isActive) continue;
              final val = provider.sharedTags[step.tag]?.trim();
              if (val == null || val.isEmpty || val.startsWith('_')) missingSteps++;
            }

            // Contar etiquetas del acta activas sin llenar
            int missingTags = total - filled;

            final totalMissing = missingSteps + missingTags;
            final isBlocked = totalMissing > 0;

            return Column(
              children: [
                if (isBlocked)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.redAccent, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Faltan $totalMissing campo(s) por llenar ($missingSteps del Asistente, $missingTags del Acta). Completa todo para desbloquear la auditoría.',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBlocked ? Colors.grey.shade800 : const Color(0xFF14161A),
                    side: BorderSide(
                      color: isBlocked ? Colors.grey : const Color(0xFF3D7EFF),
                      width: 1.5,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    isBlocked ? Icons.lock : Icons.psychology,
                    color: isBlocked ? Colors.grey : const Color(0xFF3D7EFF),
                  ),
                  label: Text(
                    isBlocked
                        ? '⛔ Bloqueado — $totalMissing campo(s) pendientes'
                        : 'Revisar y Auditar con IA',
                    style: TextStyle(
                      color: isBlocked ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: isBlocked ? null : () => _runAiReview(context, provider),
                ),
                if (isBlocked) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D7EFF).withValues(alpha: 0.2),
                      side: const BorderSide(color: Color(0xFF3D7EFF), width: 1.5),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.lightbulb_outline, color: Color(0xFF3D7EFF)),
                    label: const Text(
                      'Sugerir cómo llenar lo faltante con IA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      _showAiSuggestionsForMissingFields(context, provider);
                    },
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF262A35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _chipChoice(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D7EFF) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
