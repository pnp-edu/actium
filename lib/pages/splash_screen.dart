import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/intervention_provider.dart';
import 'main_menu_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _ambientController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  
  late Animation<double> _creatorFade;
  late Animation<double> _progressFade;

  // For drifting background glow spots
  late Animation<double> _driftX1;
  late Animation<double> _driftY1;
  late Animation<double> _driftX2;
  late Animation<double> _driftY2;

  double _loadingProgress = 0.0;
  String _loadingStatus = "Inicializando sistema...";

  @override
  void initState() {
    super.initState();
    
    // Entrance animations
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _creatorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Ambient background drift animation
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _driftX1 = Tween<double>(begin: -60, end: 80).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );
    _driftY1 = Tween<double>(begin: -80, end: 50).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _driftX2 = Tween<double>(begin: 70, end: -70).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );
    _driftY2 = Tween<double>(begin: 60, end: -90).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();
    _simulateLoading();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precarga de imágenes
    precacheImage(const AssetImage('assets/efectivo_mp.jpg'), context);
    precacheImage(const AssetImage('assets/efectivos_plamay.jpg'), context);
  }

  Future<void> _simulateLoading() async {
    // 1. Initial wait
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    
    // 2. Load provider sessions
    setState(() {
      _loadingProgress = 0.25;
      _loadingStatus = "Cargando sesiones guardadas...";
    });
    try {
      await context.read<InterventionProvider>().loadSavedSessions();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // 3. Connect/verify local DB configs
    setState(() {
      _loadingProgress = 0.60;
      _loadingStatus = "Estableciendo conexión local...";
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 4. Verification and pre-warming
    setState(() {
      _loadingProgress = 0.90;
      _loadingStatus = "Iniciando panel táctico...";
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _loadingProgress = 1.0;
      _loadingStatus = "Listo";
    });

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    // Navigate to Main Menu
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainMenuPage(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF070A0F), // Color negro obsidiana premium
      body: Stack(
        children: [
          // ── FONDO AMBIENTE ANIMADO ────────────────────────────────────────
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    left: _driftX1.value - 120,
                    top: _driftY1.value - 120,
                    child: _blurryCloud(const Color(0xFF5A0E1A), 480), // Carmesí profundo
                  ),
                  Positioned(
                    right: _driftX2.value - 120,
                    bottom: _driftY2.value - 120,
                    child: _blurryCloud(const Color(0xFF1E3A8A), 500), // Azul cobalto militar
                  ),
                  Positioned(
                    left: _driftX2.value * 0.5,
                    bottom: _driftY1.value * 0.5,
                    child: _blurryCloud(const Color(0xFF3F2D06), 400), // Dorado táctico tenue
                  ),
                ],
              );
            },
          ),

          // ── CONTENIDO PRINCIPAL CON EFECTOS DE CRISTAL ──────────────────────
          SafeArea(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // 1. Escudo / Logo Animado
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsar Glow Ring
                              Container(
                                width: 155,
                                height: 155,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // Glass Inner Container
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1.0,
                                  ),
                                ),
                                padding: const EdgeInsets.all(22),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.shield_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 70,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 2. Títulos y Textos
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Column(
                            children: [
                              // Nombre ACTIUM con gradiente
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF1E80F0), Color(0xFF9E7BFF)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds),
                                child: const Text(
                                  'ACTIUM',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 10,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Subtítulo elegante
                              const Text(
                                'SISTEMA DE GESTIÓN POLICIAL',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white60,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Línea separadora neon
                              Container(
                                width: 50,
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF9E7BFF)],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // 3. Barra de Progreso e Información de Carga
                      FadeTransition(
                        opacity: _progressFade,
                        child: Column(
                          children: [
                            Text(
                              _loadingStatus.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Custom Sleek Progress Track
                            Stack(
                              children: [
                                // Background bar
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Animated glowing progress fill
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 4,
                                  width: MediaQuery.of(context).size.width * 0.8 * _loadingProgress,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF1E80F0)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4. Créditos
                      FadeTransition(
                        opacity: _creatorFade,
                        child: const Text(
                          'DESARROLLADO POR B. IZQUIERDO LL.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white24,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurryCloud(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.75],
        ),
      ),
    );
  }
}
