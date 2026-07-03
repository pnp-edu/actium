import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/intervention_provider.dart';
import 'intervention_session_page.dart';
import '../widgets/custom_app_drawer.dart';

class ProcesoInmediatoPage extends StatelessWidget {
  const ProcesoInmediatoPage({super.key});

  void _seleccionarCarril(BuildContext context, String carril) {
    List<String> actasPlantilla = [];
    String typificationName = '';

    switch (carril) {
      case 'EBRIEDAD':
        typificationName = '1. CONDUCCIÓN EN ESTADO DE EBRIEDAD (D. Leg. 1194)';
        actasPlantilla = [
          'Acta de Intervención Policial',
          'Acta de Registro Vehicular',
          'Acta de Situación Vehicular',
          'Oficio Petitorio de Dosaje Etílico',
          'Acta de Detención y Lectura de Derechos'
        ];
        break;
      case 'FLAGRANCIA_ROBO':
        typificationName = '2. DELITO FLAGRANTE ESTRICTO (ROBO/HURTO)';
        actasPlantilla = [
          'Acta de Intervención Policial',
          'Acta de Registro Personal e Incautación',
          'Acta de Detención y Lectura de Derechos',
          'Acta de Manifestación (Formato 48)'
        ];
        break;
      case 'REQUISITORIA':
        typificationName = '3. CAPTURA POR REQUISITORIA';
        actasPlantilla = [
          'Acta de Intervención Policial',
          'Acta de Lectura de Derechos (Mandato Judicial)',
          'Parte Policial de Captura',
          'Hoja Básica de Requisitoria'
        ];
        break;
    }

    context.read<InterventionProvider>().startExpressSession(typificationName, actasPlantilla);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const InterventionSessionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A0E),
      drawer: const CustomAppDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── APP BAR PERSONALIZADO Y LIMPIO ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                      tooltip: 'Volver',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Builder(
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white70, size: 20),
                        tooltip: 'Ver menú',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── CONTENIDO PRINCIPAL COMPACTO SIN SCROLL ────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag de Emergencia / Proceso Inmediato
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded, color: Color(0xFFFF7043), size: 11),
                          SizedBox(width: 4),
                          Text(
                            'CARRIL EXPRESO · PLAZOS URGENTES',
                            style: TextStyle(
                              color: Color(0xFFFF7043),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Títulos Principales
                    const Text(
                      'PROCESO INMEDIATO',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Text(
                      'Decreto Legislativo N° 1194',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Carril 1: Ebriedad (Expanded para auto-ajustar altura)
                    Expanded(
                      child: _buildCarrilCard(
                        context: context,
                        titulo: 'CONDUCCIÓN EN ESTADO DE EBRIEDAD',
                        descripcion: 'Kits para dosaje etílico y retención vehicular.',
                        carril: 'EBRIEDAD',
                        icono: Icons.directions_car_rounded,
                        colorIcono: const Color(0xFF1E90FF),
                        guiaRapida: 'REGLA DE PLAZO: La toma de muestra para dosaje etílico debe realizarse dentro de las 4 horas de la intervención. Coordinar de inmediato la grúa para retención del vehículo.',
                        actas: [
                          'Acta Intervención',
                          'Registro Vehicular',
                          'Situación Vehicular',
                          'Dosaje Etílico',
                          'Lectura Derechos'
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Carril 2: Flagrancia Robo
                    Expanded(
                      child: _buildCarrilCard(
                        context: context,
                        titulo: 'DELITO FLAGRANTE (ROBO / HURTO)',
                        descripcion: 'Kits para registro personal y manifestación directa.',
                        carril: 'FLAGRANCIA_ROBO',
                        icono: Icons.lock_person_rounded,
                        colorIcono: const Color(0xFFFFD700),
                        guiaRapida: 'PLAZOS CONSTITUCIONALES: Detención preventiva de hasta 48 horas para diligencias fiscales urgentes. La comunicación al Fiscal penal de turno debe realizarse de inmediato.',
                        actas: [
                          'Acta Intervención',
                          'Registro Personal',
                          'Lectura Derechos',
                          'Manifestación'
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Carril 3: Requisitoria
                    Expanded(
                      child: _buildCarrilCard(
                        context: context,
                        titulo: 'CAPTURA POR REQUISITORIA',
                        descripcion: 'Formatos para mandatos judiciales y requisitoria.',
                        carril: 'REQUISITORIA',
                        icono: Icons.gavel_rounded,
                        colorIcono: const Color(0xFFE50914),
                        guiaRapida: 'PROTOCOLO RQ: Verificar de inmediato la vigencia de la requisitoria en ESINPOL. El intervenido debe ser puesto a disposición del juzgado solicitante en un plazo de 24 horas.',
                        actas: [
                          'Acta Intervención',
                          'Derechos Judiciales',
                          'Parte Captura',
                          'Ficha Requisitoria'
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
    );
  }

  Widget _buildCarrilCard({
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required String carril,
    required IconData icono,
    required Color colorIcono,
    required String guiaRapida,
    required List<String> actas,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12141C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _seleccionarCarril(context, carril),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorIcono.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icono, color: colorIcono, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            descripcion,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontFamily: 'Inter',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                  ],
                ),
                
                // Guía rápida para rellenar el espacio vacío en pantallas grandes
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.015),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colorIcono.withValues(alpha: 0.8), size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          guiaRapida,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 9.5,
                            height: 1.3,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: actas.map((acta) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.04),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      acta,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
