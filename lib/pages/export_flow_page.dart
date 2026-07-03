import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/intervention_session.dart';
import '../providers/intervention_provider.dart';
import '../services/ai_tactical_service.dart';
import 'acta_editor_view.dart';

// ── Fases del flujo de exportación ──────────────────────────────────────────
enum _ExportPhase { auditing, reviewErrors, preview, exporting }

/// Página dedicada que gestiona el flujo completo de exportación con auditoría
/// IA en 3 pasos: auditar → revisar errores → vista previa → exportar.
///
/// También puede usarse en modo [auditOnly] = true para la auditoría
/// individual del Acta de Intervención (sin exportar).
class ExportFlowPage extends StatefulWidget {
  /// Si es true, solo audita el Acta de Intervención y aplica correcciones.
  /// No muestra vista previa ni exporta.
  final bool auditOnly;

  /// Si es true, salta la fase de auditoría e inicia directamente en vista previa.
  final bool skipAudit;

  const ExportFlowPage({
    super.key,
    this.auditOnly = false,
    this.skipAudit = false,
  });

  @override
  State<ExportFlowPage> createState() => _ExportFlowPageState();
}

class _ExportFlowPageState extends State<ExportFlowPage> {
  _ExportPhase _phase = _ExportPhase.auditing;
  List<AuditIssue> _issues = [];
  final List<_EditableIssue> _editables = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.skipAudit) {
        setState(() => _phase = _ExportPhase.preview);
      } else {
        _runAudit();
      }
    });
  }

  @override
  void dispose() {
    for (final e in _editables) {
      e.controller.dispose();
    }
    super.dispose();
  }

  // ── Auditoría IA ─────────────────────────────────────────────────────────
  Future<void> _runAudit() async {
    if (!mounted) return;
    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;
    if (session == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _phase = _ExportPhase.auditing;
      _errorMessage = null;
      _issues = [];
      _editables.clear();
    });

    AuditResult? result;

    // Buscar el Acta de Intervención Policial para auditarla (es la principal)
    final actaDoc = session.documents.firstWhere(
      (d) {
        final t = d.title.toLowerCase();
        return t.contains('intervenci') || t.contains('acta de intervención') || t.contains('acta de intervencion');
      },
      orElse: () => session.documents.firstWhere(
        (d) => d.title.toLowerCase().contains('acta'),
        orElse: () => session.documents.first,
      ),
    );
    final texto = _resolverTexto(actaDoc, provider);
    result = await AiTacticalService.auditarActaIntervencion(texto);

    if (!mounted) return;

    if (result == null) {
      // Error de red o API Key inválida
      final checkToken = await AiTacticalService.getOrLoadToken();
      if (!mounted) return;
      if (checkToken == null) {
        setState(() => _errorMessage = 'API Key inválida o no configurada.');
      }
      if (widget.auditOnly) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠ Sin conexión — Auditoría no disponible'),
          backgroundColor: Colors.orangeAccent,
        ));
        Navigator.pop(context);
        return;
      }
      // Sin conexión → ir directo a vista previa sin bloquear exportación
      setState(() => _phase = _ExportPhase.preview);
      return;
    }

    if (result.sinProblemas) {
      if (widget.auditOnly) {
        // Auditoría individual: sin errores → mostrar éxito y cerrar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('✅ Acta de Intervención sin observaciones. ¡Excelente redacción!'),
            ),
          ]),
          backgroundColor: Colors.green.shade800,
        ));
        Navigator.pop(context);
        return;
      }
      // Sin errores → ir directo a vista previa
      setState(() => _phase = _ExportPhase.preview);
      return;
    }

    // Hay errores → construir lista de campos editables
    _issues = result.issues;
    _editables.clear();
    final currentTags = Map<String, String>.from(provider.sharedTags);
    for (final issue in _issues) {
      _editables.add(_EditableIssue(
        issue: issue,
        controller: TextEditingController(
          text: (issue.tag != 'general') ? (currentTags[issue.tag] ?? '') : '',
        ),
      ));
    }

    setState(() => _phase = _ExportPhase.reviewErrors);
  }

  /// Resuelve el texto del acta sustituyendo tags por sus valores actuales.
  String _resolverTexto(InterventionDocument doc, InterventionProvider provider) {
    final requiereFiscal =
        provider.getTagValue('[intervencion.requiere_fiscal]') != 'NO';
    String texto = doc.content;
    if (!requiereFiscal) {
      final regex = RegExp(
        r'II\.\s+COMUNICACIÓN\s+AL\s+MINISTERIO\s+PÚBLICO[\s\S]*?(?=III\.)',
        caseSensitive: false,
      );
      texto = texto.replaceAll(regex, '');
    }
    final tagRegex = RegExp(r'\[(.*?)\]');
    texto = texto.replaceAllMapped(tagRegex, (match) {
      final tag = match.group(0)!;
      final val = provider.getTagValue(tag);
      return (val != null && val.isNotEmpty) ? val : '[CAMPO VACÍO: $tag]';
    });
    return texto;
  }

  // ── Confirmar correcciones y avanzar ─────────────────────────────────────
  Future<void> _confirmarCorrecciones() async {
    if (!mounted) return;
    final provider = context.read<InterventionProvider>();

    // Aplicar cada corrección editada al provider
    for (final editable in _editables) {
      if (editable.issue.tag != 'general') {
        final newValue = editable.controller.text.trim();
        if (newValue.isNotEmpty) {
          provider.updateTagValue(editable.issue.tag, newValue);
        }
      }
    }

    if (widget.auditOnly) {
      // En modo auditoría individual → cerrar y volver
      Navigator.pop(context);
      return;
    }

    setState(() => _phase = _ExportPhase.preview);
  }

  // ── Exportar la carpeta fiscal ────────────────────────────────────────────
  Future<void> _exportar() async {
    if (!mounted) return;
    setState(() => _phase = _ExportPhase.exporting);

    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;

    try {
      final pdfBytes = await provider.generarCarpetaFiscal();
      if (!mounted) return;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = session?.name.replaceAll(' ', '_') ?? 'expediente';
      final fileName = 'Carpeta_Fiscal_${name}_$ts.pdf';

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: fileName,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade800,
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Error al generar la Carpeta Fiscal: $e',
                style: const TextStyle(color: Colors.white)),
          ),
        ]),
        duration: const Duration(seconds: 6),
      ));
      setState(() => _phase = _ExportPhase.preview);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;

    final String appBarTitle;
    switch (_phase) {
      case _ExportPhase.auditing:
        appBarTitle =
            widget.auditOnly ? 'Auditando Acta' : 'Auditando Expediente';
        break;
      case _ExportPhase.reviewErrors:
        appBarTitle = 'Errores Encontrados';
        break;
      case _ExportPhase.preview:
        appBarTitle = 'Vista Previa';
        break;
      case _ExportPhase.exporting:
        appBarTitle = 'Exportando…';
        break;
    }

    final theme = Theme.of(context);
    final canGoBack = _phase != _ExportPhase.auditing &&
        _phase != _ExportPhase.exporting;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                onPressed: () {
                  if (_phase == _ExportPhase.reviewErrors) {
                    Navigator.pop(context);
                  } else if (_phase == _ExportPhase.preview) {
                    if (_issues.isNotEmpty && !widget.skipAudit) {
                      setState(() => _phase = _ExportPhase.reviewErrors);
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
              )
            : null,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          // Indicador de pasos (solo para flujo completo)
          if (!widget.auditOnly)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildStepIndicator(),
            ),
        ],
      ),
      body: _buildBody(provider, session),
    );
  }

  // ── Indicador de progreso en 3 pasos ─────────────────────────────────────
  Widget _buildStepIndicator() {
    final int currentStep;
    switch (_phase) {
      case _ExportPhase.auditing:
        currentStep = 0;
        break;
      case _ExportPhase.reviewErrors:
        currentStep = 1;
        break;
      case _ExportPhase.preview:
      case _ExportPhase.exporting:
        currentStep = 2;
        break;
    }

    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= currentStep;
        final isCurrent = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(left: 4),
          width: isCurrent ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1E90FF)
                : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ── Router de fases ───────────────────────────────────────────────────────
  Widget _buildBody(InterventionProvider provider, InterventionSession? session) {
    switch (_phase) {
      case _ExportPhase.auditing:
        return _buildAuditingPhase();
      case _ExportPhase.reviewErrors:
        return _buildReviewErrorsPhase(provider);
      case _ExportPhase.preview:
        return _buildPreviewPhase(provider, session);
      case _ExportPhase.exporting:
        return _buildExportingPhase(session);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FASE 1 — AUDITANDO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAuditingPhase() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E3A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2FFF).withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    color: Color(0xFF7B2FFF),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Auditando expediente...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'La IA está revisando la consistencia legal\nde todos los campos antes de exportar',
              style: TextStyle(
                  color: Colors.white54, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FASE 2 — ERRORES ENCONTRADOS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReviewErrorsPhase(InterventionProvider provider) {
    return Column(
      children: [
        // ── Banner de errores ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border(
              bottom: BorderSide(
                  color: Colors.red.withValues(alpha: 0.3), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ERRORES ENCONTRADOS (${_issues.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Corrige los campos marcados y confirma para continuar',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Lista de errores editables ─────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _editables.length,
            itemBuilder: (context, index) =>
                _buildIssueCard(_editables[index], index),
          ),
        ),

        // ── Botón confirmar ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.white),
                label: Text(
                  widget.auditOnly
                      ? 'CONFIRMAR CORRECCIONES'
                      : 'CONFIRMAR Y CONTINUAR →',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: _confirmarCorrecciones,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card individual de un error con campo editable.
  Widget _buildIssueCard(_EditableIssue editable, int index) {
    final issue = editable.issue;
    final isGeneral = issue.tag == 'general';
    final tagLabel = isGeneral
        ? 'Observación General'
        : issue.tag
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('.', ' → ');

    return Container(
      key: ValueKey('issue_${index}_${issue.tag}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.red.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.label_outline,
                    color: Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'etiqueta [$tagLabel]',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cuerpo de la card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripción del problema
                Text(
                  issue.problema,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                // Label "corrige:"
                const Text(
                  'corrige:',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Campo editable (solo si tiene tag específico)
                if (!isGeneral)
                  TextField(
                    controller: editable.controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: issue.correccion,
                      hintStyle: const TextStyle(
                          color: Colors.white24, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF1E80F0), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  )
                else
                  // Para issues generales: solo mostrar la corrección sugerida
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      issue.correccion,
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FASE 3 — VISTA PREVIA
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPreviewPhase(
      InterventionProvider provider, InterventionSession? session) {
    if (session == null || session.documents.isEmpty) {
      return const Center(
        child: Text('No hay documentos en esta sesión',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return Column(
      children: [
        // ── Sub-header ─────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Icon(Icons.visibility_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 15),
              const SizedBox(width: 8),
              Text(
                '${session.documents.length} hoja${session.documents.length != 1 ? 's' : ''} — toca 🖊 para editar',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),

        // ── Lista de hojas ─────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: session.documents.length,
            itemBuilder: (context, index) {
              final doc = session.documents[index];
              return _buildActaPreviewCard(doc, index, provider);
            },
          ),
        ),

        // ── Botón exportar ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  shadowColor:
                      const Color(0xFF00C853).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.picture_as_pdf,
                    color: Colors.white, size: 22),
                label: const Text(
                  'EXPORTAR CARPETA FISCAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: _exportar,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card de vista previa de un acta individual con botón lápiz.
  Widget _buildActaPreviewCard(
      InterventionDocument doc, int index, InterventionProvider provider) {
    // Generar texto preview resolviendo tags
    String previewText = doc.content;
    final regex = RegExp(r'\[(.*?)\]');
    previewText = previewText.replaceAllMapped(regex, (match) {
      final tag = match.group(0)!;
      final val = provider.getTagValue(tag);
      return (val != null && val.isNotEmpty) ? val : '____';
    });
    final previewLines = previewText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(4)
        .join('\n');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOJA ${index + 1} / ${context.read<InterventionProvider>().currentSession?.documents.length ?? '?'}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        doc.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // ── Botón lápiz ───────────────────────────────────────────
                InkWell(
                  onTap: () => _openEditor(context, doc),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Preview del contenido ──────────────────────────────────────
          if (doc.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Text(
                previewLines.isEmpty ? '(Sin contenido)' : previewLines,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Text(
                'Sin plantilla creada aún',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  /// Abre el editor de un acta. Al volver, la vista previa se refresca.
  Future<void> _openEditor(BuildContext context, InterventionDocument doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ActaEditorPage(document: doc),
      ),
    );
    // Al regresar, forzar rebuild para reflejar cambios en el preview
    if (mounted) setState(() {});
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FASE 4 — EXPORTANDO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildExportingPhase(InterventionSession? session) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Generando Carpeta Fiscal…',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              session != null
                  ? 'Foliando ${session.documents.length} actas\ny calculando hash SHA-256'
                  : 'Procesando documentos...',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Página envoltorio para ActaEditorView (que es un Column, no un Scaffold)
// Se usa en la vista previa para abrir el editor de un acta específica.
// ══════════════════════════════════════════════════════════════════════════════
class _ActaEditorPage extends StatelessWidget {
  final InterventionDocument document;

  const _ActaEditorPage({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          tooltip: 'Volver a vista previa',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          document.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check, color: Color(0xFF00C853), size: 18),
            label: const Text(
              'Guardar',
              style: TextStyle(
                color: Color(0xFF00C853),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ActaEditorView(document: document),
    );
  }
}

/// Clase auxiliar que une un [AuditIssue] con su [TextEditingController] editable.
class _EditableIssue {
  final AuditIssue issue;
  final TextEditingController controller;

  _EditableIssue({required this.issue, required this.controller});
}
