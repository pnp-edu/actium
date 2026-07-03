import '../models/wizard_step.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/intervention_session.dart';
import '../providers/intervention_provider.dart';
import '../services/ai_tactical_service.dart';
import 'acta_view_mode.dart';
import '../widgets/custom_app_drawer.dart';
import 'live_intervention_sheet.dart';
import '../models/typification.dart';
import '../models/typification_repository.dart';
import '../widgets/ai_grill_sheet.dart';
import '../widgets/export_config_dialog.dart';
import '../services/word_service.dart';
import 'main_menu_page.dart';
import '../services/template_service.dart';
import '../models/template.dart';



class InterventionSessionPage extends StatefulWidget {
  final bool showLiveWizard;

  const InterventionSessionPage({super.key, this.showLiveWizard = false});

  @override
  State<InterventionSessionPage> createState() => _InterventionSessionPageState();
}

class _InterventionSessionPageState extends State<InterventionSessionPage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  void _showLiveAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) => const LiveInterventionSheet(),
        ),
      ),
    ).whenComplete(() {
      _saveDocumentSilently();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.showLiveWizard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLiveAssistantSheet(context);
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      _saveDocumentSilently();
    }
  }

  Future<void> _saveDocumentSilently() async {
    final provider = context.read<InterventionProvider>();
    if (provider.currentSession != null) {
      await provider.saveCurrentSession();
    }
  }
  bool _auditing = false;

  // ── Diálogo de confirmación de salida ──────────────────────────
  Future<bool> _onWillPop() async {
    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;
    
    if (session == null) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.white),
            SizedBox(width: 10),
            Text('Salir de la Intervención', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          '¿Deseas guardar tu progreso antes de regresar al menú principal para iniciar una nueva intervención?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('No guardar', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Sí, guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel') {
      return false; // No salir
    }

    if (result == 'save') {
      await provider.saveCurrentSession();
      await _checkAndPromptTemplateUpdate();
    } 

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainMenuPage()),
        (route) => false,
      );
    }
    
    return false;
  }





  Future<void> _checkAndPromptTemplateUpdate() async {
    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;
    if (session == null) return;

    final templateService = TemplateService();
    final templates = await templateService.loadTemplates();
    
    List<InterventionDocument> modifiedDocs = [];
    
    for (var doc in session.documents) {
      final t = templates.where((t) => t.name == doc.title).firstOrNull;
      if (t != null && t.content != doc.content) {
        modifiedDocs.add(doc);
      }
    }

    if (modifiedDocs.isEmpty) return;
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Row(
          children: [
            Icon(Icons.update, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Actualizar Plantillas', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'Se han detectado cambios en el texto base de ${modifiedDocs.length} acta(s).\n\n'
          '¿Deseas que estos cambios se guarden permanentemente en las plantillas para futuras intervenciones, o solo guardar para este caso particular?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Solo este caso', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Actualizar plantillas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      for (var doc in modifiedDocs) {
        final t = templates.firstWhere((t) => t.name == doc.title);
        final updatedTemplate = Template(
          id: t.id,
          name: t.name,
          content: doc.content,
          isSystem: t.isSystem,
          createdBy: t.createdBy,
        );
        await templateService.saveTemplate(updatedTemplate);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plantillas base actualizadas exitosamente.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }



  List<String> _getMissingFields(InterventionProvider provider, InterventionDocument doc) {
    List<String> faltantes = [];

    // 1. Validar PASOS DEL ASISTENTE activos
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

    // 2. Validar ETIQUETAS DEL DOCUMENTO (Modo Completar)
    String activeText = doc.content;
    const conditionKeys = [
      'ACOMPANANTE', 'FISCAL', 'VEHICULO', 'DETENIDO', 'COMISARIA',
      'MENOR', 'EXTRANJERO', 'HERIDO',
    ];
    for (final key in conditionKeys) {
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
    activeText = activeText.replaceAll(RegExp(r'</?\s*IF_[A-Z0-9_]+\s*>', caseSensitive: false), '');

    final tagExp = RegExp(r'\[([^\]]+)\]');
    for (final m in tagExp.allMatches(activeText)) {
      final tagKey = m.group(0)!;
      final tagLabel = m.group(1)!;
      final val = provider.sharedTags[tagKey]?.trim();
      if (val == null || val.isEmpty || val.startsWith('_')) {
        if (!faltantes.contains(tagLabel)) {
          faltantes.add(tagLabel);
        }
      }
    }

    return faltantes;
  }

  String _compileDocumentText(InterventionDocument doc, InterventionProvider provider) {
    const conditionKeys = [
      'ACOMPANANTE', 'FISCAL', 'VEHICULO', 'DETENIDO', 'COMISARIA',
      'MENOR', 'EXTRANJERO', 'HERIDO',
    ];
    String text = doc.content;

    for (final key in conditionKeys) {
      final condTrue = provider.getCondition(key);

      // <IF_KEY>…</IF_KEY>
      final ifRegex = RegExp(
        '<\\s*IF_$key\\s*>(.*?)<\\s*/\\s*IF_$key\\s*>',
        dotAll: true,
        caseSensitive: false,
      );
      text = text.replaceAllMapped(ifRegex, (m) => condTrue ? m.group(1)! : '');

      // <IF_NOT_KEY>…</IF_NOT_KEY>
      final ifNotRegex = RegExp(
        '<\\s*IF_NOT_$key\\s*>(.*?)<\\s*/\\s*IF_NOT_$key\\s*>',
        dotAll: true,
        caseSensitive: false,
      );
      text = text.replaceAllMapped(ifNotRegex, (m) => !condTrue ? m.group(1)! : '');
    }

    // Safety net: remove any remaining unknown <IF_...> tags
    text = text.replaceAll(RegExp(r'</?IF_[A-Z0-9_]+>', caseSensitive: false), '');

    final tagRegex = RegExp(r'\[(.*?)\]');
    text = text.replaceAllMapped(tagRegex, (match) {
      final tagString = match.group(0)!;
      final val = provider.getTagValue(tagString);
      if (val != null && val.isNotEmpty) {
        return val;
      }
      return tagString;
    });

    return text;
  }

  Future<void> _runAiReview() async {
    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;
    if (session == null || session.documents.isEmpty) return;

    final doc = session.documents[_currentIndex];

    // ══════════════════════════════════════════════════════════
    // BLOQUEO ESTRICTO: nada pasa a la IA si faltan campos
    // ══════════════════════════════════════════════════════════
    final faltantes = _getMissingFields(provider, doc);

    if (faltantes.isNotEmpty) {
      final list = faltantes.take(8).map((e) => '\u2022 $e').join('\n');
      final more = faltantes.length > 8 ? '\n...y ${faltantes.length - 8} campo(s) más.' : '';
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.lock, color: Colors.redAccent, size: 22),
                SizedBox(width: 8),
                Text('Auditoría Bloqueada', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'Debes llenar todos los campos antes de auditar.\n'
                'Campos faltantes (${faltantes.length}):\n\n'
                '$list$more\n\n'
                'Completa el Asistente y el Modo Completar primero.',
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido, voy a completarlos', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      return; // BLOQUEO TOTAL
    }

    final apiKey = await AiTacticalService.getOrLoadToken();
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
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

    setState(() => _auditing = true);

    final compiledText = _compileDocumentText(doc, provider);
    final result = await AiTacticalService.pulirRedaccionLegal(
      compiledText,
      typificationName: typification.name,
      typificationLogic: typification.logic,
    );

    setState(() => _auditing = false);

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al comunicarse con la Inteligencia Artificial.")),
        );
      }
      return;
    }

    if (mounted) {
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



  // ── Motor de exportación ───────────────────────────────────────────────────
  Future<void> _exportarCarpetaFiscal() async {
    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;
    if (session == null || session.documents.isEmpty) return;

    final doc = session.documents[_currentIndex];
    final faltantes = _getMissingFields(provider, doc);

    if (faltantes.isNotEmpty) {
      final list = faltantes.take(8).map((e) => '\u2022 $e').join('\n');
      final more = faltantes.length > 8 ? '\n...y ${faltantes.length - 8} campo(s) más.' : '';
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.lock, color: Colors.redAccent, size: 22),
                SizedBox(width: 8),
                Text('Exportación Bloqueada', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'Debes llenar todos los campos antes de exportar.\n'
                'Campos faltantes (${faltantes.length}):\n\n'
                '$list$more\n\n'
                'Completa el Asistente y el Modo Completar primero.',
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido, voy a completarlos', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      return; // BLOQUEO TOTAL DE EXPORTACIÓN
    }

    if (!mounted) return;

    // Mostrar lista plegable (Modal Bottom Sheet) con opciones PDF / Word
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Opciones de Exportación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.greenAccent),
                title: const Text('Exportar como PDF', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final config = await showDialog<ExportConfig>(
                    context: context,
                    builder: (c) => const ExportConfigDialog(format: 'PDF'),
                  );
                  if (config != null) {
                    _generarYExportarPdf(provider, session, config: config);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blueAccent),
                title: const Text('Exportar como Word', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final config = await showDialog<ExportConfig>(
                    context: context,
                    builder: (c) => const ExportConfigDialog(format: 'Word'),
                  );
                  if (config != null) {
                    _generarYExportarWord(provider, session, config: config);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generarYExportarWord(InterventionProvider provider, InterventionSession session, {ExportConfig? config}) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando Word...')));
      await WordService.exportarCarpetaWord(session, provider.sharedTags, config);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade800,
        content: Text('Error al exportar Word: $e', style: const TextStyle(color: Colors.white)),
      ));
    }
  }

  Future<void> _generarYExportarPdf(InterventionProvider provider, InterventionSession session, {ExportConfig? config}) async {
    try {
      final pdfBytes = await provider.generarCarpetaFiscal();
      if (!mounted) return;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = session.name.replaceAll(' ', '_');
      final fileName = 'Carpeta_Fiscal_${name}_$ts.pdf';

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade800,
        content: Text('Error al exportar PDF: $e', style: const TextStyle(color: Colors.white)),
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterventionProvider>();
    final session = provider.currentSession;

    if (session == null) {
      return const Scaffold(
          body: Center(child: Text('No hay sesión activa')));
    }

    final doc =
        session.documents.isEmpty ? null : session.documents[_currentIndex];
    final totalTags = doc != null ? provider.countTotalTags(doc) : 0;
    final filledTags = doc != null ? provider.countFilledTags(doc) : 0;
    final progress = totalTags > 0 ? filledTags / totalTags : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const CustomAppDrawer(isSessionPage: true),
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: TextFormField(
                          initialValue: session.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) {
                            session.name = val;
                          },
                          onFieldSubmitted: (val) async {
                            session.name = val;
                            await context.read<InterventionProvider>().saveCurrentSession();
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit, color: Colors.white54, size: 16),
                    ],
                  ),
                  if (doc != null && totalTags > 0)
                    Text(
                      '$filledTags de $totalTags campos completados',
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          bottom: totalTags > 0
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? Colors.greenAccent
                          : Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 4,
                  ),
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Color(0xFF9E7BFF)),
              tooltip: 'Auditoría con IA (Perito)',
              onPressed: _runAiReview,
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.greenAccent),
              tooltip: 'Exportar Carpeta Fiscal',
              onPressed: _exportarCarpetaFiscal,
            ),
            const SizedBox(width: 8),
          ],
        ),

        // ── CUERPO: Vista del acta activa ───────────────────────
        body: Stack(
          children: [
            session.documents.isEmpty
                ? const Center(
                    child: Text('No hay documentos en esta sesión',
                        style: TextStyle(color: Colors.white54)))
                : Column(
                    children: [
                      // Acta activa
                      Expanded(
                        child: _buildActaContent(session, _currentIndex),
                      ),
                    ],
                  ),
            if (_auditing)
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
              ),
          ],
        ),

        // ── BOTTOM NAV: Navegador de actas ──────────────────────
        bottomNavigationBar: session.documents.length > 1
            ? _buildBottomNav(session.documents)
            : null,
        floatingActionButton: _AssistantFab(
          onPressed: () => _showLiveAssistantSheet(context),
        ),
      ),
    );
  }

  // ── Widget selector de vista según tipo de acta ────────────────
  Widget _buildActaContent(InterventionSession session, int index) {
    return ActaViewMode(document: session.documents[index]);
  }


  // ── Navegador horizontal de actas (bottom nav) ─────────────────
  Widget _buildBottomNav(List<InterventionDocument> docs) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(docs.length, (index) {
              final isSelected = _currentIndex == index;
              final doc = docs[index];
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 70,
                        child: Text(
                          doc.title,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AI Robot Assistant FAB — Premium animated button
// ══════════════════════════════════════════════════════════════════════════════
class _AssistantFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _AssistantFab({required this.onPressed});

  @override
  State<_AssistantFab> createState() => _AssistantFabState();
}

class _AssistantFabState extends State<_AssistantFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E80F0).withValues(alpha: _glow.value),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0D1B4B).withValues(alpha: 0.8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF42A5F5).withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: widget.onPressed,
                  splashColor: Colors.white.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Robot Icon with glow
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASISTENTE IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              'Completar acta en vivo',
                              style: TextStyle(
                                color: Color(0xFF90CAF9),
                                fontSize: 9,
                                letterSpacing: 0.3,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Pulsing dot indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              const Color(0xFF69F0AE),
                              const Color(0xFF00BFA5),
                              _glow.value,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF69F0AE).withValues(alpha: _glow.value),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
