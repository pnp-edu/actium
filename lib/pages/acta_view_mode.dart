import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../utils/quill_content_helper.dart';
import '../models/intervention_session.dart';
import '../models/tags.dart';
import '../providers/intervention_provider.dart';
import 'acta_editor_view.dart';

/// Read-only interactive view for intervention mode with preview/edit toggle.
/// Tags appear as tappable inline chips — no raw text editing allowed.
class ActaViewMode extends StatefulWidget {
  final InterventionDocument document;

  const ActaViewMode({super.key, required this.document});

  @override
  State<ActaViewMode> createState() => _ActaViewModeState();
}

class _ActaViewModeState extends State<ActaViewMode>
    with SingleTickerProviderStateMixin {
  // true = preview compiled text, false = edit mode (tag chips)
  bool _isPreviewMode = false;
  bool _isEditingRaw = false;
  late QuillController _quillController;
  late final AnimationController _toggleAnim;

  @override
  void initState() {
    super.initState();
    _initQuillController(widget.document.content);
    _toggleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  void _initQuillController(String content) {
    final initialDoc = QuillContentHelper.documentFromContent(content);
    _quillController = QuillController(
      document: Document.fromDelta(QuillContentHelper.transformOnLoad(initialDoc.toDelta())),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController.document.changes.listen((_) => _saveContent());
  }

  @override
  void didUpdateWidget(ActaViewMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id) {
      _initQuillController(widget.document.content);
      _isEditingRaw = false;
    }
  }

  void _saveContent() {
    widget.document.content = QuillContentHelper.transformOnSave(_quillController.document.toDelta());
  }

  @override
  void dispose() {
    _quillController.dispose();
    _toggleAnim.dispose();
    super.dispose();
  }

  String _getFilteredContent(String content, bool requiereFiscal) {
    if (requiereFiscal) return content;

    final regex = RegExp(
      r'II\.\s+COMUNICACIÓN\s+AL\s+MINISTERIO\s+PÚBLICO[\s\S]*?(?=III\.)',
      caseSensitive: false,
    );
    String filtered = content.replaceAll(regex, '');

    filtered = filtered.replaceAllMapped(RegExp(r'(?<=^|\n)III\.'), (match) => 'II.');
    filtered = filtered.replaceAllMapped(RegExp(r'(?<=^|\n)IV\.'), (match) => 'III.');
    filtered = filtered.replaceAllMapped(RegExp(r'(?<=^|\n)V\.'), (match) => 'IV.');

    return filtered;
  }

  String _processConditions(String content, InterventionProvider provider) {
    final conditionRegex = RegExp(r'<\s*IF_([A-Z0-9_]+)\s*>(.*?)<\s*/\s*IF_\1\s*>', dotAll: true, caseSensitive: false);
    String text = content.replaceAllMapped(conditionRegex, (match) {
      final condition = match.group(1)!;
      final innerText = match.group(2)!;
      if (provider.getCondition(condition)) return innerText;
      return '';
    });

    final conditionNotRegex = RegExp(r'<\s*IF_NOT_([A-Z0-9_]+)\s*>(.*?)<\s*/\s*IF_NOT_\1\s*>', dotAll: true, caseSensitive: false);
    text = text.replaceAllMapped(conditionNotRegex, (match) {
      final condition = match.group(1)!;
      final innerText = match.group(2)!;
      if (!provider.getCondition(condition)) return innerText;
      return '';
    });

    final safetyRegex = RegExp(r'<\s*/?\s*IF_[A-Z0-9_]+\s*>', caseSensitive: false);
    text = text.replaceAll(safetyRegex, '');

    return text;
  }

  /// Compiles tags into their filled values for preview mode
  String _compileText(String content, InterventionProvider provider) {
    String text = _processConditions(content, provider);

    final tagRegex = RegExp(r'\[(.*?)\]');
    text = text.replaceAllMapped(tagRegex, (match) {
      final tagStr = match.group(0)!;
      final val = provider.getTagValue(tagStr);
      if (val != null && val.isNotEmpty) return val;
      return '___';
    });

    return text;
  }

  void _showTagInput(BuildContext context, String tagStr, TagDefinition? tagDef, String? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => TagInputWidget(
        tagString: tagStr,
        tagDef: tagDef,
        initialValue: current,
      ),
    );
  }

  void _onTagTapped(BuildContext context, String tagStr, TagDefinition? tagDef, String? currentValue) {
    final isPerson = tagStr.startsWith('[imputado.') ||
                     tagStr.startsWith('[testigo.') ||
                     tagStr.startsWith('[agraviado.');

    if (!isPerson) {
      _showTagInput(context, tagStr, tagDef, currentValue);
      return;
    }

    final dniTag = tagStr.startsWith('[imputado.')
        ? '[imputado.dni]'
        : tagStr.startsWith('[testigo.')
            ? '[testigo.dni]'
            : '[agraviado.dni]';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return PersonEntryMethodSheet(
          tagStr: tagStr,
          tagDef: tagDef,
          currentValue: currentValue,
          dniTag: dniTag,
          onChoice: (method) {
            Navigator.pop(ctx);
            if (method == 'manual') {
              _showTagInput(context, tagStr, tagDef, currentValue);
            } else {
              final dniDef = TagsRepository.tagMap[dniTag];
              final provider = context.read<InterventionProvider>();
              final currentDniVal = provider.getTagValue(dniTag);
              _showTagInput(context, dniTag, dniDef, currentDniVal);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document.content.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.article_outlined,
                  size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                widget.document.title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta acta no tiene plantilla creada aún.\n'
                'Crea su contenido en el Gestor de Plantillas.',
                style: TextStyle(color: Colors.white38, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<InterventionProvider>();
    final requiereFiscal =
        provider.getTagValue('[intervencion.requiere_fiscal]') != 'NO';
    final filteredContent =
        _getFilteredContent(widget.document.content, requiereFiscal);
    final processedContent = _processConditions(filteredContent, provider);

    return Column(
      children: [
        // ── Mode Toggle Bar ─────────────────────────────────────────────────
        _ModeToggleBar(
          isPreviewMode: _isPreviewMode,
          onToggle: () {
            setState(() {
              _isPreviewMode = !_isPreviewMode;
              if (_isPreviewMode) {
                _toggleAnim.forward();
              } else {
                _toggleAnim.reverse();
              }
            });
          },
        ),

        // ── Content Area ────────────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _isPreviewMode
                ? _CompiledPreviewView(
                    key: const ValueKey('preview'),
                    compiledText: _compileText(filteredContent, provider),
                    docTitle: widget.document.title,
                  )
                : Column(
                    key: const ValueKey('edit'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_isEditingRaw)
                              TextButton.icon(
                                onPressed: () => _showTagsMenu(context),
                                icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.blueAccent),
                                label: const Text('Insertar Etiqueta', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Modo Edición Libre', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _isEditingRaw,
                                  activeThumbColor: const Color(0xFFFF6B35),
                                  onChanged: (val) {
                                    setState(() {
                                      if (!val) {
                                        _saveContent();
                                      }
                                      _isEditingRaw = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isEditingRaw
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DefaultTextStyle(
                                    style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
                                    child: QuillEditor(
                                      focusNode: FocusNode(),
                                      scrollController: ScrollController(),
                                      controller: _quillController,
                                      config: const QuillEditorConfig(
                                        scrollable: true,
                                        expands: true,
                                        autoFocus: true,
                                        padding: EdgeInsets.all(16),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : _TaggedDocumentView(
                                content: processedContent,
                                onTagTapped: (tagStr, tagDef, currentValue) =>
                                    _onTagTapped(context, tagStr, tagDef, currentValue),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showTagsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _TagsMenuSheet(
          onTagSelected: (tagStr) {
            final displayName = tagStr.replaceAll('[', '').replaceAll(']', '').split('.').last;
            final index = _quillController.selection.baseOffset;
            final length = _quillController.selection.extentOffset - index;
            _quillController.replaceText(
              index,
              length,
              displayName,
              TextSelection.collapsed(offset: index + displayName.length),
            );
            _quillController.formatText(
              index,
              displayName.length,
              LinkAttribute('actium-tag:$tagStr'),
            );
            _saveContent();
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}

class _TagsMenuSheet extends StatefulWidget {
  final Function(String tag) onTagSelected;

  const _TagsMenuSheet({required this.onTagSelected});

  @override
  State<_TagsMenuSheet> createState() => _TagsMenuSheetState();
}

class _TagsMenuSheetState extends State<_TagsMenuSheet> {
  String _searchQuery = '';
  late List<TagDefinition> _filteredTags;

  @override
  void initState() {
    super.initState();
    _filteredTags = TagsRepository.allTags;
  }

  void _filterTags(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredTags = TagsRepository.allTags;
      } else {
        _filteredTags = TagsRepository.allTags.where((t) {
          return t.name.toLowerCase().contains(_searchQuery) ||
                 t.tag.toLowerCase().contains(_searchQuery) ||
                 t.category.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar por categoría
    final Map<String, List<TagDefinition>> grouped = {};
    for (var t in _filteredTags) {
      grouped.putIfAbsent(t.category, () => []).add(t);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle (Grabber)
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Etiquetas Automatizadas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                onChanged: _filterTags,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar etiqueta...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: grouped.isEmpty
                    ? const Center(child: Text('No se encontraron etiquetas', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final category = grouped.keys.elementAt(index);
                          final tags = grouped[category]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(category, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              ...tags.map((t) => ListTile(
                                dense: true,
                                title: Text(t.name, style: const TextStyle(color: Colors.white)),
                                subtitle: Text(t.tag, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                onTap: () => widget.onTagSelected(t.tag),
                                trailing: const Icon(Icons.add, color: Colors.white38, size: 18),
                              )),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Toggle Bar between Preview and Edit modes
// ══════════════════════════════════════════════════════════════════════════════
class _ModeToggleBar extends StatelessWidget {
  final bool isPreviewMode;
  final VoidCallback onToggle;

  const _ModeToggleBar({
    required this.isPreviewMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Edit Tab (COMPLETAR)
          Expanded(
            child: GestureDetector(
              onTap: !isPreviewMode ? null : onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: !isPreviewMode
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: !isPreviewMode
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: !isPreviewMode ? Colors.white : Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'COMPLETAR',
                      style: TextStyle(
                        color: !isPreviewMode ? Colors.white : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Preview Tab (VISTA PREVIA)
          Expanded(
            child: GestureDetector(
              onTap: isPreviewMode ? null : onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: isPreviewMode
                      ? const LinearGradient(
                          colors: [Color(0xFF1E80F0), Color(0xFF0D47A1)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isPreviewMode
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E80F0).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      size: 15,
                      color: isPreviewMode ? Colors.white : Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VISTA PREVIA',
                      style: TextStyle(
                        color: isPreviewMode ? Colors.white : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Preview Mode: Compiled document rendered like a real printed acta
// ══════════════════════════════════════════════════════════════════════════════
class _CompiledPreviewView extends StatelessWidget {
  final String compiledText;
  final String docTitle;

  const _CompiledPreviewView({
    super.key,
    required this.compiledText,
    required this.docTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No Header row as per user request
            const SizedBox(height: 28),
            // Document title centered
            Center(
              child: Text(
                docTitle.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.underline,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 22),
            // Compiled document body
            _buildCompiledBody(compiledText),
            const SizedBox(height: 44),
            // Signature line
            Center(
              child: Column(
                children: [
                  Container(width: 130, height: 1, color: Colors.black45),
                  const SizedBox(height: 6),
                  const Text(
                    'FIRMA Y SELLO',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Text(
                    'EFECTIVO PNP INTERVINIENTE',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 7,
                      letterSpacing: 0.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompiledBody(String text) {
    final lines = text.split('\n');
    final spans = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        spans.add(const SizedBox(height: 6));
        continue;
      }

      // Section headers (Roman numerals or ALL CAPS short lines)
      final isHeader = RegExp(r'^[IVX]+\.\s+').hasMatch(trimmed) ||
          (trimmed.length < 60 && trimmed == trimmed.toUpperCase() && trimmed.length > 3);

      // Detect unfilled placeholders
      final containsBlank = trimmed.contains('___');

      spans.add(Padding(
        padding: EdgeInsets.only(bottom: isHeader ? 8 : 2),
        child: Text(
          line,
          style: TextStyle(
            color: containsBlank ? const Color(0xFFE53935) : Colors.black87,
            fontSize: isHeader ? 11.5 : 11,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            fontFamily: isHeader ? 'Inter' : 'monospace',
            height: 1.65,
            letterSpacing: isHeader ? 0.5 : 0,
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spans,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Edit Mode: Document with inline tappable tag chips
// ══════════════════════════════════════════════════════════════════════════════
class _TaggedDocumentView extends StatelessWidget {
  final String content;
  final Function(String, TagDefinition?, String?) onTagTapped;

  const _TaggedDocumentView({
    required this.content,
    required this.onTagTapped,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterventionProvider>();
    final regex = RegExp(r'\[(.*?)\]');
    final matches = regex.allMatches(content);

    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Plain text before the tag
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: content.substring(lastEnd, match.start),
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 13.5,
            height: 1.75,
            fontFamily: 'Inter',
          ),
        ));
      }

      final tagStr = match.group(0)!;
      final tagDef = TagsRepository.tagMap[tagStr];
      final currentValue = provider.getTagValue(tagStr);
      final isFilled = currentValue != null && currentValue.isNotEmpty;

      final displayLabel = isFilled
          ? currentValue
          : (tagDef?.name ?? tagStr.replaceAll('[', '').replaceAll(']', '').split('.').last);

      final tagWidget = _TagChip(
        label: displayLabel,
        isFilled: isFilled,
        onTap: () => onTagTapped(tagStr, tagDef, currentValue),
      );

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: tagWidget,
      ));

      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastEnd),
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 13.5,
          height: 1.75,
          fontFamily: 'Inter',
        ),
      ));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Helper hint
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2744),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E80F0).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, color: Color(0xFF1E80F0), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toca cualquier campo resaltado para completarlo',
                    style: TextStyle(
                      color: Color(0xFF90CAF9),
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(children: spans),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Inline Tag Chip — compact & clean design
// ══════════════════════════════════════════════════════════════════════════════
class _TagChip extends StatelessWidget {
  final String label;
  final bool isFilled;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isFilled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isFilled
        ? const Color(0xFF0A3320)
        : const Color(0xFF1A2236);
    final borderColor = isFilled
        ? const Color(0xFF00C853).withValues(alpha: 0.7)
        : const Color(0xFF1E80F0).withValues(alpha: 0.6);
    final textColor = isFilled
        ? const Color(0xFF69F0AE)
        : const Color(0xFF82B1FF);
    final icon = isFilled ? Icons.check_rounded : Icons.edit_rounded;
    final iconColor = isFilled ? const Color(0xFF00C853) : const Color(0xFF1E80F0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: iconColor),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
