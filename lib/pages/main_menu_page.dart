import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/intervention_provider.dart';
import '../models/intervention_session.dart';
import '../services/template_service.dart';
import 'intervention_session_page.dart';
import '../widgets/custom_app_drawer.dart';
import '../models/typification.dart';
import '../models/typification_repository.dart';
import '../models/template.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with SingleTickerProviderStateMixin {
  String _operatorName = 'EFECTIVO';
  String _operatorGrade = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // State variables for inline typification selection
  int _interventionStep = 0; // 0: Main, 1: Typification list, 2: Document selection
  Typification? _selectedTypification;
  List<Template> _allTemplates = [];
  List<Template> _selectedTemplates = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOperatorInfo();
    _loadTemplates();
    context.read<InterventionProvider>().loadSavedSessions();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    final svc = TemplateService();
    final temps = await svc.loadTemplates();
    if (mounted) {
      setState(() {
        _allTemplates = temps;
      });
    }
  }

  Future<void> _loadOperatorInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _operatorName = prefs.getString('operator_name') ?? 'EFECTIVO';
          _operatorGrade = prefs.getString('operator_grade') ?? '';
        });
      }
    } catch (_) {}
  }





  void _showAddExtraTemplatesSheet() {
    String modalSearchQuery = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1115),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white10),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _allTemplates
                .where((t) => t.name.toLowerCase().contains(modalSearchQuery.toLowerCase()))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SELECCIONAR ACTAS',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar acta...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30, size: 18),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        modalSearchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final t = filtered[i];
                        final isSelected = _selectedTemplates.any((st) => st.name == t.name);
                        return CheckboxListTile(
                          title: Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          value: isSelected,
                          activeColor: const Color(0xFFFF6B00),
                          onChanged: (val) {
                            if (val == true) {
                              setState(() => _selectedTemplates.add(t));
                              setModalState(() {});
                            } else {
                              setState(() => _selectedTemplates.removeWhere((st) => st.name == t.name));
                              setModalState(() {});
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final displayName = _operatorGrade.isNotEmpty
        ? '${_operatorGrade.toUpperCase()} ${_operatorName.toUpperCase()}'
        : _operatorName.toUpperCase();

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: Colors.black,
      drawer: const CustomAppDrawer(isMainMenu: true),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Imagen de fondo (De la mitad hacia arriba, oscurecida) ──────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.70,
            child: Opacity(
              opacity: 0.25, // Aumentado para más claridad y mejor visibilidad
              child: Image.asset(
                'assets/efectivos_plamay.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error cargando fondo del menu principal: $error');
                  return const SizedBox();
                },
              ),
            ),
          ),

          // ── Overlay degradado para oscurecer y fundir con el negro abajo ─────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.71,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.30), // Reducido para mayor claridad arriba
                    Colors.black.withValues(alpha: 0.15), // Transparente medio
                    Colors.black,                         // Negro puro abajo
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Contenido principal ────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar manual con navegación dinámica hacia atrás ────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Builder(
                    builder: (ctx) => IconButton(
                      icon: Icon(
                        _interventionStep > 0 ? Icons.arrow_back_rounded : Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        if (_interventionStep > 0) {
                          setState(() {
                            _interventionStep--;
                          });
                        } else {
                          Scaffold.of(ctx).openDrawer();
                        }
                      },
                    ),
                  ),
                ),

                const Spacer(),

                // ── Zona de texto inferior ─────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isKeyboardOpen) ...[
                            // Logo ACTIUM con degradado naranja-rojo
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFF6B00), Color(0xFFE50914)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: const Text(
                                'ACTIUM',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'POLICÍA NACIONAL DEL PERÚ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white70,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                                children: [
                                  const TextSpan(text: 'BIENVENIDO, '),
                                  TextSpan(
                                    text: displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Renderizado según el paso de intervención ──
                          if (_interventionStep == 0) ...[
                            // ── Botones de acción del menú principal ──
                            Row(
                              children: [
                                // Botón principal: NUEVA INTERVENCIÓN
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _interventionStep = 1;
                                        _selectedTypification = null;
                                        _selectedTemplates = [];
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF6B1010), Color(0xFF3D0000)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE50914).withValues(alpha: 0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'NUEVA INTERVENCIÓN',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (_interventionStep == 1) ...[
                            // ── Paso 1: Selección de tipificación con transparencia/glassmorphism ──
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.list_alt_rounded, color: Color(0xFFFFD700), size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'SELECCIONE DELITO / TIPIFICACIÓN',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              letterSpacing: 1.0,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _searchController,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Buscar delito...',
                                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30, size: 18),
                                          filled: true,
                                          fillColor: Colors.white.withValues(alpha: 0.04),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _searchQuery = val;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),

                                      // Botón para Caso Personalizado (Selección libre)
                                      Card(
                                        color: const Color(0xFF1B80F0).withValues(alpha: 0.15),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: const BorderSide(color: Color(0xFF1B80F0), width: 1.2),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF1B80F0)),
                                          title: const Text(
                                            'CASO PERSONALIZADO (SELECCIÓN LIBRE)',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          subtitle: const Text(
                                            'Inicia sin actas pre-seleccionadas y elige las tuyas',
                                            style: TextStyle(color: Colors.white60, fontSize: 10),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedTypification = const Typification(
                                                id: 'custom',
                                                name: 'Caso Personalizado',
                                                logic: 'custom',
                                                recommendedTemplateNames: [],
                                              );
                                              _selectedTemplates = [];
                                              _interventionStep = 2;
                                            });
                                            // Abre automáticamente la selección de actas
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              _showAddExtraTemplatesSheet();
                                            });
                                          },
                                        ),
                                      ),

                                      Container(
                                        constraints: const BoxConstraints(maxHeight: 220),
                                        child: Builder(
                                          builder: (ctx) {
                                            final filtered = TypificationRepository.all
                                                .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                                .toList();
                                            return ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: filtered.length,
                                              itemBuilder: (context, i) {
                                                final t = filtered[i];
                                                return Card(
                                                  color: Colors.white.withValues(alpha: 0.02),
                                                  margin: const EdgeInsets.only(bottom: 6),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                                                  ),
                                                  child: ListTile(
                                                    dense: true,
                                                    title: Text(
                                                      t.name,
                                                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter'),
                                                    ),
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedTypification = t;
                                                        _selectedTemplates = _allTemplates
                                                            .where((tmp) => t.recommendedTemplateNames.contains(tmp.name))
                                                            .toList();
                                                        _interventionStep = 2;
                                                      });
                                                    },
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else if (_interventionStep == 2) ...[
                            // ── Paso 2: Confirmación y adición de actas ──
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _selectedTypification?.name.toUpperCase() ?? 'DETALLE DE INTERVENCIÓN',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                fontFamily: 'Inter',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            onPressed: _showAddExtraTemplatesSheet,
                                            icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFFFF6B00)),
                                            label: const Text('Extra', style: TextStyle(color: Color(0xFFFF6B00), fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        constraints: const BoxConstraints(maxHeight: 180),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: _selectedTemplates.length,
                                          itemBuilder: (context, i) {
                                            final t = _selectedTemplates[i];
                                            return Card(
                                              color: Colors.white.withValues(alpha: 0.01),
                                              margin: const EdgeInsets.only(bottom: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                leading: const Icon(Icons.description_rounded, color: Colors.white54, size: 16),
                                                title: Text(t.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedTemplates.removeAt(i);
                                                    });
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6B1010),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () {
                                          final session = InterventionSession(
                                            name: 'Intervención - ${_selectedTypification!.name}',
                                            typificationId: _selectedTypification!.id,
                                            documents: _selectedTemplates.map((t) => InterventionDocument(title: t.name, content: t.content)).toList(),
                                          );
                                          final provider = context.read<InterventionProvider>();
                                          provider.startNewSession(session, typificationName: _selectedTypification!.name, conDetenido: true);
                                          
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const InterventionSessionPage(showLiveWizard: true),
                                            ),
                                          );
                                        },
                                        child: const Text('Iniciar Editor en Vivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}


