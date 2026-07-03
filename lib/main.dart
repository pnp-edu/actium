import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/intervention_provider.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InterventionProvider()),
      ],
      child: const ActiumApp(),
    ),
  );
}

class ActiumApp extends StatelessWidget {
  const ActiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Actium',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplashScreen(),
      // ── flutter_quill requires these localization delegates ──────────────
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'PE'), // Español Perú (primary)
        Locale('es'),
        Locale('en'),
      ],
    );
  }

  ThemeData _buildTheme() {
    const primaryBlue = Color(0xFF1E80F0);     // Celeste eléctrico principal
    const secondaryCyan = Color(0xFF00FFCC);   // Cian neón táctico
    const tertiaryGold = Color(0xFFFFD700);    // Dorado de rango/atención
    const bgObsidian = Color(0xFF04060A);      // Fondo ultra oscuro
    const bgCardSlate = Color(0xFF0E131F);     // Tarjetas pizarra táctico
    const bgSurfaceField = Color(0xFF171E2E);  // Campos de texto / divisiones
    const errorRed = Color(0xFFCF6679);        // Rojo de alerta / urgencia

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgObsidian,
      
      // Configuración de Esquema de Color unificado
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: secondaryCyan,
        onSecondary: bgObsidian,
        tertiary: tertiaryGold,
        onTertiary: bgObsidian,
        surface: bgCardSlate,
        onSurface: Colors.white,
        surfaceContainerHighest: bgSurfaceField,
        error: errorRed,
        onError: Colors.white,
      ),

      // Animaciones de transición unificadas
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CustomPageTransitionsBuilder(),
          TargetPlatform.iOS: CustomPageTransitionsBuilder(),
          TargetPlatform.windows: CustomPageTransitionsBuilder(),
          TargetPlatform.linux: CustomPageTransitionsBuilder(),
          TargetPlatform.macOS: CustomPageTransitionsBuilder(),
        },
      ),

      // Estilo del AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: bgObsidian,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // Estilo de Tarjetas
      cardTheme: CardThemeData(
        color: bgCardSlate,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF1F293D), width: 1), // Borde sutil táctico
        ),
      ),

      // Botones Elevados (Primarios)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),

      // Botones de Borde (Secundarios)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF1F293D), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Estilos de Inputs de Formularios
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurfaceField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F293D), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle: const TextStyle(color: Color(0xFF475569)),
      ),

      // Estilo de ListTiles
      listTileTheme: const ListTileThemeData(
        tileColor: bgCardSlate,
        textColor: Colors.white,
        iconColor: primaryBlue,
        selectedTileColor: bgSurfaceField,
      ),

      // Líneas Divisorias
      dividerTheme: const DividerThemeData(color: Color(0xFF1F293D), thickness: 1),

      // Barra de Navegación Inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgObsidian,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Color(0xFF475569),
        elevation: 8,
      ),

      // Botón Flotante (FAB)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}

class CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = Curves.easeInOutCubic;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: curve));
    
    final scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: curve));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: curve));

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      ),
    );
  }
}
