// ════════════════════════════════════════════════════════════════════════════
// ai_tactical_panel.dart — Panel de IA Táctica
// Fase 5 · ACTIUM v1.5
//
// BottomSheet accesible desde InterventionSessionPage que agrupa las
// herramientas de IA de Narrativa (Original vs IA en 2 Pestañas) y
// Síntesis del Parte Policial.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/intervention_provider.dart';
import '../services/ai_tactical_service.dart';

/// Muestra el Panel de IA Táctica como un BottomSheet modal.
void showAiTacticalPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _AiTacticalPanelSheet(),
    ),
  );
}

class _AiTacticalPanelSheet extends StatefulWidget {
  const _AiTacticalPanelSheet();

  @override
  State<_AiTacticalPanelSheet> createState() => _AiTacticalPanelSheetState();
}

class _AiTacticalPanelSheetState extends State<_AiTacticalPanelSheet> {
  // ── Estado general ───────────────────────────────────────────────────────
  bool _loadingLegal = false;
  bool _dictando = false;
  bool _loadingParte = false;
  bool _sinConexion = false;

  // ── Función 2: Candado Semántico y Dictado Táctico ───────────────────────
  final _originalController = TextEditingController();
  final _iaController = TextEditingController();
  int _activeNarrativaTab = 0; // 0: Original, 1: IA Mejorada
  List<String> _observacionesTacticas = [];

  @override
  void dispose() {
    _originalController.dispose();
    _iaController.dispose();
    AiTacticalService.detenerDictado();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FUNCIÓN 2 — CANDADO SEMÁNTICO (Filtro Legal)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _pulirRedaccion() async {
    if (_originalController.text.trim().isEmpty) return;

    setState(() {
      _loadingLegal = true;
      _sinConexion = false;
      _observacionesTacticas = [];
    });

    final resultado = await AiTacticalService.pulirRedaccionLegal(
      _originalController.text,
    );

    if (!mounted) return;

    if (resultado == null) {
      setState(() {
        _loadingLegal = false;
        _sinConexion = true;
      });
      return;
    }

    _iaController.text = resultado.textoAuditado;
    _observacionesTacticas = resultado.observacionesTacticas;

    setState(() {
      _loadingLegal = false;
      _activeNarrativaTab = 1; // Cambiar automáticamente a la pestaña de IA
    });
    _mostrarExito('✓ Redacción mejorada por IA. Puedes revisarla y editarla en su pestaña.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FUNCIÓN 3 — DICTADO TÁCTICO (STT)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _toggleDictado() async {
    if (_dictando) {
      await AiTacticalService.detenerDictado();
      setState(() => _dictando = false);
    } else {
      setState(() {
        _dictando = true;
        _activeNarrativaTab = 0; // Forzar la visualización de la pestaña original
      });
      await AiTacticalService.iniciarDictado(
        onResult: (texto) {
          if (!mounted) return;
          _originalController.text = texto;
        },
      );
    }
  }

  void _aplicarNarrativa(String texto, String origen) {
    if (texto.trim().isEmpty) return;
    context.read<InterventionProvider>().updateTagValue('[narrativa.hechos]', texto);
    _mostrarExito('✓ Versión ($origen) aplicada a los hechos del acta');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FUNCIÓN 5 — SÍNTESIS PARTE POLICIAL
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _sintetizarParte() async {
    setState(() {
      _loadingParte = true;
      _sinConexion = false;
    });

    final tags = Map<String, String>.from(
      context.read<InterventionProvider>().sharedTags,
    );
    final resumen = await AiTacticalService.sintetizarPartePolicial(tags);

    if (!mounted) return;

    if (resumen == null) {
      setState(() {
        _loadingParte = false;
        _sinConexion = true;
      });
      return;
    }

    context.read<InterventionProvider>().updateTagValue('[parte.resumen_ai]', resumen);
    setState(() => _loadingParte = false);
    _mostrarExito('✓ Resumen del Parte Policial generado');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS UI
  // ─────────────────────────────────────────────────────────────────────────
  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _sectionHeader(String titulo, IconData icono, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool loading = false,
    bool active = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: active
              ? color
              : color.withValues(alpha: 0.15),
          foregroundColor: active ? Colors.white : color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: active ? Colors.white : color,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          loading ? 'Procesando...' : label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Pre-cargar narrativa actual del provider
    final currentNarrativa = context.read<InterventionProvider>()
        .getTagValue('[narrativa.hechos]') ?? '';
    if (_originalController.text.isEmpty && currentNarrativa.isNotEmpty) {
      _originalController.text = currentNarrativa;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_alt, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IA Táctica',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Powered by Groq Cloud · llama-3.3-70b-versatile',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Banner de sin conexión
              if (_sinConexion)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '⚠ Error de conexión — La API Key es inválida o no responde. Verifica tus ajustes.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Contenido scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [

                    // ─── NARRATIVA INTELIGENTE (F2-F3) ─
                    _sectionHeader(
                      'F2·F3 · Narrativa Inteligente',
                      Icons.auto_fix_high,
                      theme.colorScheme.tertiary,
                    ),
                    Text(
                      'Edita o dicta tu narrativa original en tiempo real. Luego, presiona "Pulir Redacción Legal" para obtener y ajustar la versión mejorada por la IA.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    // Selector de Pestañas
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _activeNarrativaTab = 0);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _activeNarrativaTab == 0
                                        ? theme.colorScheme.tertiary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Original / Dictado',
                                style: TextStyle(
                                  color: _activeNarrativaTab == 0
                                      ? theme.colorScheme.tertiary
                                      : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _activeNarrativaTab = 1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _activeNarrativaTab == 1
                                        ? theme.colorScheme.tertiary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Mejorado por IA ✨',
                                style: TextStyle(
                                  color: _activeNarrativaTab == 1
                                      ? theme.colorScheme.tertiary
                                      : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Contenido según la pestaña activa
                    if (_activeNarrativaTab == 0) ...[
                      // Campo de narrativa original
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _dictando ? theme.colorScheme.tertiary : Colors.white12,
                            width: _dictando ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _originalController,
                              maxLines: 6,
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Redacta la narrativa original de los hechos aquí o usa el micrófono...',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              onChanged: (val) {
                                context.read<InterventionProvider>()
                                    .updateTagValue('[narrativa.hechos]', val);
                              },
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.white12)),
                              ),
                              child: Row(
                                children: [
                                  if (_dictando)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                                          SizedBox(width: 6),
                                          Text(
                                            'DICTANDO...',
                                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      _dictando ? Icons.mic : Icons.mic_none,
                                      color: _dictando ? Colors.red : Colors.white38,
                                      size: 22,
                                    ),
                                    onPressed: _toggleDictado,
                                    tooltip: _dictando ? 'Detener dictado' : 'Iniciar dictado',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _aiButton(
                              label: '⚖️ Pulir Redacción',
                              icon: Icons.auto_awesome,
                              color: theme.colorScheme.tertiary,
                              loading: _loadingLegal,
                              onPressed: _pulirRedaccion,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _aplicarNarrativa(_originalController.text, 'Original'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4D2E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Aplicar Original', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Si hay observaciones tácticas, mostrarlas en una cajita elegante
                      if (_observacionesTacticas.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Observaciones del Perito IA:',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._observacionesTacticas.map((obs) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: Colors.amber, fontSize: 13)),
                                        Expanded(
                                          child: Text(
                                            obs,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                      // Campo de narrativa mejorada por IA
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _iaController,
                          maxLines: 6,
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'La versión mejorada por la IA se mostrará aquí para que la edites...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _aiButton(
                              label: '⚖️ Volver a Pulir',
                              icon: Icons.refresh,
                              color: Colors.orangeAccent,
                              loading: _loadingLegal,
                              onPressed: _pulirRedaccion,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _aplicarNarrativa(_iaController.text, 'IA Mejorada'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Aplicar IA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(color: Colors.white12, height: 40),

                    // ─── FUNCIÓN 5: SÍNTESIS PARTE POLICIAL ──────────
                    _sectionHeader(
                      'F5 · Síntesis del Parte Policial',
                      Icons.summarize_outlined,
                      theme.colorScheme.secondary,
                    ),
                    Text(
                      'Genera automáticamente el resumen ejecutivo de 3 párrafos para la sección "II. AMPLIACIÓN DETALLADA" del Formato 61.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    _aiButton(
                      label: 'Generar Resumen del Parte',
                      icon: Icons.auto_stories,
                      color: theme.colorScheme.secondary,
                      loading: _loadingParte,
                      onPressed: _sintetizarParte,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El resumen se guardará automáticamente en [parte.resumen_ai] y se incluirá al exportar la Carpeta Fiscal.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
