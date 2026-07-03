import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../utils/quill_content_helper.dart';
import '../models/template.dart';
import '../services/template_service.dart';
import '../models/typification.dart';
import '../models/typification_repository.dart';
import '../widgets/custom_app_drawer.dart';


class CommunityPost {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String authorId;
  final String authorRank;
  final String? authorComment;
  double stars;
  int userRating;
  int ratingsCount;
  final String? typificationName;
  final String? typificationLogic;
  final List<Template>? templates;

  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorId,
    required this.authorRank,
    this.authorComment,
    required this.stars,
    this.userRating = 0,
    required this.ratingsCount,
    this.typificationName,
    this.typificationLogic,
    this.templates,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorName': authorName,
      'authorId': authorId,
      'authorRank': authorRank,
      'authorComment': authorComment,
      'stars': stars,
      'userRating': userRating,
      'ratingsCount': ratingsCount,
      'typificationName': typificationName,
      'typificationLogic': typificationLogic,
      'templates': templates?.map((t) => t.toMap()).toList(),
    };
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    List<Template>? templatesList;
    if (map['templates'] != null) {
      try {
        final List<dynamic> list = map['templates'];
        templatesList = list.map((e) => Template.fromMap(e)).toList();
      } catch (_) {}
    }
    return CommunityPost(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorName: map['authorName'] ?? '',
      authorId: map['authorId'] ?? '',
      authorRank: map['authorRank'] ?? '',
      authorComment: map['authorComment'],
      stars: (map['stars'] as num?)?.toDouble() ?? 0.0,
      userRating: map['userRating'] ?? 0,
      ratingsCount: map['ratingsCount'] ?? 0,
      typificationName: map['typificationName'],
      typificationLogic: map['typificationLogic'],
      templates: templatesList,
    );
  }
}

class CommunityPage extends StatefulWidget {
  final Function(bool isPreviewing)? onPreviewChanged;
  const CommunityPage({super.key, this.onPreviewChanged});

  @override
  State<CommunityPage> createState() => CommunityPageState();
}

class CommunityPageState extends State<CommunityPage> {
  final _searchController = TextEditingController();
  final _templateService = TemplateService();
  final _focusNode = FocusNode();
  String _searchQuery = '';

  List<CommunityPost> _posts = [];
  CommunityPost? _selectedPostForPreview;
  int _previewingTemplateIndex = 0;

  bool get isPreviewing => _selectedPostForPreview != null;

  Widget _buildPrintedPreviewText(String content) {
    final doc = QuillContentHelper.documentForPrintedPreview(content);
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 11.5,
        fontFamily: 'monospace',
        height: 1.6,
      ),
      child: QuillEditor(
        focusNode: FocusNode(),
        scrollController: ScrollController(),
        controller: controller,
        config: const QuillEditorConfig(
          scrollable: false,
          expands: false,
          autoFocus: false,
          enableInteractiveSelection: true,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString('community_posts');
      if (postsJson != null) {
        final List<dynamic> decoded = json.decode(postsJson);
        setState(() {
          _posts = decoded.map((item) => CommunityPost.fromMap(item)).toList();
        });
      } else {
        _posts = _getDefaultPosts();
        await _savePosts();
        setState(() {});
      }
    } catch (_) {
      setState(() {
        _posts = _getDefaultPosts();
      });
    }
  }

  Future<void> _savePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_posts.map((p) => p.toMap()).toList());
      await prefs.setString('community_posts', encoded);
    } catch (_) {}
  }

  List<CommunityPost> _getDefaultPosts() {
    return [
      CommunityPost(
        id: 'post_1',
        title: 'Acta de Control de Identidad Policial',
        authorRank: 'CRNL. PNP',
        authorName: 'Gomez Arrieta',
        authorId: 'CIP-482910',
        stars: 2.8,
        ratingsCount: 42,
        content: 'MINISTERIO DEL INTERIOR\nPOLICÍA NACIONAL DEL PERÚ\n\nACTA DE CONTROL DE IDENTIDAD POLICIAL\n\nEn la ciudad de [CIUDAD], el [FECHA] a las [HORA] horas, el efectivo policial que suscribe, en cumplimiento de sus funciones de prevención del delito, procedió a requerir la identificación al ciudadano [NOMBRE_CIUDADANO], identificado con DNI [DNI_CIUDADANO], domiciliado en [DIRECCION_CIUDADANO]...\n',
      ),
      CommunityPost(
        id: 'post_2',
        title: 'Acta de Registro Vehicular (D. Leg. 1194)',
        authorRank: 'MAY. PNP',
        authorName: 'Rodriguez Flores',
        authorId: 'CIP-992013',
        stars: 2.7,
        ratingsCount: 31,
        content: 'MINISTERIO DEL INTERIOR\nPOLICÍA NACIONAL DEL PERÚ\n\nACTA DE REGISTRO VEHICULAR Y ENCAUTACIÓN\n\nEn el distrito de [DISTRITO], siendo las [HORA] horas del [FECHA], personal policial de la Comisaría de [COMISARIA] procedió al registro del vehículo de placa [PLACA_VEHICULO], marca [MARCA_VEHICULO], modelo [MODELO_VEHICULO], color [COLOR_VEHICULO], conducido por [CONDUCTOR]...\n',
      ),
      CommunityPost(
        id: 'post_3',
        title: 'Acta de Lectura de Derechos del Detenido',
        authorRank: 'TNTE. PNP',
        authorName: 'Salazar Vega',
        authorId: 'CIP-551092',
        stars: 2.5,
        ratingsCount: 24,
        content: 'MINISTERIO DEL INTERIOR\nPOLICÍA NACIONAL DEL PERÚ\n\nACTA DE LECTURA DE DERECHOS DEL DETENIDO\n\nAl ciudadano [NOMBRE_DETENIDO], de nacionalidad [NACIONALIDAD], identificado con [DOCUMENTO_IDENTIDAD], se le hace saber que se encuentra en calidad de DETENIDO por la presunta comisión del delito de [DELITO], habiéndosele informado de los derechos que le asisten...\n',
      ),
      CommunityPost(
        id: 'post_4',
        title: 'Acta de Incautación de Especies e Instrumentos',
        authorRank: 'CAP. PNP',
        authorName: 'Diaz Maldonado',
        authorId: 'CIP-778841',
        stars: 2.2,
        ratingsCount: 15,
        content: 'MINISTERIO DEL INTERIOR\nPOLICÍA NACIONAL DEL PERÚ\n\nACTA DE INCAUTACIÓN Y DECOMISO DE ESPECIES\n\nEn las inmediaciones de [LUGAR], siendo las [HORA] horas del [FECHA], se procedió a la incautación de las siguientes especies e instrumentos del delito hallados en poder del presunto autor [NOMBRE_IMPUTADO]...\n',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Lógica de calificación (1 a 3 estrellas)
  void _ratePost(CommunityPost post, int rating) {
    setState(() {
      if (post.userRating == 0) {
        post.stars = ((post.stars * post.ratingsCount) + rating) / (post.ratingsCount + 1);
        post.ratingsCount += 1;
        post.userRating = rating;
      } else {
        post.stars = ((post.stars * post.ratingsCount) - post.userRating + rating) / post.ratingsCount;
        post.userRating = rating;
      }
    });
    _savePosts();
  }

  // Importar plantilla a la lista local del dispositivo
  Future<void> _importTemplate(CommunityPost post) async {
    final prefs = await SharedPreferences.getInstance();
    final localTemplates = await _templateService.loadTemplates();

    final now = DateTime.now();
    final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final Map<String, String> renamedTemplatesMap = {};
    final List<String> importedTemplateNames = [];

    // 1. Importar plantillas (actas)
    if (post.templates != null && post.templates!.isNotEmpty) {
      for (final t in post.templates!) {
        String resolvedName = t.name;
        bool hasConflict = localTemplates.any((lt) => lt.name.trim().toLowerCase() == resolvedName.trim().toLowerCase());
        if (hasConflict) {
          resolvedName = '${t.name} [${post.authorName}] [$yearMonth]';
        }
        renamedTemplatesMap[t.name] = resolvedName;
        importedTemplateNames.add(resolvedName);

        final tempToSave = Template(
          id: const Uuid().v4(),
          name: resolvedName,
          content: t.content,
          isSystem: false,
          createdBy: post.authorId,
        );
        await _templateService.saveTemplate(tempToSave);
      }
    } else {
      // Importación de actas para posts heredados (legacy)
      String resolvedName = post.title;
      bool hasConflict = localTemplates.any((lt) => lt.name.trim().toLowerCase() == resolvedName.trim().toLowerCase());
      if (hasConflict) {
        resolvedName = '${post.title} [${post.authorName}] [$yearMonth]';
      }
      renamedTemplatesMap[post.title] = resolvedName;
      importedTemplateNames.add(resolvedName);

      final tempToSave = Template(
        id: const Uuid().v4(),
        name: resolvedName,
        content: post.content,
        isSystem: false,
        createdBy: post.authorId,
      );
      await _templateService.saveTemplate(tempToSave);
    }

    // 2. Importar tipificación asociada si existe
    String? importedTypName;
    if (post.typificationName != null && post.typificationName!.trim().isNotEmpty) {
      // Cargar tipificaciones locales
      final customTypificationsJson = prefs.getString('custom_typifications');
      List<Typification> localTypifications = [];
      if (customTypificationsJson != null) {
        try {
          final List<dynamic> decoded = json.decode(customTypificationsJson);
          localTypifications = decoded.map((item) {
            return Typification(
              id: item['id'] ?? '',
              name: item['name'] ?? '',
              logic: item['logic'] ?? '',
              recommendedTemplateNames: List<String>.from(item['recommendedTemplateNames'] ?? []),
            );
          }).toList();
        } catch (_) {}
      }

      String resolvedTypName = post.typificationName!;
      bool hasTypConflict = localTypifications.any((lt) => lt.name.trim().toLowerCase() == resolvedTypName.trim().toLowerCase()) ||
          TypificationRepository.all.any((st) => st.name.trim().toLowerCase() == resolvedTypName.trim().toLowerCase());
      if (hasTypConflict) {
        resolvedTypName = '${post.typificationName!} [${post.authorName}] [$yearMonth]';
      }
      importedTypName = resolvedTypName;

      // Actualizar nombres recomendados de la tipificación para que correspondan con los nombres importados/renombrados
      final List<String> updatedRecNames = [];
      if (post.templates != null && post.templates!.isNotEmpty) {
        for (final t in post.templates!) {
          final resolvedTName = renamedTemplatesMap[t.name] ?? t.name;
          updatedRecNames.add(resolvedTName);
        }
      } else {
        final resolvedTName = renamedTemplatesMap[post.title] ?? post.title;
        updatedRecNames.add(resolvedTName);
      }

      final newTyp = Typification(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: resolvedTypName,
        logic: post.typificationLogic ?? 'Tipificación importada de la comunidad.',
        recommendedTemplateNames: updatedRecNames,
      );

      localTypifications.add(newTyp);

      // Guardar tipificaciones personalizadas actualizadas
      final List<Map<String, dynamic>> listToSave = localTypifications.map((t) {
        return {
          'id': t.id,
          'name': t.name,
          'logic': t.logic,
          'recommendedTemplateNames': t.recommendedTemplateNames,
        };
      }).toList();
      await prefs.setString('custom_typifications', json.encode(listToSave));
    }

    if (!mounted) return;

    final String templateMsg = importedTemplateNames.length == 1
        ? 'El acta "${importedTemplateNames.first}" ha sido agregada.'
        : 'Se han importado ${importedTemplateNames.length} actas: ${importedTemplateNames.join(", ")}.';

    final String typificationMsg = importedTypName != null
        ? '\nSe agregó la tipificación "$importedTypName" a tu lista.'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF00E676), // Éxito vibrante
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Importación Exitosa!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$templateMsg$typificationMsg',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPublishDialog() async {
    final results = await Future.wait([
      _templateService.loadTemplates(),
      SharedPreferences.getInstance(),
    ]);
    if (!mounted) return;

    final allTemplates = results[0] as List<Template>;
    final prefs = results[1] as SharedPreferences;

    // Solo se pueden publicar actas creadas por el usuario o importadas (isSystem == false)
    final templates = allTemplates.where((t) => !t.isSystem).toList();

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No tienes plantillas creadas o importadas para compartir. Crea una primero.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Cargar tipificaciones personalizadas locales
    final customTypificationsJson = prefs.getString('custom_typifications');
    List<Typification> customTypifications = [];
    if (customTypificationsJson != null) {
      try {
        final List<dynamic> decoded = json.decode(customTypificationsJson);
        customTypifications = decoded.map((item) {
          return Typification(
            id: item['id'] ?? '',
            name: item['name'] ?? '',
            logic: item['logic'] ?? '',
            recommendedTemplateNames: List<String>.from(item['recommendedTemplateNames'] ?? []),
          );
        }).toList();
      } catch (_) {}
    }

    // Perfil del operador para precompletar firma
    final String operatorName = prefs.getString('operator_name') ?? 'OFICIAL';
    final String operatorSurname = prefs.getString('operator_first_surname') ?? 'PNP';
    final String operatorGrade = prefs.getString('operator_grade') ?? 'SO. PNP';
    final String operatorCip = prefs.getString('operator_cip') ?? 'CIP-XXXXXX';

    final selectedTemplateIds = <String>{};
    final titleController = TextEditingController(text: 'Mi Kit de Actas de Intervención');
    final commentController = TextEditingController();
    final newTypNameController = TextEditingController();
    final newTypLogicController = TextEditingController();
    String selectedTypificationId = 'none';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: const Border(
                    top: BorderSide(color: Colors.white12, width: 1.0),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Publicar en la Comunidad',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                            onPressed: () {
                              newTypNameController.dispose();
                              newTypLogicController.dispose();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Título de la publicación
                      const Text(
                        'TÍTULO DE LA PUBLICACIÓN',
                        style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          hintText: 'Ej. Acta de Intervención Completa',
                          hintStyle: const TextStyle(color: Colors.white30),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Contexto adicional / Comentario
                      const Text(
                        'CONTEXTO ADICIONAL / COMENTARIO (DESCRIPCIÓN DE LA PUBLICACIÓN)',
                        style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          hintText: 'Describe qué estás compartiendo, el escenario de uso, intervención o sugerencias para otros efectivos...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Seleccionar Tipificación
                      const Text(
                        'ASOCIAR TIPIFICACIÓN A LA PUBLICACIÓN (OPCIONAL)',
                        style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        initialValue: selectedTypificationId,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.04),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'none',
                            child: Text('Ninguna (Solo actas sueltas)', style: TextStyle(color: Colors.white70)),
                          ),
                          const DropdownMenuItem(
                            value: 'new',
                            child: Text('+ Crear nueva tipificación para compartir', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                          ),
                          ...customTypifications.map((typ) => DropdownMenuItem(
                                value: typ.id,
                                child: Text(typ.name, style: const TextStyle(color: Colors.white)),
                              )),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            selectedTypificationId = val ?? 'none';
                            if (selectedTypificationId == 'none') {
                              // No pre-select templates
                            } else if (selectedTypificationId == 'new') {
                              if (newTypNameController.text.isNotEmpty) {
                                titleController.text = newTypNameController.text;
                              }
                            } else {
                              final matchedTyp = customTypifications.firstWhere((t) => t.id == selectedTypificationId);
                              // Pre-select templates of this typification
                              selectedTemplateIds.clear();
                              for (final temp in templates) {
                                if (matchedTyp.recommendedTemplateNames.contains(temp.name)) {
                                  selectedTemplateIds.add(temp.id);
                                }
                              }
                              titleController.text = matchedTyp.name;
                            }
                          });
                        },
                      ),
                      if (selectedTypificationId == 'new') ...[
                        const SizedBox(height: 16),
                        const Text(
                          'NOMBRE DE LA NUEVA TIPIFICACIÓN',
                          style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: newTypNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            hintText: 'Ej. Violencia Contra la Mujer',
                            hintStyle: const TextStyle(color: Colors.white30),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              titleController.text = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'LÓGICA / DESCRIPCIÓN DE LA TIPIFICACIÓN',
                          style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: newTypLogicController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            hintText: 'Ej. Protocolo de actas para violencia física o psicológica...',
                            hintStyle: const TextStyle(color: Colors.white30),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Seleccionar Plantillas
                      const Text(
                        'SELECCIONA LAS ACTAS A SUBIR (PUEDE SER UNA O VARIAS)',
                        style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: templates.length,
                          itemBuilder: (context, idx) {
                            final template = templates[idx];
                            final isSelected = selectedTemplateIds.contains(template.id);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: CheckboxListTile(
                                activeColor: Theme.of(context).colorScheme.secondary,
                                checkColor: Colors.black,
                                title: Text(
                                  template.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Creado por: ${template.createdBy ?? operatorCip}',
                                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                                ),
                                value: isSelected,
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedTemplateIds.add(template.id);
                                      if (selectedTemplateIds.length == 1) {
                                        titleController.text = template.name;
                                      } else {
                                        titleController.text = 'Kit: ${selectedTemplateIds.length} Actas de Intervención';
                                      }
                                    } else {
                                      selectedTemplateIds.remove(template.id);
                                      if (selectedTemplateIds.length == 1) {
                                        final remainingId = selectedTemplateIds.first;
                                        final remTemp = templates.firstWhere((t) => t.id == remainingId);
                                        titleController.text = remTemp.name;
                                      } else if (selectedTemplateIds.isEmpty) {
                                        titleController.text = '';
                                      } else {
                                        titleController.text = 'Kit: ${selectedTemplateIds.length} Actas de Intervención';
                                      }
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Firma / Créditos
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.secondary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Publicado como: $operatorGrade $operatorName $operatorSurname ($operatorCip)',
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: selectedTemplateIds.isEmpty
                            ? null
                            : () {
                                final List<Template> selectedList = templates
                                    .where((t) => selectedTemplateIds.contains(t.id))
                                    .toList();

                                String? finalTypName;
                                String? finalTypLogic;

                                if (selectedTypificationId == 'new') {
                                  finalTypName = newTypNameController.text.trim();
                                  finalTypLogic = newTypLogicController.text.trim();
                                  if (finalTypName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Por favor, ingresa el nombre de la tipificación.')),
                                    );
                                    return;
                                  }
                                } else if (selectedTypificationId != 'none') {
                                  final match = customTypifications.firstWhere((t) => t.id == selectedTypificationId);
                                  finalTypName = match.name;
                                  finalTypLogic = match.logic;
                                }

                                // Agrupar contenidos de actas para compatibilidad
                                final buffer = StringBuffer();
                                for (int i = 0; i < selectedList.length; i++) {
                                  final t = selectedList[i];
                                  buffer.writeln('── ACTA ${i + 1}: ${t.name.toUpperCase()} ──');
                                  buffer.writeln(t.content);
                                  if (i < selectedList.length - 1) {
                                    buffer.writeln();
                                  }
                                }
                                final newPost = CommunityPost(
                                  id: const Uuid().v4(),
                                  title: titleController.text.trim().isEmpty
                                      ? 'Fórmula Policial Compartida'
                                      : titleController.text.trim(),
                                  content: buffer.toString(),
                                  authorName: '$operatorName $operatorSurname',
                                  authorId: operatorCip,
                                  authorRank: operatorGrade.toUpperCase(),
                                  authorComment: commentController.text.trim().isEmpty
                                      ? null
                                      : commentController.text.trim(),
                                  stars: 3.0,
                                  ratingsCount: 1,
                                  userRating: 3,
                                  typificationName: finalTypName,
                                  typificationLogic: finalTypLogic,
                                  templates: selectedList,
                                );

                                setState(() {
                                  _posts.insert(0, newPost);
                                });
                                _savePosts();

                                newTypNameController.dispose();
                                newTypLogicController.dispose();
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.cloud_upload_rounded, color: Colors.black, size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                '¡Plantilla Publicada!',
                                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                                              ),
                                              Text(
                                                'Tu aporte ya está visible en la red de comunidad.',
                                                style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontSize: 11, fontFamily: 'Inter'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'COMPARTIR CON LA COMUNIDAD',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<CommunityPost> filteredPosts;
    if (_searchQuery.isEmpty) {
      final sortedPosts = List<CommunityPost>.from(_posts);
      sortedPosts.sort((a, b) => b.stars.compareTo(a.stars));
      filteredPosts = sortedPosts.take(3).toList();
    } else {
      final matches = _posts.where((post) {
        return post.title.toLowerCase().contains(_searchQuery) ||
            post.authorName.toLowerCase().contains(_searchQuery) ||
            post.authorRank.toLowerCase().contains(_searchQuery);
      }).toList();
      matches.sort((a, b) => b.stars.compareTo(a.stars));
      filteredPosts = matches.take(3).toList();
    }

    if (_selectedPostForPreview != null) {
      final post = _selectedPostForPreview!;
      final hasTemplates = post.templates != null && post.templates!.isNotEmpty;
      final currentTemplateName = hasTemplates
          ? post.templates![_previewingTemplateIndex].name
          : post.title;
      final currentTemplateContent = hasTemplates
          ? post.templates![_previewingTemplateIndex].content
          : post.content;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedPostForPreview = null;
              });
              widget.onPreviewChanged?.call(false);
            },
          ),
          title: Text(
            post.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Detalles de la Tipificación asociada si existe
              if (post.typificationName != null && post.typificationName!.trim().isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.gavel_rounded, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TIPIFICACIÓN ASOCIADA',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.typificationName!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (post.typificationLogic != null && post.typificationLogic!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                post.typificationLogic!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (post.authorComment != null && post.authorComment!.trim().isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CONTEXTO Y SUGERENCIAS DEL AUTOR',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.authorComment!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Pestañas (Tabs) de selección de Acta si comparte múltiples actas
              if (post.templates != null && post.templates!.length > 1) ...[
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.templates!.length,
                    itemBuilder: (context, index) {
                      final t = post.templates![index];
                      final isSelected = _previewingTemplateIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            t.name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFD700),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _previewingTemplateIndex = index;
                              });
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFFFD700) : Colors.white10,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ],
              // Vista Previa de Documento Impreso/PDF Realista
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white, // Color de papel real
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sello / Encabezado oficial simulado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'POLICÍA NACIONAL DEL PERÚ',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              post.authorRank,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              'CÓDIGO: ${post.authorId}',
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 7.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        // Mini escudo o sello redondo simulado
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black87, width: 1.5),
                          ),
                          child: const Icon(Icons.security, color: Colors.black87, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Título del documento centrado
                    Center(
                      child: Text(
                        currentTemplateName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          letterSpacing: 1.2,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Cuerpo del acta (PDF Simulado)
                    _buildPrintedPreviewText(currentTemplateContent),
                    const SizedBox(height: 48),
                    // Línea de Firma simulada
                    Center(
                      child: Column(
                        children: [
                          Container(width: 140, height: 1, color: Colors.black54),
                          const SizedBox(height: 6),
                          Text(
                            post.authorName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            post.authorRank,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 8,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            'EFECTIVO PNP',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Panel de Acciones e Interacción en la Vista Previa
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'CALIFICAR E IMPORTAR PLANTILLA',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Calificación interactiva dentro de la Vista Previa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calificación del documento:',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter'),
                        ),
                        Row(
                          children: List.generate(3, (starIndex) {
                            final starValue = starIndex + 1;
                            final isSelected = post.userRating >= starValue;
                            return GestureDetector(
                              onTap: () {
                                _ratePost(post, starValue);
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Icon(
                                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                                  size: 28,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 20),
                    // Botón para Importar directamente desde la vista previa
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E80F0), Color(0xFF00D2FF)],
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _importTemplate(post),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text(
                                'IMPORTAR A ACTAS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CustomAppDrawer(isCommunityPage: true),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_focusNode.hasFocus) {
              _focusNode.unfocus();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Listado de plantillas
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                bottom: 24,
                child: filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                            const SizedBox(height: 12),
                            const Text(
                              'No se encontraron plantillas en la red.',
                              style: TextStyle(color: Colors.white38, fontSize: 13, fontFamily: 'Inter'),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                          if (isKeyboardOpen) {
                            return ListView.builder(
                              itemCount: filteredPosts.length,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  height: 125,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildCommunityCard(filteredPosts[index], isCompact: true),
                                  ),
                                );
                              },
                            );
                          } else {
                            return Column(
                              children: [
                                for (int i = 0; i < 3; i++) ...[
                                  if (i < filteredPosts.length)
                                    Expanded(
                                      child: _buildCommunityCard(filteredPosts[i], isCompact: false),
                                    )
                                  else
                                    const Expanded(
                                      child: SizedBox(),
                                    ),
                                  if (i < 2)
                                    const SizedBox(height: 14),
                                ],
                              ],
                            );
                          }
                        },
                      ),
              ),
              // Botón del menú lateral (Hamburger)
              Positioned(
                top: 12,
                left: 16,
                child: Builder(
                  builder: (context) => Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white70),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
              ),
              // Buscador superior con Glassmorphism (Siempre visible)
              Positioned(
                top: 12,
                left: 80,
                right: 78,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                            theme.colorScheme.surface.withValues(alpha: 0.45),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search_rounded, 
                            color: Color(0xFFFFD700), 
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
                              decoration: const InputDecoration(
                                hintText: 'Buscar plantilla o autor policial...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            const SizedBox(width: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Botón Flotante "+" (Solo publicar)
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFEA00), Color(0xFFFF5722)], 
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showPublishDialog,
                          child: const Center(
                            child: Icon(
                              Icons.add_rounded, 
                              color: Colors.black, 
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(CommunityPost post, {required bool isCompact}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Avatar, Author Info, Stars
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: isCompact ? 30 : 36,
                height: isCompact ? 30 : 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  post.authorName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900, 
                    fontSize: isCompact ? 12 : 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Rango
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            post.authorRank,
                            style: const TextStyle(
                              color: Color(0xFF22D3EE), 
                              fontWeight: FontWeight.w900, 
                              fontSize: 8,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.authorId,
                      style: const TextStyle(color: Colors.white30, fontSize: 9, fontFamily: 'Inter'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      post.stars.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFFFFC107), 
                        fontWeight: FontWeight.w900, 
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (!isCompact) const Spacer(),
          if (isCompact) const SizedBox(height: 8),
          
          // Post Title
          Text(
            post.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              fontSize: isCompact ? 13.5 : 15.5, 
              fontFamily: 'Inter',
            ),
          ),
          
          // Snippet (hidden in compact mode)
          if (!isCompact) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 3.5,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            post.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54, 
                              fontSize: 11, 
                              fontFamily: 'monospace', 
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          
          if (!isCompact) const Spacer(),
          if (isCompact) const SizedBox(height: 6),
          
          // Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_rounded, color: Color(0xFFFFD700), size: 18),
                tooltip: 'Vista previa',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                onPressed: () {
                  setState(() {
                    _selectedPostForPreview = post;
                    _previewingTemplateIndex = 0;
                  });
                  widget.onPreviewChanged?.call(true);
                },
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E80F0), Color(0xFF00D2FF)],
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _importTemplate(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 12, color: Colors.white),
                  label: const Text(
                    'IMPORTAR',
                    style: TextStyle(
                      fontSize: 9.5, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 0.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
