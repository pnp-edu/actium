import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/intervention_provider.dart';
import '../services/dni_service.dart';
import '../services/ai_tactical_service.dart';
import '../services/location_service.dart';
import 'templates_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static void showLocalApiKeysDialog(BuildContext context) {
    final dniService = DniService();
    final keyController = TextEditingController();
    final groqKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<String?>>(
          future: Future.wait([
            dniService.getApiKey(),
            AiTacticalService.getOrLoadToken(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              keyController.text = snapshot.data![0] ?? '';
              groqKeyController.text = snapshot.data![1] ?? '';
            }
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text(
                'Ajustes (API KEYS)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Token de Factiliza (DNI)',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final uri = Uri.parse('https://app.factiliza.com/reniec/token');
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } catch (_) {}
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Obtener Token', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: keyController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Pega tu token de Factiliza aquí...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.vpn_key, color: Colors.white54, size: 18),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Se utiliza para consultar datos del DNI (imputado, testigo y agraviado).',
                      style: TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'API Key de Groq Cloud (IA)',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final uri = Uri.parse('https://console.groq.com/keys');
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } catch (_) {}
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Obtener API Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: groqKeyController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Pega tu API Key de Groq aquí...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixIcon: const Icon(Icons.psychology_alt, color: Colors.white54, size: 18),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Se utiliza para auditar actas y usar el Candado Semántico.',
                      style: TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final newDniKey = keyController.text.trim();
                    final newGroqKey = groqKeyController.text.trim();

                    bool validationSuccess = true;
                    if (newGroqKey.isNotEmpty && newGroqKey != (snapshot.data?[1] ?? '')) {
                      final esValido = await AiTacticalService.validarToken(newGroqKey);
                      if (!esValido) {
                        validationSuccess = false;
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠ La API Key de Groq ingresada es inválida o no responde. No se guardó.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }

                    if (validationSuccess) {
                      await dniService.saveApiKey(newDniKey);
                      await AiTacticalService.saveToken(newGroqKey);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Ajustes guardados correctamente'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  // Controllers para todos los campos
  final _nameController = TextEditingController();
  final _firstSurnameController = TextEditingController();
  final _secondSurnameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _unitController = TextEditingController();
  final _cityController = TextEditingController();
  final _roleController = TextEditingController();
  final _cipController = TextEditingController();

  // Focus nodes para auto-guardado
  final _nameFocus = FocusNode();
  final _firstSurnameFocus = FocusNode();
  final _secondSurnameFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _roleFocus = FocusNode();
  final _cipFocus = FocusNode();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocating = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();

    // Auto-guardado al perder foco en cada campo
    for (final fn in [_nameFocus, _firstSurnameFocus, _secondSurnameFocus, _unitFocus, _cityFocus, _roleFocus, _cipFocus]) {
      fn.addListener(() {
        if (!fn.hasFocus) _autoSave();
      });
    }

    // Listener para actualizar dinámicamente la UI de validación de CIP
    _cipController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final ctrl in [_nameController, _firstSurnameController, _secondSurnameController, _gradeController, _unitController, _cityController, _roleController, _cipController]) {
      ctrl.dispose();
    }
    for (final fn in [_nameFocus, _firstSurnameFocus, _secondSurnameFocus, _unitFocus, _cityFocus, _roleFocus, _cipFocus]) {
      fn.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString('operator_name') ?? '';
        _firstSurnameController.text = prefs.getString('operator_first_surname') ?? '';
        _secondSurnameController.text = prefs.getString('operator_second_surname') ?? '';
        _gradeController.text = prefs.getString('operator_grade') ?? '';
        _unitController.text = prefs.getString('operator_unit') ?? '';
        _cityController.text = prefs.getString('operator_city') ?? '';
        _roleController.text = prefs.getString('operator_role') ?? '';
        _cipController.text = prefs.getString('operator_cip') ?? '';
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _autoSave() async {
    if (mounted) setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('operator_name', _nameController.text.trim().toUpperCase());
      await prefs.setString('operator_first_surname', _firstSurnameController.text.trim().toUpperCase());
      await prefs.setString('operator_second_surname', _secondSurnameController.text.trim().toUpperCase());
      await prefs.setString('operator_grade', _gradeController.text.trim());
      await prefs.setString('operator_unit', _unitController.text.trim().toUpperCase());
      await prefs.setString('operator_city', _cityController.text.trim().toUpperCase());
      await prefs.setString('operator_role', _roleController.text.trim().toUpperCase());
      await prefs.setString('operator_cip', _cipController.text.trim());

      if (mounted) {
        await context.read<InterventionProvider>().reloadOperatorInfo();
      }
    } catch (_) {}

    // Esperar un instante para mostrar de forma fluida el estado de guardado
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _detectLocationAndShowSelector() async {
    setState(() => _isLocating = true);
    try {
      final result = await LocationService.getOperatorLocationData();

      if (!mounted) return;

      // Autorellenar y guardar la ciudad detectada
      setState(() {
        _cityController.text = result.city;
      });
      await _autoSave();

      if (!mounted) return;

      // Mostrar bottom sheet de selección de comisarías PNP
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.white10, width: 1),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Color(0xFFFF5722), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'COMISARÍAS PNP CERCANAS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.8,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Coordenadas: ${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)} · Ciudad: ${result.city}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: result.nearbyStations.length,
                    itemBuilder: (context, index) {
                      final station = result.nearbyStations[index];
                      final distStr = station.distanceKm > 0
                          ? '${station.distanceKm.toStringAsFixed(2)} km'
                          : 'Ubicación de referencia';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: Color(0xFFFF5722), size: 16),
                          ),
                          title: Text(
                            station.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          subtitle: Text(
                            distStr,
                            style: const TextStyle(color: Colors.white38, fontSize: 10.5, fontFamily: 'Inter'),
                          ),
                          onTap: () {
                            setState(() {
                              _unitController.text = station.name;
                            });
                            _autoSave();
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Ingresar manualmente / Cancelar',
                    style: TextStyle(color: Colors.white54, fontFamily: 'Inter', fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            title: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text('Ubicación no disponible', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'No se pudo obtener la ubicación o consultar las comisarías.\n\nDetalle: ${e.toString().replaceAll('Exception: ', '')}\n\nIngresa tu ciudad y comisaría de forma manual.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontFamily: 'Inter'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  String get _fullName {
    final parts = [
      _firstSurnameController.text.trim(),
      _secondSurnameController.text.trim(),
      _nameController.text.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'OFICIAL' : parts.join(' ').toUpperCase();
  }

  String get _avatarInitial {
    final name = _nameController.text.trim();
    final surname = _firstSurnameController.text.trim();
    if (surname.isNotEmpty) return surname[0].toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'G';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── HERO SECTION ──────────────────────────────────────────
          _buildHeroSection(context),

          // ── TABS ─────────────────────────────────────────────────
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF5722),
              indicatorWeight: 2.5,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'PERSONAL'),
                Tab(text: 'LABORAL'),
              ],
            ),
          ),

          // ── TAB CONTENT ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalTab(),
                _buildLaboralTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        // Fondo con gradiente animado del tema
        Container(
          height: 210,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A0A00),
                Color(0xFF3D1200),
                Color(0xFF6B1E00),
              ],
            ),
          ),
        ),
        // Capa de patrón glassmorphic sutil
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Orbes decorativos
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF5722).withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Contenido del hero
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                // Fila superior: Botón Atrás + Estado Sincronización
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isSaving ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_done_rounded, color: Colors.greenAccent, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Guardado',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Avatar
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFE50914)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.40),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _avatarInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 34,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Nombre completo
                Text(
                  _fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    fontFamily: 'Inter',
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_gradeController.text.isNotEmpty || _cipController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (_gradeController.text.isNotEmpty) _gradeController.text,
                      if (_cipController.text.isNotEmpty) 'CIP ${_cipController.text}',
                    ].join(' · '),
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── TAB: PERSONAL ─────────────────────────────────────────────────────
  Widget _buildPersonalTab() {
    final bool isCipValid = _cipController.text.length == 8;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('DATOS DE IDENTIFICACIÓN'),
          const SizedBox(height: 14),
          _buildAutoSaveField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'Nombres',
            icon: Icons.person_rounded,
            hint: 'EJ. JUAN MANUEL',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 14),
          _buildAutoSaveField(
            controller: _firstSurnameController,
            focusNode: _firstSurnameFocus,
            label: 'Primer Apellido',
            icon: Icons.person_outline_rounded,
            hint: 'EJ. PÉREZ',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 14),
          _buildAutoSaveField(
            controller: _secondSurnameController,
            focusNode: _secondSurnameFocus,
            label: 'Segundo Apellido',
            icon: Icons.person_outline_rounded,
            hint: 'EJ. GÓMEZ',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 14),
          _buildAutoSaveField(
            controller: _cipController,
            focusNode: _cipFocus,
            label: 'Número de CIP',
            icon: Icons.badge_rounded,
            hint: 'EJ. 31245678',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            suffixIcon: _cipController.text.isNotEmpty
                ? (isCipValid
                    ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20)
                    : const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20))
                : null,
          ),
          if (_cipController.text.isNotEmpty && !isCipValid) ...[
            const SizedBox(height: 4),
            const Text(
              '⚠ El CIP debe tener exactamente 8 dígitos',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 10.5, fontFamily: 'Inter'),
            ),
          ],
          const SizedBox(height: 32),
          _buildAcercaDeCard(),
        ],
      ),
    );
  }

  // ── TAB: LABORAL ──────────────────────────────────────────────────────
  Widget _buildLaboralTab() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('INFORMACIÓN INSTITUCIONAL'),
          const SizedBox(height: 14),
          _buildGradeDropdown(),
          const SizedBox(height: 14),
          _buildAutoSaveField(
            controller: _unitController,
            focusNode: _unitFocus,
            label: 'Unidad donde trabaja',
            icon: Icons.account_balance_rounded,
            hint: 'Ej. DEPINCRI Miraflores',
            suffixIcon: IconButton(
              icon: _isLocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5722)),
                    )
                  : const Icon(Icons.my_location_rounded, color: Color(0xFFFF5722), size: 20),
              onPressed: _isLocating ? null : _detectLocationAndShowSelector,
            ),
          ),
          const SizedBox(height: 14),
          _buildAutoSaveField(
            controller: _roleController,
            focusNode: _roleFocus,
            label: 'Cargo actual',
            icon: Icons.work_rounded,
            hint: 'EJ. ENCARGADO DE INVESTIGACIONES',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 14),
          _buildAutoSaveField(
            controller: _cityController,
            focusNode: _cityFocus,
            label: 'Ciudad actual',
            icon: Icons.location_city_rounded,
            hint: 'Ej. Lima',
            suffixIcon: IconButton(
              icon: _isLocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5722)),
                    )
                  : const Icon(Icons.my_location_rounded, color: Color(0xFFFF5722), size: 20),
              onPressed: _isLocating ? null : _detectLocationAndShowSelector,
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader('HERRAMIENTAS DE OPERADOR'),
          const SizedBox(height: 16),
          _buildToolCard(
            icon: Icons.folder_copy_rounded,
            color: theme.colorScheme.primary,
            title: 'Plantillas',
            subtitle: 'Gestionar actas y plantillas personales',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplatesPage())),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            icon: Icons.key_rounded,
            color: theme.colorScheme.tertiary,
            title: 'API Keys & Tokens',
            subtitle: 'Configurar Factiliza y Groq Cloud',
            onTap: () => ProfilePage.showLocalApiKeysDialog(context),
          ),
          const SizedBox(height: 32),
          _buildAcercaDeCard(),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.20), width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 10.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.25), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSaveField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.22),
              fontSize: 12.5,
            ),
            prefixIcon: Icon(icon, color: Colors.white30, size: 17),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDropdown() {
    final gradeOptions = [
      'Crnl. PNP', 'Cmdte. PNP', 'May. PNP', 'Cap. PNP', 'Tnte. PNP',
      'Alfz. PNP', 'SS. PNP', 'SB. PNP', 'ST1. PNP', 'ST2. PNP',
      'ST3. PNP', 'S1. PNP', 'S2. PNP', 'S3. PNP',
    ];

    final currentValue = _gradeController.text.trim();
    final items = List<String>.from(gradeOptions);
    if (currentValue.isNotEmpty && !items.contains(currentValue)) {
      items.insert(0, currentValue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grado',
          style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: currentValue.isEmpty ? null : currentValue,
          hint: Text(
            'Selecciona tu grado...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.22), fontSize: 12.5),
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontFamily: 'Inter'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.stars_rounded, color: Colors.white30, size: 17),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.white10, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
          ),
          items: items.map((grade) {
            return DropdownMenuItem<String>(
              value: grade,
              child: Text(grade),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _gradeController.text = val);
              _autoSave();
            }
          },
        ),
      ],
    );
  }

  Widget _buildAcercaDeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF5722)],
                ).createShader(b),
                child: const Text(
                  'ACTIUM',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.3), width: 0.8),
                ),
                child: const Text(
                  'PNP',
                  style: TextStyle(color: Color(0xFFFF7043), fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema de Gestión de Intervenciones Policiales\nPolicía Nacional del Perú',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontFamily: 'Inter',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white.withValues(alpha: 0.25), size: 14),
              const SizedBox(width: 6),
              Text(
                'Versión 1.0.0 · Uso oficial reservado',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30),
                  fontSize: 10,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
