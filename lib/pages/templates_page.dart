import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import '../models/template.dart';
import '../services/template_service.dart';
import '../utils/quill_content_helper.dart';
import 'tag_editor_page.dart';
import '../widgets/custom_app_drawer.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final TemplateService _templateService = TemplateService();
  List<Template> _allTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    super.dispose();
  }

  
  List<Template> get _systemTemplates => _allTemplates.where((t) => t.isSystem).toList();
  List<Template> get _userTemplates => _allTemplates.where((t) => !t.isSystem && (t.createdBy == null || t.createdBy == '')).toList();
  List<Template> get _importedTemplates => _allTemplates.where((t) => !t.isSystem && t.createdBy != null && t.createdBy != '' && t.createdBy != 'SISTEMA').toList();

  Widget _buildList(List<Template> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_add_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildTemplateCard(list[index]),
    );
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final list = await _templateService.loadTemplates();
    if (mounted) {
      setState(() {
        _allTemplates = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTemplate(Template t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar plantilla', style: TextStyle(color: Colors.white)),
        content: Text('¿Estás seguro de que deseas eliminar la plantilla "${t.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _templateService.deleteTemplate(t.id);
      _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla eliminada')),
        );
      }
    }
  }

  void _exportTemplate(Template t) {
    try {
      final jsonString = json.encode(t.toMap());
      final bytes = utf8.encode(jsonString);
      final base64Str = base64.encode(bytes);
      final exportCode = 'ACTIUM-TPL:$base64Str';
      
      Clipboard.setData(ClipboardData(text: exportCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Código de plantilla copiado. ¡Compártelo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  void _showImportDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Importar Plantilla', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pega aquí el código de la plantilla compartida:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'ACTIUM-TPL:...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _processImport(codeController.text.trim());
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Future<void> _processImport(String code) async {
    if (code.isEmpty) return;
    try {
      String base64Data = code;
      if (code.startsWith('ACTIUM-TPL:')) {
        base64Data = code.replaceFirst('ACTIUM-TPL:', '');
      }
      final bytes = base64.decode(base64Data);
      final jsonString = utf8.decode(bytes);
      final Map<String, dynamic> map = json.decode(jsonString);
      
      // Force new ID to avoid collisions
      map['id'] = const Uuid().v4();
      map['isSystem'] = false;
      if (map['createdBy'] == null || map['createdBy'].toString().isEmpty || map['createdBy'] == 'SISTEMA') {
        map['createdBy'] = 'COMUNIDAD';
      }
      
      final importedTemplate = Template.fromMap(map);
      await _templateService.saveTemplate(importedTemplate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Plantilla importada exitosamente')),
        );
        _loadTemplates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Código inválido o corrupto')),
        );
      }
    }
  }


  void _viewTemplateContent(Template t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  'PLANTILLA PERSONAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD2BBFF),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.print_outlined, size: 14, color: Colors.white38),
                        SizedBox(width: 8),
                        Text(
                          'VISTA PREVIA DE IMPRESIÓN (EN BLANCO)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content (Paper sheet styled card)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC), // White/light paper background
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _buildPrintedPreviewText(t.content),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrintedPreviewText(String content) {
    // Build document from Delta JSON or legacy plain text, with tags replaced by blanks
    final doc = QuillContentHelper.documentForPrintedPreview(content);
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    const baseStyle = TextStyle(
      color: Color(0xFF1E293B),
      fontSize: 13,
      height: 1.7,
      fontFamily: 'Georgia',
    );

    return QuillEditor(
      focusNode: FocusNode(),
      scrollController: ScrollController(),
      controller: controller,
      config: QuillEditorConfig(
        scrollable: false,
        expands: false,
        autoFocus: false,
        enableInteractiveSelection: true,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            baseStyle,
            HorizontalSpacing.zero,
            const VerticalSpacing(3, 3),
            VerticalSpacing.zero,
            null,
          ),
          h1: DefaultTextBlockStyle(
            baseStyle.copyWith(fontSize: 19, fontWeight: FontWeight.bold),
            HorizontalSpacing.zero,
            const VerticalSpacing(8, 4),
            VerticalSpacing.zero,
            null,
          ),
          h2: DefaultTextBlockStyle(
            baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            HorizontalSpacing.zero,
            const VerticalSpacing(6, 3),
            VerticalSpacing.zero,
            null,
          ),
          h3: DefaultTextBlockStyle(
            baseStyle.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold),
            HorizontalSpacing.zero,
            const VerticalSpacing(4, 2),
            VerticalSpacing.zero,
            null,
          ),
          bold: baseStyle.copyWith(fontWeight: FontWeight.bold),
          italic: baseStyle.copyWith(fontStyle: FontStyle.italic),
          underline: baseStyle.copyWith(decoration: TextDecoration.underline),
          strikeThrough: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
          placeHolder: DefaultTextBlockStyle(
            baseStyle.copyWith(color: const Color(0xFF9BA3AE)),
            HorizontalSpacing.zero,
            VerticalSpacing.zero,
            VerticalSpacing.zero,
            null,
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Template t) {
    final isSystem = t.isSystem;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isSystem
                  ? const Color(0xFF1E40AF).withValues(alpha: 0.18)
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSystem
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (isSystem) ...[
                            const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF60A5FA)),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              t.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSystem ? const Color(0xFFBFDBFE) : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSystem
                            ? const Color(0xFF1D4ED8).withValues(alpha: 0.3)
                            : const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSystem
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                              : const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isSystem ? 'SISTEMA' : (t.createdBy != null && t.createdBy!.isNotEmpty && t.createdBy != 'SISTEMA' ? 'IMPORTADA' : 'Personal'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSystem ? const Color(0xFF93C5FD) : const Color(0xFFD2BBFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isSystem ? Icons.verified_outlined : Icons.person_outline_rounded,
                      size: 12,
                      color: Colors.white30,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSystem ? 'Plantilla oficial del sistema' : 'Creado por: ${t.createdBy ?? "CIP-PROPIO"}',
                      style: const TextStyle(fontSize: 10, color: Colors.white30, fontFamily: 'Inter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  QuillContentHelper.plainTextPreview(t.content),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Share Button — always available
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF64B5F6)),
                      tooltip: 'Compartir plantilla',
                      onPressed: () => _exportTemplate(t),
                    ),
                    // View Button — always available
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.white70),
                      tooltip: 'Visualizar plantilla',
                      onPressed: () => _viewTemplateContent(t),
                    ),
                    if (!isSystem) ...[
                      // Edit Button — only for non-system templates
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                        tooltip: 'Editar plantilla',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TagEditorPage(templateToEdit: t),
                            ),
                          );
                          _loadTemplates();
                        },
                      ),
                      // Delete Button — only for non-system templates
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        tooltip: 'Eliminar plantilla',
                        onPressed: () => _deleteTemplate(t),
                      ),
                    ] else ...[
                      // Lock indicator for system templates
                      Tooltip(
                        message: 'Las plantillas del sistema no se pueden eliminar ni editar',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock_rounded, size: 16, color: Color(0xFF60A5FA)),
                              SizedBox(width: 4),
                              Text('Protegida', style: TextStyle(fontSize: 11, color: Color(0xFF60A5FA))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomAppDrawer(),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white70),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Explorador de Plantillas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: Colors.white),
                        tooltip: 'Importar plantilla compartida',
                        onPressed: _showImportDialog,
                      ),
                    ],
                  ),
                ),
                // Body Content
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary)))
                      : DefaultTabController(
                          length: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TabBar(
                                indicatorColor: Theme.of(context).colorScheme.primary,
                                labelColor: Theme.of(context).colorScheme.primary,
                                unselectedLabelColor: Colors.white54,
                                labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 12),
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                tabs: const [
                                  Tab(text: 'SISTEMA'),
                                  Tab(text: 'MIS PLANTILLAS'),
                                  Tab(text: 'IMPORTADAS'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildList(_systemTemplates, 'Sin plantillas de sistema'),
                                    _buildList(_userTemplates, 'No has creado ninguna plantilla'),
                                    _buildList(_importedTemplates, 'No has importado plantillas'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TagEditorPage()),
          );
          _loadTemplates();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Plantilla', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
