import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/intervention_provider.dart';
import '../services/template_service.dart';
import '../models/intervention_session.dart';
import '../services/intervention_service.dart';
import '../pages/main_menu_page.dart';
import '../pages/profile_page.dart';
import '../pages/proceso_inmediato_page.dart';
import '../pages/intervention_session_page.dart';
import '../pages/templates_page.dart';
import '../pages/community_page.dart';

class CustomAppDrawer extends StatefulWidget {
  final bool isSessionPage;
  final bool isMainMenu;
  final bool isCommunityPage;
  final Function(int)? onTabSelected;
  const CustomAppDrawer({
    super.key,
    this.isSessionPage = false,
    this.isMainMenu = false,
    this.isCommunityPage = false,
    this.onTabSelected,
  });

  @override
  State<CustomAppDrawer> createState() => _CustomAppDrawerState();
}

class _CustomAppDrawerState extends State<CustomAppDrawer>
    with SingleTickerProviderStateMixin {
  final _drawerSearchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchField = false;
  String _operatorName = 'Operador';
  String _operatorGrade = '';
  String _operatorId = '4892';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadOperatorInfo();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(-0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    // Trigger animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _drawerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadOperatorInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _operatorName = prefs.getString('operator_name') ?? 'Operador';
        _operatorGrade = prefs.getString('operator_grade') ?? '';
        _operatorId = prefs.getString('operator_cip') ?? prefs.getString('operator_id') ?? '4892';
      });
    } catch (_) {}
  }

  Future<void> _resumeSession(BuildContext context, SavedSession saved) async {
    final templateService = TemplateService();
    final allTemplates = await templateService.loadTemplates();

    final docs = saved.documentTitles.map((title) {
      final match = allTemplates.where((t) => t.name == title).toList();
      return InterventionDocument(
        title: title,
        content: match.isNotEmpty ? match.first.content : '',
      );
    }).toList();

    if (!context.mounted) return;

    context.read<InterventionProvider>().resumeSession(saved, docs);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const InterventionSessionPage()),
      (route) => false,
    );
  }

  Future<void> _deleteSession(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar intervención',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter'),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta intervención guardada?',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38, fontFamily: 'Inter')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<InterventionProvider>().deleteSavedSession(id);
    }
  }

  Future<bool> _promptSaveIfSession(BuildContext context) async {
    if (!widget.isSessionPage) return true;

    final provider = context.read<InterventionProvider>();
    final session = provider.currentSession;
    if (session == null) return true;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('¿Guardar progreso?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Está a punto de salir de la intervención activa.\n¿Desea guardar su progreso?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Salir sin guardar', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );

    if (shouldSave == null) return false;

    if (shouldSave) {
      if (session.name.isEmpty || session.name.startsWith('Intervención')) {
        final nameController = TextEditingController(text: session.name);
        if (!context.mounted) return false;
        final newName = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white10),
            ),
            title: const Text('Asignar nombre', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre de la intervención',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
                child: const Text('Guardar', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
        
        if (newName == null) return false;
        if (newName.isNotEmpty) {
          session.name = newName;
        }
      }
      await provider.saveCurrentSession();
    }
    return true;
  }

  void _handleNav(BuildContext context, Future<void> Function() action) async {
    final proceed = await _promptSaveIfSession(context);
    if (!proceed) return;
    
    if (context.mounted) {
      Navigator.pop(context); // Close Drawer
      await action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterventionProvider>();
    final savedSessions = provider.savedSessions;
    final pinnedIds = provider.pinnedIds;
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: const Color(0xFF0F1115),
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1115),
          border: Border(
            right: BorderSide(color: Colors.white10, width: 1.0),
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: StatefulBuilder(
              builder: (context, setDrawerState) {
                final filteredSessions = savedSessions
                    .where((s) =>
                        s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (s.typificationName != null &&
                            s.typificationName!.toLowerCase().contains(_searchQuery.toLowerCase())))
                    .toList();

                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // ── LOGO / TÍTULO ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF5722)],
                              ).createShader(bounds),
                              child: const Text(
                                'ACTIUM',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                'PNP',
                                style: TextStyle(
                                  color: Color(0xFFFF7043),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── DIVISOR ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                      ),

                      const SizedBox(height: 16),

                      // ── NAV: NUEVA INTERVENCIÓN ───────────────────────
                      _buildNavCard(
                        context: context,
                        icon: Icons.add_circle_outline_rounded,
                        label: 'NUEVA INTERVENCIÓN',
                        isActive: widget.isMainMenu,
                        accentColor: theme.colorScheme.tertiary,
                        onTap: () => _handleNav(context, () async {
                          if (widget.isMainMenu) {
                            widget.onTabSelected?.call(0);
                            return;
                          }
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const MainMenuPage()),
                              (route) => false,
                            );
                          }
                        }),
                      ),

                      const SizedBox(height: 8),

                      // ── NAV: COMUNIDAD ────────────────────────────────
                      _buildNavCard(
                        context: context,
                        icon: Icons.people_alt_rounded,
                        label: 'COMUNIDAD',
                        isActive: widget.isCommunityPage,
                        accentColor: const Color(0xFFFFD700),
                        onTap: () => _handleNav(context, () async {
                          if (widget.isCommunityPage) return;
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CommunityPage()),
                            );
                          }
                        }),
                      ),

                      const SizedBox(height: 12),

                      // ── PRÓXIMO PAGO MEF ──────────────────────────────
                      _buildMefPaymentCard(),

                      const SizedBox(height: 8),

                      // ── HEADER INTERVENCIONES GUARDADAS ──────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _showSearchField
                            ? Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1.0,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, color: Colors.white30, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _drawerSearchController,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter'),
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          hintText: 'Buscar...',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onChanged: (val) {
                                          setDrawerState(() => _searchQuery = val);
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _drawerSearchController.clear();
                                        setDrawerState(() {
                                          _searchQuery = '';
                                          _showSearchField = false;
                                        });
                                      },
                                      child: const Icon(Icons.close, color: Colors.white30, size: 16),
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'INTERVENCIONES GUARDADAS',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setDrawerState(() => _showSearchField = true);
                                    },
                                    tooltip: 'Buscar intervención',
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),

                      // ── LISTADO DE SESIONES ───────────────────────────
                      Expanded(
                        child: filteredSessions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.01),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _searchQuery.isEmpty ? Icons.folder_open_rounded : Icons.search_off_rounded,
                                          size: 32,
                                          color: Colors.white24,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Sin intervenciones'
                                            : 'No se encontraron resultados',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: filteredSessions.length,
                                itemBuilder: (context, index) {
                                  final s = filteredSessions[index];
                                  final isPinned = pinnedIds.contains(s.id);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1C22),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white10,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _handleNav(context, () async {
                                          final provider = context.read<InterventionProvider>();
                                          if (widget.isSessionPage && provider.currentSession?.id == s.id) {
                                            return;
                                          }
                                          if (context.mounted) {
                                            _resumeSession(context, s);
                                          }
                                        }),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          child: Row(
                                            children: [
                                              if (isPinned) ...[
                                                const Icon(Icons.push_pin_rounded, color: Colors.white, size: 14),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  s.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                    fontFamily: 'Inter',
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 18),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                color: theme.colorScheme.surface,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                onSelected: (value) {
                                                  if (value == 'pin') {
                                                    context.read<InterventionProvider>().togglePinSession(s.id);
                                                  } else if (value == 'delete') {
                                                    _deleteSession(context, s.id);
                                                  }
                                                },
                                                itemBuilder: (ctx) => [
                                                  PopupMenuItem(
                                                    value: 'pin',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                                                          color: theme.colorScheme.primary,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          isPinned ? 'Desfijar' : 'Fijar',
                                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: const [
                                                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                                        SizedBox(width: 8),
                                                        Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // ── FOOTER: PERFIL DE OPERADOR ────────────────────
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0C0E12),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white10,
                              width: 1.0,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _handleNav(context, () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                                  ).then((_) => _loadOperatorInfo());
                                }),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary.withValues(alpha: 0.7),
                                              theme.colorScheme.primary,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _operatorName.isNotEmpty ? _operatorName[0].toUpperCase() : 'G',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            fontFamily: 'Geist',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _operatorName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                fontFamily: 'Inter',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _operatorGrade.isNotEmpty
                                                  ? '$_operatorGrade · CIP $_operatorId'
                                                  : 'CIP: $_operatorId',
                                              style: TextStyle(
                                                color: theme.colorScheme.secondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildQuickActionButton(
                              icon: Icons.key_rounded,
                              color: theme.colorScheme.tertiary,
                              tooltip: 'Tokens y API Keys',
                              onTap: () => _handleNav(context, () async {
                                ProfilePage.showLocalApiKeysDialog(context);
                              }),
                            ),
                            const SizedBox(width: 6),
                            _buildQuickActionButton(
                              icon: Icons.flash_on_rounded,
                              color: theme.colorScheme.error,
                              tooltip: 'Vía Rápida (Proceso Inmediato)',
                              onTap: () => _handleNav(context, () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProcesoInmediatoPage()),
                                );
                              }),
                            ),
                            const SizedBox(width: 6),
                            _buildQuickActionButton(
                              icon: Icons.folder_copy_rounded,
                              color: theme.colorScheme.primary,
                              tooltip: 'Gestionar Actas y Plantillas',
                              onTap: () => _handleNav(context, () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TemplatesPage()),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta para items de navegación principal
  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1E222B)
                  : const Color(0xFF14161B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? accentColor.withValues(alpha: 0.3)
                    : Colors.white10,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // Indicador lateral activo
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? accentColor : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  icon,
                  color: isActive ? accentColor : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: isActive ? Colors.white : Colors.white70,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 6),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMefPaymentCard() {
    final now = DateTime.now();
    final payments = [
      {'month': 1, 'day': 22, 'monthName': 'Enero'},
      {'month': 2, 'day': 19, 'monthName': 'Febrero'},
      {'month': 3, 'day': 19, 'monthName': 'Marzo'},
      {'month': 4, 'day': 22, 'monthName': 'Abril'},
      {'month': 5, 'day': 21, 'monthName': 'Mayo'},
      {'month': 6, 'day': 18, 'monthName': 'Junio'},
      {'month': 7, 'day': 20, 'monthName': 'Julio'},
      {'month': 8, 'day': 21, 'monthName': 'Agosto'},
      {'month': 9, 'day': 18, 'monthName': 'Setiembre'},
      {'month': 10, 'day': 21, 'monthName': 'Octubre'},
      {'month': 11, 'day': 19, 'monthName': 'Noviembre'},
      {'month': 12, 'day': 17, 'monthName': 'Diciembre'},
    ];

    Map<String, dynamic> activePayment = payments.last;
    for (final p in payments) {
      final pMonth = p['month'] as int;
      final pDay = p['day'] as int;
      if (now.year < 2026) {
        activePayment = payments.first;
        break;
      } else if (now.year == 2026) {
        if (now.month < pMonth) {
          activePayment = p;
          break;
        } else if (now.month == pMonth && now.day <= pDay) {
          activePayment = p;
          break;
        }
      }
    }

    final dayNum = activePayment['day'];
    final monthName = (activePayment['monthName'] as String).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 11, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            'PRÓXIMO PAGO: $dayNum $monthName',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}
