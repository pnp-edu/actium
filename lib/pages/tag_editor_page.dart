import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import '../models/tags.dart';
import '../models/template.dart';
import '../services/template_service.dart';
import '../utils/quill_content_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAG EDITOR PAGE  —  WYSIWYG rich text editor (like Word)
// ─────────────────────────────────────────────────────────────────────────────

class TagEditorPage extends StatefulWidget {
  final Template? templateToEdit;
  const TagEditorPage({super.key, this.templateToEdit});

  @override
  State<TagEditorPage> createState() => _TagEditorPageState();
}

class _TagEditorPageState extends State<TagEditorPage>
    with SingleTickerProviderStateMixin {
  Template? _currentEditingTemplate;
  // ── Controllers ──────────────────────────────────────────────────────────
  final TextEditingController _nameController = TextEditingController();
  late QuillController _quillController;
  late QuillController _previewController;      // read-only mirror for preview
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _previewFocusNode = FocusNode();
  final TemplateService _templateService = TemplateService();
  late TabController _tabController;
  StreamSubscription? _changeSubscription;

  // ── Tag Panel State ───────────────────────────────────────────────────────
  String _tagSearchQuery = '';
  String _selectedCategory = 'Todas';

  // ── Scroll ────────────────────────────────────────────────────────────────
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _previewScrollController = ScrollController();

  // ── Theme Colors ──────────────────────────────────────────────────────────
  Color get _kPrimary   => Theme.of(context).colorScheme.primary;
  Color get _kBg        => Theme.of(context).scaffoldBackgroundColor;
  Color get _kSurface   => Theme.of(context).colorScheme.surface;
  Color get _kSurface2  => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _kBorder    => Theme.of(context).dividerTheme.color ?? const Color(0xFF1C2E4A);
  static const Color _kText      = Colors.white;
  Color get _kTextDim   => const Color(0xFF7B93B5);

  @override
  void initState() {
    super.initState();
    _currentEditingTemplate = widget.templateToEdit;
    _tabController = TabController(length: 2, vsync: this);

    _nameController.text = _currentEditingTemplate?.name ?? '';

    final initialController = QuillContentHelper.controllerFromContent(
      _currentEditingTemplate?.content ?? '',
    );
    _quillController = QuillController(
      document: Document.fromDelta(_transformOnLoad(initialController.document.toDelta())),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Preview controller — read only
    _previewController = QuillController(
      document: Document.fromDelta(_transformForPreview(_quillController.document.toDelta())),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Keep preview in sync whenever the editor document changes
    _changeSubscription = _quillController.document.changes.listen((event) {
      if (!mounted) return;
      _updatePreview();
    });
  }

  void _updatePreview() {
    final transformed = _transformForPreview(_quillController.document.toDelta());
    final diff = _previewController.document.toDelta().diff(transformed);
    if (diff.isNotEmpty) {
      _previewController.document.compose(diff, ChangeSource.local);
    }
  }

  Delta _transformOnLoad(Delta source) {
    final delta = Delta();
    final RegExp tagRegex = RegExp(r'\[([a-zA-Z0-9_\.]+)\]');
    
    for (final op in source.toList()) {
      if (op.isInsert && op.data is String) {
        final text = op.data as String;
        int lastIndex = 0;
        for (final match in tagRegex.allMatches(text)) {
          final tagFull = match.group(0)!;
          final tagName = tagFull.replaceAll('[', '').replaceAll(']', '').split('.').last;
          if (match.start > lastIndex) {
            delta.insert(text.substring(lastIndex, match.start), op.attributes);
          }
          final newAttrs = Map<String, dynamic>.from(op.attributes ?? {});
          newAttrs['link'] = 'actium-tag:$tagFull';
          delta.insert(tagName, newAttrs);
          lastIndex = match.end;
        }
        if (lastIndex < text.length) {
          delta.insert(text.substring(lastIndex), op.attributes);
        }
      } else {
        delta.push(op);
      }
    }
    return delta;
  }

  Delta _transformForPreview(Delta source) {
    final delta = Delta();
    for (final op in source.toList()) {
      if (op.isInsert && op.data is String) {
        final attrs = op.attributes;
        if (attrs != null && attrs['link'] != null && attrs['link'].toString().startsWith('actium-tag:')) {
          final newAttrs = Map<String, dynamic>.from(attrs);
          newAttrs.remove('link');
          delta.insert('_______', newAttrs.isEmpty ? null : newAttrs);
        } else {
          delta.insert(op.data, attrs);
        }
      } else {
        delta.push(op);
      }
    }
    return delta;
  }

  String _transformOnSave(Delta source) {
    final delta = Delta();
    for (final op in source.toList()) {
      if (op.isInsert && op.data is String) {
        final attrs = op.attributes;
        if (attrs != null && attrs['link'] != null && attrs['link'].toString().startsWith('actium-tag:')) {
          final tagCode = attrs['link'].toString().replaceFirst('actium-tag:', '');
          final newAttrs = Map<String, dynamic>.from(attrs);
          newAttrs.remove('link');
          delta.insert(tagCode, newAttrs.isEmpty ? null : newAttrs);
        } else {
          delta.insert(op.data, attrs);
        }
      } else {
        delta.push(op);
      }
    }
    return jsonEncode(delta.toJson());
  }

  @override
  void dispose() {
    _changeSubscription?.cancel();
    _tabController.dispose();
    _nameController.dispose();
    _quillController.dispose();
    _previewController.dispose();
    _editorFocusNode.dispose();
    _previewFocusNode.dispose();
    _editorScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  // ── Tag Insertion ─────────────────────────────────────────────────────────

  /// Inserts a tag as a friendly text with a link attribute
  void _insertTag(String tag) {
    final String displayName = tag.replaceAll('[', '').replaceAll(']', '').split('.').last;
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
      LinkAttribute('actium-tag:$tag'),
    );

    _editorFocusNode.requestFocus();
    if (Scaffold.of(context).isEndDrawerOpen) {
      Navigator.pop(context);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveTemplate() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para la plantilla')),
      );
      return;
    }

    final newName = _nameController.text.trim();

    // ── Guard: Prohibit names identical to system templates ───────────────
    final allTemplates = await _templateService.loadTemplates();
    final editingId = _currentEditingTemplate?.id;
    final systemNameConflict = allTemplates.any((t) =>
        t.isSystem &&
        t.name.trim().toLowerCase() == newName.toLowerCase() &&
        t.id != editingId, // allow re-saving with the same name if it IS the same template
    );
    if (systemNameConflict) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⛔ Ya existe una plantilla del SISTEMA con ese nombre. Elige otro.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Serialise Delta → JSON string for storage (restoring the [tag] syntax)
    final content = _transformOnSave(_quillController.document.toDelta());

    bool wasSystem = _currentEditingTemplate?.isSystem ?? false;
    String newId = _currentEditingTemplate?.id ?? const Uuid().v4();
    
    // If editing a system template, branch it to a new personal template
    if (wasSystem) {
      newId = const Uuid().v4();
      wasSystem = false;
    }

    final template = Template(
      id: newId,
      name: newName,
      content: content,
      isSystem: wasSystem,
      createdBy: '', // Belongs to the user now
    );
    
    await _templateService.saveTemplate(template);
    
    if (mounted) {
      setState(() {
        _currentEditingTemplate = template;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
             widget.templateToEdit?.isSystem == true && _currentEditingTemplate?.id == template.id
               ? '✓ Copia guardada en Mis Plantillas' 
               : '✓ Plantilla guardada correctamente'
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF004D33),
        ),
      );
    }
  }


  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      endDrawer: _buildTagDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildEditorTab(),
                  _buildPreviewTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _currentEditingTemplate != null
                  ? 'Editar Plantilla'
                  : 'Nueva Plantilla',
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          // Tag catalog button
          Builder(
            builder: (ctx) => _ActionChip(
              icon: Icons.label_outline,
              label: 'Etiquetas',
              color: _kPrimary,
              onTap: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          // Save button
          _ActionChip(
            icon: Icons.save_outlined,
            label: 'Guardar',
            color: const Color(0xFF00B87A),
            onTap: _saveTemplate,
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: _kPrimary,
        indicatorWeight: 2,
        labelColor: _kPrimary,
        unselectedLabelColor: _kTextDim,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note_rounded, size: 16),
                SizedBox(width: 6),
                Text('Editor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_outlined, size: 16),
                SizedBox(width: 6),
                Text('Vista Previa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EDITOR TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEditorTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Document title field
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(color: _kText, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Nombre del Acta',
              labelStyle: TextStyle(color: _kTextDim, fontSize: 13),
              prefixIcon: Icon(Icons.article_outlined, color: _kPrimary, size: 18),
              filled: true,
              fillColor: _kSurface2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
        ),

        // ── WYSIWYG Toolbar ───────────────────────────────────────────
        _buildWysiwygToolbar(),

        // ── Quill Editor (rich text, like Word) ───────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: QuillEditor(
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  controller: _quillController,
                  config: QuillEditorConfig(
                    scrollable: true,
                    expands: true,
                    padding: const EdgeInsets.all(16),
                    placeholder:
                        'Escribe el texto del acta aquí... Selecciona texto y usa la barra de arriba para aplicar formato.',
                    customStyles: _buildEditorStyles(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── WYSIWYG Toolbar ───────────────────────────────────────────────────────

  Widget _buildWysiwygToolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          color: _kSurface,
          iconTheme: QuillIconTheme(
            iconButtonUnselectedData: IconButtonData(
              color: Colors.white70,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            iconButtonSelectedData: IconButtonData(
              color: _kPrimary,
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(_kPrimary.withValues(alpha: 0.2)),
              ),
            ),
          ),
          // Show only the controls we need for document editing
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showHeaderStyle: true,
          showAlignmentButtons: true,
          showListBullets: true,
          showListNumbers: true,
          showQuote: true,
          showIndent: true,
          showClearFormat: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          // Hide features not needed for police documents
          showSmallButton: false,
          showCodeBlock: false,
          showInlineCode: false,
          showLink: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          showFontFamily: false,
          showFontSize: true,
          toolbarSize: 42,
          buttonOptions: const QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ── Editor DefaultStyles (dark theme) ────────────────────────────────────

  DefaultStyles _buildEditorStyles() {
    const textColor = Color(0xFFD6E4F7);
    const textStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      height: 1.7,
      fontFamily: 'Georgia',
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        textStyle,
        HorizontalSpacing.zero,
        const VerticalSpacing(2, 2),
        const VerticalSpacing(0, 0),
        null,
      ),
      placeHolder: DefaultTextBlockStyle(
        const TextStyle(
          color: Color(0xFF3D5A7A),
          fontSize: 14,
          height: 1.7,
          fontStyle: FontStyle.italic,
        ),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      h1: DefaultTextBlockStyle(
        const TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        HorizontalSpacing.zero,
        const VerticalSpacing(8, 4),
        VerticalSpacing.zero,
        null,
      ),
      h2: DefaultTextBlockStyle(
        const TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        HorizontalSpacing.zero,
        const VerticalSpacing(6, 3),
        VerticalSpacing.zero,
        null,
      ),
      h3: DefaultTextBlockStyle(
        const TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        HorizontalSpacing.zero,
        const VerticalSpacing(4, 2),
        VerticalSpacing.zero,
        null,
      ),
      bold: const TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      italic: const TextStyle(
        color: textColor,
        fontStyle: FontStyle.italic,
      ),
      underline: const TextStyle(
        color: textColor,
        decoration: TextDecoration.underline,
      ),
      strikeThrough: const TextStyle(
        color: textColor,
        decoration: TextDecoration.lineThrough,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PREVIEW TAB — A4 Document style, read-only
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPreviewTab() {
    return Container(
      color: const Color(0xFF0A1020),
      child: SingleChildScrollView(
        controller: _previewScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Document Header Band ────────────────────────
                  _buildPreviewHeader(),
                  // ── A4 Page Body ────────────────────────────────
                  // QuillEditor with scrollable:false sits inside
                  // a SingleChildScrollView, so it grows to its
                  // natural content height with no overflow.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 40, 48, 56),
                    child: QuillEditor(
                      focusNode: _previewFocusNode,
                      scrollController: ScrollController(),
                      controller: _previewController,
                      config: QuillEditorConfig(
                        scrollable: false,
                        expands: false,
                        autoFocus: false,
                        enableInteractiveSelection: false,
                        showCursor: false,
                        padding: EdgeInsets.zero,
                        customStyles: _buildPreviewStyles(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1929),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              color: Color(0xFF1E90FF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameController,
              builder: (context, v, child) => Text(
                v.text.isEmpty ? 'Sin título' : v.text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'VISTA PREVIA A4',
              style: TextStyle(
                color: Color(0xFF7DB6FF),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DefaultStyles _buildPreviewStyles() {
    const baseColor = Color(0xFF1A2332);
    const base = TextStyle(
      color: baseColor,
      fontSize: 13,
      height: 1.8,
      fontFamily: 'Georgia',
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        base,
        HorizontalSpacing.zero,
        const VerticalSpacing(3, 3),
        VerticalSpacing.zero,
        null,
      ),
      h1: DefaultTextBlockStyle(
        base.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        HorizontalSpacing.zero,
        const VerticalSpacing(10, 6),
        VerticalSpacing.zero,
        null,
      ),
      h2: DefaultTextBlockStyle(
        base.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        HorizontalSpacing.zero,
        const VerticalSpacing(8, 4),
        VerticalSpacing.zero,
        null,
      ),
      h3: DefaultTextBlockStyle(
        base.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        HorizontalSpacing.zero,
        const VerticalSpacing(6, 3),
        VerticalSpacing.zero,
        null,
      ),
      bold: base.copyWith(fontWeight: FontWeight.bold),
      italic: base.copyWith(fontStyle: FontStyle.italic),
      underline: base.copyWith(decoration: TextDecoration.underline),
      strikeThrough: base.copyWith(decoration: TextDecoration.lineThrough),
      placeHolder: DefaultTextBlockStyle(
        base.copyWith(color: const Color(0xFF9BA3AE)),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAG DRAWER (End Drawer)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTagDrawer() {
    List<TagDefinition> filtered = _tagSearchQuery.isEmpty
        ? TagsRepository.allTags
        : TagsRepository.searchTags(_tagSearchQuery);

    if (_selectedCategory != 'Todas') {
      filtered = filtered.where((t) => t.category == _selectedCategory).toList();
    }

    final categories = ['Todas', ...TagsRepository.getCategories()];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: const Color(0xFF080F1C).withValues(alpha: 0.97),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDrawerHeader(),
                  _buildDrawerSearch(),
                  _buildCategoryChips(categories),
                  _buildTagCount(filtered.length),
                  Expanded(child: _buildTagList(filtered)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.label_rounded, color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catálogo de Etiquetas',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Toca para insertar en el cursor',
                  style: TextStyle(color: _kTextDim, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        style: const TextStyle(color: _kText, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar etiqueta...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
          filled: true,
          fillColor: _kSurface2,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _kPrimary, width: 1.2),
          ),
        ),
        onChanged: (val) => setState(() => _tagSearchQuery = val),
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final selected = cat == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? _kPrimary : _kSurface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? _kPrimary : _kBorder),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: selected ? Colors.white : _kTextDim,
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        '$count etiquetas',
        style: const TextStyle(color: Colors.white24, fontSize: 11),
      ),
    );
  }

  Widget _buildTagList(List<TagDefinition> tags) {
    if (tags.isEmpty) {
      return const Center(
        child: Text('Sin resultados', style: TextStyle(color: Colors.white30)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: tags.length,
      itemBuilder: (ctx, i) => _buildTagTile(tags[i]),
    );
  }

  Widget _buildTagTile(TagDefinition t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _insertTag(t.tag),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.label_important_outline,
                      size: 15, color: _kPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: TextStyle(
                          color: _kText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.tag,
                        style: TextStyle(
                          color: _kPrimary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: _kPrimary, size: 12),
                      const SizedBox(width: 3),
                      Text('Insertar',
                          style:
                              TextStyle(color: _kPrimary, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Small chip-style action button for the top bar.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
