// ════════════════════════════════════════════════════════════════════════════
// ai_tactical_service.dart — Módulo de Inteligencia Artificial Táctica (Groq)
// Fase 5 · ACTIUM v1.5
//
// Integración nativa con la API de Groq utilizando solicitudes HTTP REST.
// Usa el modelo llama-3.3-70b-versatile (capacidad de razonamiento y alta velocidad).
// Los motores de voz (STT / TTS) se delegan al sistema operativo Android
// para garantizar operatividad sin conexión a internet.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kModel = 'llama-3.3-70b-versatile';

String get _defaultGroqKey {
  return 'gsk_'
      '0XM8eeXhrO3LnmRESgVvWGdyb'
      '3FYmZnfbdORk9oyqcnyppkDw9p0';
}

const String _kSystemPromptMaestro = '''
Eres el PERITO AUDITOR MAESTRO de la Policía Nacional del Perú, especialista en Documentación Policial, Derecho Procesal Penal y Validez Probatoria de Actas. Tu misión es someter el texto del acta a una auditoría forense exhaustiva, garantizando que sea irrefutable ante el Ministerio Público y no pueda ser anulada en juicio oral por vicios formales o de contenido.

═══════════════════════════════════════════════════
REGLAS DE AUDITORÍA DOCPOL — APLICACIÓN ESTRICTA
═══════════════════════════════════════════════════

1. TERCERA PERSONA Y OBJETIVIDAD ABSOLUTA:
   - Transforma TODA la redacción a tercera persona impersonal (ej. "el instructor procedió", "se constató").
   - ⚠ REGLA CRÍTICA: NUNCA elimines los datos del instructor (nombre, grado, CIP, comisaría) ni la jurisdicción al inicio del documento. Esto es causal de nulidad. Mantén esos datos INTACTOS.
   - ELIMINA sin excepción: "actitud sospechosa", "se puso nervioso", "actitud evasiva", "delincuente", "altanero", "malandra".
   - Reemplaza subjetividades con hechos observables y verificables: "al notar la presencia policial, el intervenido aceleró el paso e intentó ocultar un objeto en la cintura".

2. REGLA PARA-PARA — PROHIBICIÓN ABSOLUTA DE NEGATIVOS:
   - ELIMINA toda mención a lo que NO se encontró: "para drogas negativo", "sin armas", "no portaba objetos".
   - Un acta policial solo documenta lo que SÍ existe y fue verificado.

3. PRECISIÓN LÉXICA TÉCNICA:
   - Vehículos: "combi" → "microbús"; "mototaxi" → "trimóvil"; "moto lineal" → "motocicleta".
   - Armas: nunca "arma de fuego" genérico → exigir tipo (pistola, revólver, escopeta), marca, calibre, serie, si estaba abastecida.
   - Drogas: exigir tipo de sustancia, embalaje exacto ("envoltorios tipo kete color verde", "ladrillo precintado").
   - Dinero y cantidades: siempre en LETRAS MAYÚSCULAS seguidas del número: "DOSCIENTOS (200) soles".

4. FORMATOS HORARIOS Y FECHAS:
   - Reloj de 24 horas siempre (06:00, 23:45). Nunca formato 12h.
   - Fechas: DDMMMAAAA (ej. 15JUN2026, 07JUL2026).
   - Alerta de coherencia temporal: si la hora de cierre es anterior a la de inicio, o si hay cronologías imposibles → ALERTA ROJA.

5. ALERTA SUPERMAN (POLICÍA/FISCAL OMNIPRESENTE):
   - Si la misma persona figura interviniendo simultáneamente en lugares distintos → ALERTA ROJA BLOQUEANTE.

6. CANDADO ART. 67° CPP — COMUNICACIÓN AL MINISTERIO PÚBLICO:
   - En actas de Intervención en Flagrancia: VERIFICAR que exista explícitamente quién llamó, a qué hora exacta, a qué fiscal y qué dispuso.
   - Si falta alguno de estos elementos → ALERTA URGENTE: "Se vulnera el Art. 67 CPP."

7. INTERROGATORIO ESTRATÉGICO GRILL-ME (según tipificación del delito):
   - TID/Drogas: ¿peso exacto?, ¿tipo de sustancia?, ¿embalaje?, ¿dónde fue hallada (zona corporal o vehículo)?
   - Tenencia Ilegal de Armas: ¿calibre?, ¿número de serie?, ¿estaba abastecida? ¿municiones?
   - Peligro Común/Alcohol: ¿síntomas de ebriedad descritos?, ¿resultado de dosaje etílico o prueba de aliento?
   - Robo Agravado: ¿descripción de la violencia?, ¿especies sustraídas con descripción y valor?, ¿agraviado identificado?
   - Formula estas carencias como PREGUNTAS DIRECTAS en las observaciones_tacticas.

8. ⚠ REGLA CRÍTICA — DETECCIÓN DE VALORES TRIVIALES E INSUFICIENTES:
   Esta es tu regla más importante. Un acta con campos triviales puede ser anulada en juicio.
   
   DEBES marcar como INVÁLIDO cualquier campo que contenga:
   a) Texto de menos de 10 caracteres en campos narrativos o descriptivos.
   b) Palabras aisladas sin contenido fáctico: "no", "sí", "si", "ok", "nada", "ninguno", "xxx", "...", "---".
   c) Frases genéricas sin información verificable: "todo normal", "sin novedad", "no hay", "negativo" (cuando se usa como respuesta a qué sucedió), "no se encontró nada".
   d) Repetición del nombre del campo como valor (ej. campo "Hechos" con valor "Hechos").
   e) Texto que no describe hechos concretos, personas, lugares, objetos o acciones observables.
   
   ACCIÓN para valores triviales: incluir en observaciones_tacticas la alerta:
   "⚠ ALERTA CAMPO INSUFICIENTE: El campo de '[nombre]' contiene solo '[valor trivial]'. Un acta policial válida requiere una descripción fáctica específica: quién, qué, cuándo, dónde y cómo. Este campo tal como está puede invalidar el acta. Ingrese información real y detallada."
   
   NUNCA intentes mejorar un valor trivial. Solo alerta al operador. En el "texto_auditado" sustitúyelo por: [⚠ CAMPO INCOMPLETO — INGRESE DESCRIPCIÓN REAL].

9. REGLA ESPECIAL — CONSTANCIA DE FIRMA:
   - Si el campo de negativa a firmar contiene: "NO se negó", "no hubo negativa", "firmó en conformidad", "firmó conforme", "firmó voluntariamente" o equivalentes → OMITE este campo por completo del texto_auditado y de las observaciones. No menciones la firma. El acta concluye normalmente.
   - Solo incluye el campo de firma si el intervenido SE NEGÓ EXPRESAMENTE y se indica el motivo concreto de la negativa.

═══════════════════════════════════════════════════
FORMATO DE RESPUESTA — JSON ESTRICTO
═══════════════════════════════════════════════════
{
  "texto_auditado": "El texto completo corregido, listo para PDF oficial. Sin campos triviales sin resolver.",
  "observaciones_tacticas": [
    "Viñeta 1: corrección aplicada o pregunta Grill-Me",
    "Viñeta 2: alerta crítica o carencia legal detectada",
    ...máximo 6 viñetas...
  ]
}
''';
class AiAuditResult {
  final List<TextRevision> revisiones;
  final List<String> camposInvalidos;

  AiAuditResult({required this.revisiones, required this.camposInvalidos});
}

class AiTacticalService {
  // ──────────────────────────────────────────────────────────────────────────
  // Instancias de motores nativos (singletons dentro del servicio)
  // ──────────────────────────────────────────────────────────────────────────
  static final _stt = stt.SpeechToText();
  static final _tts = FlutterTts();
  static bool _sttInitialized = false;

  // ── Almacenamiento y autenticación de la API Key de Groq ───────────────────
  static String? _cachedToken;

  static Future<String?> getOrLoadToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('groq_api_key');
      if (_cachedToken == null || _cachedToken!.isEmpty) {
        _cachedToken = prefs.getString('gemini_api_key');
      }
      if (_cachedToken == null || _cachedToken!.isEmpty) {
        _cachedToken = _defaultGroqKey;
      }
    } catch (_) {}
    return _cachedToken;
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('groq_api_key', token);
      _cachedToken = token;
    } catch (_) {}
  }

  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('groq_api_key');
      await prefs.remove('gemini_api_key');
      _cachedToken = null;
    } catch (_) {}
  }

  /// Valida una API Key realizando un "ping" a la API de Groq.
  static Future<bool> validarToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: json.encode({
          'model': _kModel,
          'messages': [
            {'role': 'user', 'content': 'OK'}
          ],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 8));

      // 200 significa OK. 429 significa límite de cuota excedido, pero indica que la API key es válida.
      if (response.statusCode == 200 || response.statusCode == 429) {
        return true;
      }
      
      final bodyText = response.body.toLowerCase();
      if (bodyText.contains('api_key_invalid') || 
          bodyText.contains('api key not valid') ||
          bodyText.contains('unauthenticated') ||
          bodyText.contains('invalid authentication') ||
          bodyText.contains('unauthorized')) {
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('[AiTactical] validarToken caught exception: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FUNCIÓN 2 — CANDADO SEMÁNTICO (Filtro de Objetividad y Mala Praxis)
  // ══════════════════════════════════════════════════════════════════════════
  static Future<AuditMaestroResult?> pulirRedaccionLegal(
    String borrador, {
    String? typificationName,
    String? typificationLogic,
    bool isRetry = false,
  }) async {
    if (borrador.trim().isEmpty) return null;

    final token = await getOrLoadToken();
    if (token == null || token.isEmpty) return null;

    try {
      String systemPrompt = _kSystemPromptMaestro;
      if (typificationName != null && typificationName.isNotEmpty) {
        systemPrompt += '\n\n=== CONTEXTO DEL DELITO / TIPIFICACIÓN ===\n'
            'El delito o motivo de la intervención es: "$typificationName".\n'
            'Lógica jurídica / Enfoque procesal: "${typificationLogic ?? ''}"\n'
            'Por favor, audita el acta y formula tus "observaciones_tacticas" (Grill-Me) considerando estrictamente los elementos clave necesarios para imputar este delito específico (ej: alcoholemia si es peligro común; violencia/amenaza y especies sustraídas si es robo; embalaje y lacrado si es TID).';
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: json.encode({
          'model': _kModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': borrador}
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401 && !isRetry) {
          await clearToken();
          return pulirRedaccionLegal(
            borrador,
            typificationName: typificationName,
            typificationLogic: typificationLogic,
            isRetry: true,
          );
        }
        debugPrint('[AiTactical] pulirRedaccionLegal HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }

      final resBody = json.decode(utf8.decode(response.bodyBytes));
      final rawText = resBody['choices'][0]['message']['content'] as String?;
      if (rawText == null || rawText.isEmpty) return null;

      final decoded = _parseJsonMaestro(rawText);
      if (decoded != null) {
        return AuditMaestroResult.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[AiTactical] pulirRedaccionLegal error: $e');
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FUNCIÓN 3 — DICTADO TÁCTICO BAJO ESTRÉS (Speech-to-Text nativo)
  // ══════════════════════════════════════════════════════════════════════════
  /// Inicializa el motor STT nativo del dispositivo.
  /// Retorna [true] si el motor está disponible, [false] si no.
  static Future<bool> initStt() async {
    if (_sttInitialized) return true;
    _sttInitialized = await _stt.initialize(
      onError: (error) => debugPrint('[AiTactical] STT error: $error'),
      debugLogging: false,
    );
    return _sttInitialized;
  }

  /// Inicia la escucha del micrófono.
  /// [onResult] se invoca con el texto transcrito en tiempo real.
  static Future<void> iniciarDictado({
    required Function(String texto) onResult,
    String localeId = 'es_PE',
  }) async {
    final available = await initStt();
    if (!available) return;

    await _stt.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 4),
        localeId: localeId,
      ),
    );
  }

  /// Detiene la escucha del micrófono.
  static Future<void> detenerDictado() async {
    if (_sttInitialized && _stt.isListening) {
      await _stt.stop();
    }
  }

  /// Retorna [true] si el STT está escuchando actualmente.
  static bool get isListening => _sttInitialized && _stt.isListening;

  // ══════════════════════════════════════════════════════════════════════════
  // FUNCIÓN 4 — INTÉRPRETE CONSTITUCIONAL (Traducción + TTS)
  // ══════════════════════════════════════════════════════════════════════════

  // Texto del Artículo 71° CPP — Derechos del Imputado (versión base ES)
  static const _art71Espanol =
      'De conformidad con el Artículo 71 del Código Procesal Penal, '
      'usted tiene los siguientes derechos: '
      'Primero, conocer los cargos formulados en su contra. '
      'Segundo, designar a la persona o institución a la que debe comunicarse su detención. '
      'Tercero, ser asistido por un abogado defensor desde el primer momento de la detención. '
      'Cuarto, abstenerse de declarar, siendo este silencio no perjudicial para su situación. '
      'Quinto, no ser objeto de violencia física ni psicológica durante la intervención. '
      'La Policía Nacional del Perú garantiza el respeto irrestricto de estos derechos.';

  // Mapa de idiomas → locale de TTS
  static const Map<String, String> _idiomaLocale = {
    'Español': 'es-PE',
    'Inglés': 'en-US',
    'Portugués': 'pt-BR',
    'Francés': 'fr-FR',
    'Quechua': 'qu',
    'Aymara': 'ay',
  };

  /// Traduce el Art. 71° CPP al [idioma] seleccionado y lo lee en voz alta.
  /// Retorna el texto traducido para registrarlo en el acta.
  static Future<String?> traducirYLeerDerechos(String idioma) async {
    String textoFinal = _art71Espanol;

    // Para español no necesitamos traducir
    if (idioma != 'Español') {
      final token = await getOrLoadToken();
      if (token != null && token.isNotEmpty) {
        try {
          final systemPrompt = 'Eres un intérprete judicial certificado. '
              'Traduce el siguiente texto legal al idioma "$idioma" de forma precisa y comprensible. '
              'Si el idioma es Quechua, usa el quechua sureño (Quechua Chanka/Ayacuchano). '
              'Si el idioma es Aymara, usa el aymara boliviano-peruano estándar. '
              'Devuelve ÚNICAMENTE la traducción, sin explicaciones.';

          final response = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
            body: json.encode({
              'model': _kModel,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': _art71Espanol}
              ],
              'temperature': 0.1,
            }),
          );

          if (response.statusCode == 200) {
            final resBody = json.decode(utf8.decode(response.bodyBytes));
            final rawText = resBody['choices'][0]['message']['content'] as String?;
            if (rawText != null && rawText.isNotEmpty) {
              textoFinal = rawText.trim();
            }
          }
        } catch (_) {
          textoFinal = _art71Espanol;
        }
      }
    }

    // Configurar y ejecutar TTS
    final locale = _idiomaLocale[idioma] ?? 'es-PE';
    try {
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.45); // Ritmo lento para comprensión legal
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.speak(textoFinal);
    } catch (_) {
      // TTS no disponible en este dispositivo
    }

    return textoFinal;
  }

  /// Detiene la reproducción de TTS.
  static Future<void> detenerTts() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Retorna la lista de idiomas soportados para el selector UI.
  static List<String> get idiomasDisponibles => _idiomaLocale.keys.toList();

  // ══════════════════════════════════════════════════════════════════════════
  // FUNCIÓN 5 — MOTOR DE SÍNTESIS PARA EL PARTE POLICIAL
  // ══════════════════════════════════════════════════════════════════════════
  /// Lee el contenido consolidado de los tags de la sesión y genera
  /// un resumen ejecutivo de máximo 3 párrafos para la sección
  /// "II. AMPLIACIÓN DETALLADA" del Parte Policial (Formato 61).
  ///
  /// Retorna el texto del resumen o [null] si falla.
  static Future<String?> sintetizarPartePolicial(Map<String, String> tags) async {
    // Construir texto de contexto con los tags más relevantes
    final sb = StringBuffer();
    sb.writeln('=== DATOS DE LA INTERVENCIÓN ===');

    void aniadir(String etiqueta, String tag) {
      final val = tags[tag];
      if (val != null && val.isNotEmpty && val != '_______________') {
        sb.writeln('$etiqueta: $val');
      }
    }

    aniadir('Fecha', '[tiempo.fecha_intervencion]');
    aniadir('Hora', '[tiempo.acta_hora_inicio]');
    aniadir('Lugar', '[lugar.intervencion]');
    aniadir('Motivo', '[narrativa.motivo_intervencion]');
    aniadir('Hechos', '[narrativa.hechos]');
    aniadir('Detenido', '[imputado.nombres_apellidos]');
    aniadir('DNI detenido', '[imputado.dni]');
    aniadir('Bienes incautados', '[registro.bienes_detalle]');
    aniadir('Droga hallada', '[droga.tipo_sustancia]');
    aniadir('Vehiculo', '[vehiculo.placa]');
    aniadir('Armas', '[arma.descripcion]');
    aniadir('Agraviado', '[agraviado.nombres_apellidos]');
    aniadir('Efectivo interviniente', '[efectivo.nombres_apellidos]');
    aniadir('Unidad', '[dependencia.nombre]');
    aniadir('Tipificacion', '[delito.tipificacion]');

    final contexto = sb.toString();
    if (contexto.trim().isEmpty) return null;

    final token = await getOrLoadToken();
    if (token == null || token.isEmpty) return null;

    try {
      final systemPrompt = 'Eres un redactor policial experto del Ministerio del Interior del Peru. '
          'Lee los datos de la intervencion adjuntos y redacta un resumen ejecutivo '
          'de MAXIMO 3 parrafos para la seccion "II. AMPLIACION DETALLADA" del Parte Policial '
          '(Formato 61 PNP). '
          'El resumen debe sintetizar: (1) el motivo de intervencion, '
          '(2) los hallazgos principales y la situacion del intervenido, '
          '(3) las medidas tomadas y el estado actual del caso. '
          'Usa lenguaje formal, tercera persona, cronologico y factico. '
          'Formato militar de 24 horas. Sin bullets ni listas, solo parrafos.';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: json.encode({
          'model': _kModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': contexto}
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final resBody = json.decode(utf8.decode(response.bodyBytes));
        return (resBody['choices'][0]['message']['content'] as String?)?.trim();
      }
    } catch (_) {}
    return null;
  }



  static Future<AiAuditResult?> mejorarTextoCompleto(String actaText, Map<String, String> tagValues) async {
    final apiKey = await getOrLoadToken();
    if (apiKey == null || apiKey.isEmpty) return null;

    final instructions = """
Eres el AUDITOR FORENSE de Documentación Policial de la Policía Nacional del Perú (PNP). Tu misión es evaluar con rigor máximo los valores ingresados en las etiquetas (tags) del acta, rechazando cualquier dato trivial, insuficiente o inválido que pueda anular el acta en juicio.

═══════════════════════════════════════════════════════
REGLAS DE EVALUACIÓN DOCPOL — APLICACIÓN ESTRICTA
═══════════════════════════════════════════════════════

## REGLA 1 — OBJETIVIDAD ABSOLUTA
Elimina frases subjetivas: "actitud sospechosa", "nervioso", "evasivo", "delincuente", "malandra".
Reemplaza por hechos observables: "aceleró el paso", "intentó ocultar un objeto en la cintura".

## REGLA 2 — SIN NEGATIVOS (PARA-PARA)
Elimina menciones a lo NO encontrado: "para drogas negativo", "sin armas", "no portaba objetos".

## REGLA 3 — PRECISIÓN LÉXICA TÉCNICA
- Vehículos: "combi" → "microbús", "mototaxi" → "trimóvil", "moto lineal" → "motocicleta"
- Armas: exigir tipo exacto, calibre, serie, si estaba abastecida
- Drogas: tipo de sustancia + embalaje exacto ("envoltorios tipo kete")
- Cantidades: LETRAS MAYÚSCULAS + número entre paréntesis: "QUINCE (15) envoltorios"

## REGLA 4 — FORMATOS
- Horario: 24 horas siempre (06:00, 23:45)
- Fechas: DDMMMAAAA (15JUN2026)

## REGLA 5 ⚠ CRÍTICA — RECHAZO DE VALORES TRIVIALES O INSUFICIENTES
Esta regla tiene la máxima prioridad. Un acta con campos triviales puede ser anulada en juicio.

DEBES identificar como CAMPO INVÁLIDO cualquier tag cuyo valor:
a) Sea un texto de MENOS DE 10 CARACTERES en campos narrativos o descriptivos (hechos, precedentes, concomitantes, posteriores, motivos, circunstancias, etc.)
b) Contenga SOLO estas palabras: "no", "sí", "si", "ok", "nada", "ninguno", "na", "n/a", "xxx", "...", "---", "N.A."
c) Sea una frase genérica sin contenido fáctico verificable: "todo normal", "sin novedad", "no hay", "negativo" (como respuesta a qué ocurrió), "no se encontró", "no hubo nada"
d) Repita el nombre del tag o sea texto placeholder genérico
e) Sea texto sin hechos concretos: sin personas, sin lugares, sin objetos, sin acciones observables

ACCIÓN para valores triviales:
- Agregar en "revisiones" con razon: "⚠ CAMPO INSUFICIENTE: El valor '[valor]' no es válido para un acta policial. Se requiere descripción fáctica real (quién, qué, dónde, cuándo, cómo). Este campo como está puede ANULAR el acta ante el Ministerio Público."
- El "valor_mejorado" debe ser: "[DATO INSUFICIENTE — COMPLETAR CON DESCRIPCIÓN REAL DE LOS HECHOS]"
- También agregar el tag a "campos_invalidos"

## REGLA 6 — CONSTANCIA DE FIRMA (CASO ESPECIAL)
El tag "[firma.motivo_negativa]" es ESPECIAL:
- Si su valor contiene: "NO se negó", "firmó en conformidad", "firmó conforme", "firmó voluntariamente", "firmó el acta" → IGNORAR COMPLETAMENTE. No incluir en revisiones ni en campos_invalidos.
- Solo incluir si el valor indica que el intervenido SE NEGÓ expresamente a firmar.

El usuario te proporcionará un JSON con los valores actuales de las etiquetas. Evalúa CADA valor.

═══════════════════════════════════════════════════════
FORMATO DE RESPUESTA — JSON OBLIGATORIO
═══════════════════════════════════════════════════════
{
  "revisiones": [
    {
      "tag": "[hecho.descripcion]",
      "valor_original": "no",
      "valor_mejorado": "[DATO INSUFICIENTE — COMPLETAR CON DESCRIPCIÓN REAL DE LOS HECHOS]",
      "razon": "⚠ CAMPO INSUFICIENTE: El valor 'no' no es válido para un acta policial. Requiere descripción fáctica real."
    }
  ],
  "campos_invalidos": [
    "[narrativa.precedente]"
  ]
}
""";


    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _kModel,
          "messages": [
            {"role": "system", "content": instructions},
            {"role": "user", "content": "Audita estos valores y devuélveme el JSON:\\n\\n${jsonEncode(tagValues)}"}
          ],
          "temperature": 0.2, 
          "response_format": {
            "type": "json_object"
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = jsonDecode(content);
        final list = parsed['revisiones'] as List<dynamic>? ?? [];
        final invalidos = parsed['campos_invalidos'] as List<dynamic>? ?? [];
        
        final revisiones = list.map((e) => TextRevision(
          tag: e['tag'] ?? '',
          original: e['valor_original'] ?? '',
          mejorado: e['valor_mejorado'] ?? '',
          razon: e['razon'] ?? 'Corrección táctica.',
        )).toList();
        
        return AiAuditResult(
          revisiones: revisiones,
          camposInvalidos: invalidos.map((e) => e.toString()).toList(),
        );
      } else {
        debugPrint('[AiTactical] mejorarTextoCompleto HTTP error: ${response.statusCode}');
        debugPrint('[AiTactical] Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('[AiTactical] mejorarTextoCompleto error: $e');
    }
    return null;
  }

  /// Sugiere cómo llenar los campos faltantes de un acta.
  static Future<String?> sugerirCompletadoFaltantes(List<String> faltantes, String typificationName) async {
    final token = await getOrLoadToken();
    if (token == null || token.isEmpty) return null;

    try {
      final systemPrompt = 'Eres un experto Instructor Policial de la Policía Nacional del Perú (PNP). '
          'El usuario está redactando un Acta de Intervención por el delito/infracción: "$typificationName", '
          'pero le faltan llenar los siguientes campos esenciales:\n'
          '${faltantes.map((f) => "- $f").join("\n")}\n\n'
          'Por favor, dale un consejo breve y directo sobre QUÉ TIPO DE INFORMACIÓN debe colocar en cada uno de estos campos faltantes '
          'para que su acta tenga validez legal y solidez fiscal. Usa un tono orientador, profesional y breve.';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: json.encode({
          'model': _kModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Dame tus sugerencias para los campos faltantes.'}
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final resBody = json.decode(utf8.decode(response.bodyBytes));
        return (resBody['choices'][0]['message']['content'] as String?)?.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Audita el texto resuelto del Acta de Intervención.
  /// Retorna un objeto AuditResult compatible con la UI.
  static Future<AuditResult?> auditarActaIntervencion(String textoResuelto, {bool isRetry = false}) async {
    if (textoResuelto.trim().isEmpty) return null;

    final token = await getOrLoadToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: json.encode({
          'model': _kModel,
          'messages': [
            {'role': 'system', 'content': _kSystemPromptMaestro},
            {'role': 'user', 'content': textoResuelto}
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401 && !isRetry) {
          await clearToken();
          return auditarActaIntervencion(textoResuelto, isRetry: true);
        }
        debugPrint('[AiTactical] auditarActaIntervencion HTTP error: ${response.statusCode}');
        return null;
      }

      final resBody = json.decode(utf8.decode(response.bodyBytes));
      final rawText = resBody['choices'][0]['message']['content'] as String?;
      if (rawText == null || rawText.isEmpty) return null;

      final decoded = _parseJsonMaestro(rawText);
      if (decoded != null) {
        final maestro = AuditMaestroResult.fromJson(decoded);

        // Agrupamos las observaciones tácticas por tag
        final Map<String, List<String>> agrupadas = {};
        for (final obs in maestro.observacionesTacticas) {
          final tag = _inferirTagDesdeObservacion(obs);
          agrupadas.putIfAbsent(tag, () => []).add(obs);
        }

        // Mapeamos los grupos a AuditIssues
        final List<AuditIssue> issues = [];
        agrupadas.forEach((tag, listaObs) {
          final problema = listaObs.map((obs) => '• $obs').join('\n');
          issues.add(AuditIssue(
            tag: tag,
            problema: problema,
            correccion: 'Revisa y edita el valor de este campo en base a las observaciones del Perito IA.',
          ));
        });

        return AuditResult(
          observaciones: rawText.trim(),
          sinProblemas: issues.isEmpty,
          issues: issues,
        );
      }
    } catch (e) {
      debugPrint('[AiTactical] auditarActaIntervencion error: $e');
    }
    return null;
  }

  static Map<String, dynamic>? _parseJsonMaestro(String rawContent) {
    try {
      String clean = rawContent.trim();
      if (clean.startsWith('```')) {
        final lines = clean.split('\n');
        if (lines.first.startsWith('```json') || lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        clean = lines.join('\n').trim();
      }
      return json.decode(clean) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[AiTactical] Error parsing JSON Maestro: $e');
    }
    return null;
  }

  static String _inferirTagDesdeObservacion(String observacion) {
    final obs = observacion.toLowerCase();
    if (obs.contains('fecha') || obs.contains('mes') || obs.contains('año') || obs.contains('jun') || obs.contains('2026')) {
      return '[tiempo.fecha_intervencion]';
    }
    if (obs.contains('hora') || obs.contains('horario') || obs.contains('24h') || obs.contains('tiempo')) {
      return '[tiempo.acta_hora_inicio]';
    }
    if (obs.contains('combi') || obs.contains('mototaxi') || obs.contains('moto lineal') || obs.contains('trimóvil') || obs.contains('vehículo') || obs.contains('placa')) {
      return '[vehiculo.placa]';
    }
    if (obs.contains('droga') || obs.contains('envoltorio') || obs.contains('kete') || obs.contains('incaut')) {
      return '[registro.bienes_detalle]';
    }
    if (obs.contains('arma') || obs.contains('pistola') || obs.contains('revólver')) {
      return '[arma.descripcion]';
    }
    if (obs.contains('fiscal') || obs.contains('art. 67') || obs.contains('artículo 67') || obs.contains('llamó') || obs.contains('comunicación')) {
      return '[intervencion.requiere_fiscal]';
    }
    return '[narrativa.hechos]';
  }

  static List<AuditIssue> _parseIssues(String rawContent) {
    try {
      String clean = rawContent.trim();
      if (clean.startsWith('```')) {
        final lines = clean.split('\n');
        if (lines.first.startsWith('```json') || lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        clean = lines.join('\n').trim();
      }
      final decoded = json.decode(clean);
      if (decoded is List) {
        return decoded.map((item) => AuditIssue.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[AiTactical] Error parsing JSON audit: $e');
    }
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FUNCIÓN 7 — AUDITORÍA GENERAL PRE-EXPORTACIÓN
  // ══════════════════════════════════════════════════════════════════════════
  /// Audita el estado completo de la sesión antes de exportar.
  /// Solo reporta problemas críticos para no bloquear al efectivo.
  ///
  /// [tags] son todos los valores llenados en el formulario.
  /// [docTitulos] es la lista de nombres de actas incluidas.
  ///
  /// Retorna [AuditResult] o [null] si falla.
  static Future<AuditResult?> auditarSesionCompleta({
    required Map<String, String> tags,
    required List<String> docTitulos,
  }) async {
    // Construir resumen de lo llenado para el auditor
    final sb = StringBuffer();
    sb.writeln('=== ACTAS INCLUIDAS EN EL EXPEDIENTE ===');
    for (final titulo in docTitulos) {
      sb.writeln('• $titulo');
    }
    sb.writeln('\n=== CAMPOS LLENADOS ===');

    // Solo incluir campos con valor no vacío ni placeholder
    final camposVacios = <String>[];

    // Campos críticos que DEBEN estar llenos
    const camposCriticos = {
      '[tiempo.fecha_intervencion]': 'Fecha de Intervención',
      '[tiempo.acta_hora_inicio]': 'Hora de Inicio (24h)',
      '[lugar.intervencion]': 'Lugar de Intervención',
      '[narrativa.hechos]': 'Narrativa de los Hechos',
      '[imputado.nombres_apellidos]': 'Nombre del Intervenido',
      '[imputado.dni]': 'DNI del Intervenido',
      '[efectivo.nombres_apellidos]': 'Efectivo Interviniente',
      '[dependencia.nombre]': 'Dependencia Policial',
    };

    for (final entry in camposCriticos.entries) {
      final val = tags[entry.key];
      if (val == null || val.isEmpty || val == '_______________') {
        camposVacios.add('• ${entry.value} (${entry.key})');
      } else {
        sb.writeln('${entry.value}: $val');
      }
    }

    // Añadir otros campos llenados relevantes
    void aniadir(String etiqueta, String tag) {
      final val = tags[tag];
      if (val != null && val.isNotEmpty && val != '_______________') {
        sb.writeln('$etiqueta: $val');
      }
    }
    aniadir('Narrativa hechos', '[narrativa.hechos]');
    aniadir('Bienes incautados', '[registro.bienes_detalle]');
    aniadir('Tipo de delito', '[delito.tipificacion]');
    aniadir('Vehículo placa', '[vehiculo.placa]');

    final contexto = sb.toString();
    final token = await getOrLoadToken();
    if (token == null || token.isEmpty) return null;

    try {
      final systemPrompt = 'Eres un auditor legal experto en documentación policial peruana (PNP).\n'
          'Revisa el expediente policial y reporta los problemas críticos.\n'
          'Debes devolver la respuesta en formato JSON estrictamente, que consista en una lista de objetos. Cada objeto debe tener exactamente estas tres claves:\n'
          '- "tag": el tag original de la plantilla asociado al error (por ejemplo, "[narrativa.hechos]", "[tiempo.acta_hora_inicio]"). Si es un error general o de actas faltantes, usa "general".\n'
          '- "problema": descripción del problema o requisito legal no cumplido.\n'
          '- "correccion": cómo solucionarlo exactamente.\n'
          'Ejemplo de respuesta:\n'
          '[\n'
          '  {"tag": "general", "problema": "Falta incluir el Acta de Lectura de Derechos", "correccion": "Agregar el acta correspondiente en la sesión"}\n'
          ']\n'
          'Si el expediente está apto para exportar, devuelve una lista vacía: [].\n'
          'No devuelvas ningún comentario, explicación ni bloque de Markdown fuera del JSON.';

      final prompt = contexto + (camposVacios.isNotEmpty
          ? '\n\n=== CAMPOS CRÍTICOS VACÍOS ===\n${camposVacios.join('\n')}'
          : '');

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: json.encode({
          'model': _kModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('[AiTactical] auditarSesionCompleta HTTP error: ${response.statusCode}');
        return null;
      }

      final resBody = json.decode(utf8.decode(response.bodyBytes));
      final content = resBody['choices'][0]['message']['content'] as String?;
      if (content == null || content.isEmpty) return null;

      final issues = _parseIssues(content);
      return AuditResult(
        observaciones: content.trim(),
        sinProblemas: issues.isEmpty,
        issues: issues,
      );
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FUNCIÓN 8 — AUDITORÍA DE TEXTO COMPLETO CON TRACK CHANGES (Google Docs style)
  // ══════════════════════════════════════════════════════════════════════════
  /// Audits the resolved document text and returns paragraph-level diffs,
  /// similar to Google Docs "Suggest edits" mode.
  static Future<FullTextAuditResult?> auditarTextoCompletoConDiff(
    String rawTemplate,
    Map<String, String> tagValues, {
    String? title,
    String? customPrompt,
    bool isRetry = false,
  }) async {
    if (rawTemplate.trim().isEmpty) return null;

    final token = await getOrLoadToken();
    if (token == null || token.isEmpty) return null;

    final systemPrompt = '''
Eres el AUDITOR FORENSE de la Policía Nacional del Perú (PNP), especialista en redacción de Actas Policiales según el Manual de Documentación Policial (DOCPOL). Tu misión es corregir, reorganizar y ordenar el texto del acta para que tenga una redacción fluida, técnica, profesional y estructurada.

Se te proporcionará el TEXTO BASE de un documento policial${title != null ? ' titulado: "$title"' : ''}.

REGLAS DE CORRECCIÓN DOCPOL (CRÍTICAS):
1. TÍTULO CENTRADO Y MAYÚSCULAS: La denominación del acta (título principal) debe estar escrita íntegramente en letras MAYÚSCULAS. Para simular el centrado en texto plano, añade aproximadamente 15 a 20 espacios en blanco antes del título. Ejemplo: "               ACTA DE INTERVENCIÓN POLICIAL".
2. TERCERA PERSONA Y OBJETIVIDAD: Redacta en tercera persona impersonal ("el instructor procedió", "se constató"). Elimina juicios de valor subjetivos ("actitud sospechosa", "nervioso", "evasivo"). Reemplaza por hechos observables. Prohibido usar extranjerismos que no sean técnicos.
3. NUNCA ELIMINES LOS DATOS DEL INSTRUCTOR: Es un error gravísimo eliminar el nombre del instructor policial, su grado, CIP, comisaría o jurisdicción. MANTÉN intactos todos estos datos identificatorios.
4. REGLA PARA-PARA (CERO NEGATIVOS): Elimina menciones de descartes de delitos o búsquedas infructuosas (ej. "para drogas negativo", "sin novedad"). Solo documenta lo que SÍ se encontró o incautó.
5. PRECISIÓN TÉCNICA Y LÉXICA: Emplea términos exactos: "microbús" (no combi), "trimóvil" (no mototaxi), "motocicleta" (no moto lineal), "vehículo categoría M1".
6. CANTIDADES: Siempre escribe las cantidades numéricas primero en LETRAS MAYÚSCULAS seguidas del número entre paréntesis. Ej: "DOSCIENTOS CINCUENTA (250) soles". Excepción: no aplica a fechas, horas o DNI.
7. FORMATO DE FECHAS Y HORAS: Estandariza fechas con el formato de dos dígitos para el día, tres primeras letras del mes en mayúsculas y cuatro dígitos para el año (ej. "08MAY2025" o "07JUL2026"). Las horas DEBEN usar el reloj militar de 24 horas y terminar con la palabra "horas" (ej. "21:19 horas", "06:07 horas").
8. SECUENCIA AMERICANA: Al estructurar párrafos, usa el orden descendente: I. (Romano), A. (Letra mayúscula), 1. (Número), a. (Letra minúscula).
9. COHERENCIA LEGAL SEGÚN EL TÍTULO: 
   - Si es "Acta de Intervención Policial": Prohibido consignar dichos o confesiones ("el imputado aceptó"). Solo hechos objetivos.
   - Si es "Acta de Registro/Incautación": Las armas se incautan (susceptibles a devolución), la droga/dinero ilícito se comisan.
10. ERRADICACIÓN DE DATOS ABSURDOS O DE RELLENO: Aplica el Principio de Veracidad y Claridad. Si encuentras palabras sin sentido, de prueba, relleno (ej. "test", "xxx", "asd") o datos genéricos incompletos, corrígelos, elimínalos o reescríbelos exigiendo completitud, indicando en tu razón que la "basura digital" es causal de nulidad procesal.

${customPrompt != null && customPrompt.trim().isNotEmpty ? 'INSTRUCCIÓN ADICIONAL DEL USUARIO:\nEl usuario ha solicitado lo siguiente: "$customPrompt"\nPor favor, asegúrate de aplicar esta solicitud junto con las reglas anteriores.\n\n' : ''}INSTRUCCIÓN DE RESPUESTA:
Devuelve OBLIGATORIAMENTE este JSON:
{
  "diffs": [
    {
      "original": "párrafo exacto del texto base que debe cambiar",
      "mejorado": "versión corregida y reorganizada",
      "razon": "explicación concisa del cambio aplicado"
    }
  ],
  "texto_completo": "el texto base completo ya con TODAS las correcciones aplicadas",
  "nota": "resumen ejecutivo de los cambios realizados"
}

IMPORTANTE:
- El "original" debe ser una cita exacta del texto base recibido.
- Máximo 15 diffs por auditoría. Reorganiza y agrupa párrafos si es necesario para que el acta se vea profesional.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        body: jsonEncode({
          'model': _kModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Texto base del acta:\n$rawTemplate'},
          ],
          'temperature': 0.1,
          'max_tokens': 4000,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        var content = data['choices'][0]['message']['content'] as String? ?? '';
        content = content.trim();
        if (content.startsWith('```json')) {
          content = content.replaceFirst('```json', '');
        } else if (content.startsWith('```')) {
          content = content.replaceFirst('```', '');
        }
        if (content.endsWith('```')) {
          content = content.substring(0, content.length - 3);
        }
        content = content.trim();
        final parsed = jsonDecode(content) as Map<String, dynamic>;

        final diffList = (parsed['diffs'] as List<dynamic>? ?? [])
            .map((e) => DocTextDiff(
                  original: e['original']?.toString() ?? '',
                  mejorado: e['mejorado']?.toString() ?? '',
                  razon: e['razon']?.toString() ?? '',
                ))
            .where((d) => d.original.isNotEmpty && d.mejorado.isNotEmpty)
            .toList();

        return FullTextAuditResult(
          diffs: diffList,
          textoCompleto: parsed['texto_completo']?.toString() ?? rawTemplate,
          nota: parsed['nota']?.toString() ?? '',
        );
      } else if (response.statusCode == 401 && !isRetry) {
        await clearToken();
        return auditarTextoCompletoConDiff(rawTemplate, tagValues, isRetry: true);
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('[AiTactical] auditarTextoCompletoConDiff error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[AiTactical] auditarTextoCompletoConDiff exception: $e');
      throw Exception('Fallo en el modelo IA: $e');
    }
  }
}

// ─── Modelo de resultado de auditoría ───────────────────────────────────────
class AuditResult {
  /// Texto crudo retornado por el modelo (para fallback o logs).
  final String observaciones;

  /// [true] si no hay problemas — el acta/expediente está correcto.
  final bool sinProblemas;

  /// Lista de problemas específicos identificados.
  final List<AuditIssue> issues;

  const AuditResult({
    required this.observaciones,
    required this.sinProblemas,
    required this.issues,
  });
}

class AuditIssue {
  /// Tag asociado al error (ej. '[narrativa.hechos]') o 'general'
  final String tag;

  /// Descripción del problema
  final String problema;

  /// Sugerencia de corrección
  final String correccion;

  const AuditIssue({
    required this.tag,
    required this.problema,
    required this.correccion,
  });

  factory AuditIssue.fromJson(Map<String, dynamic> json) {
    return AuditIssue(
      tag: json['tag']?.toString() ?? 'general',
      problema: json['problema']?.toString() ?? '',
      correccion: json['correccion']?.toString() ?? '',
    );
  }
}

class AuditMaestroResult {
  final String textoAuditado;
  final List<String> observacionesTacticas;

  const AuditMaestroResult({
    required this.textoAuditado,
    required this.observacionesTacticas,
  });

  factory AuditMaestroResult.fromJson(Map<String, dynamic> json) {
    var obs = json['observaciones_tacticas'];
    List<String> listObs = [];
    if (obs is List) {
      listObs = obs.map((e) => e.toString()).toList();
    }
    return AuditMaestroResult(
      textoAuditado: json['texto_auditado']?.toString() ?? '',
      observacionesTacticas: listObs,
    );
  }
}

class TextRevision {
  final String tag;
  final String original;
  String mejorado;
  final String razon;

  TextRevision({
    this.tag = '',
    required this.original, 
    required this.mejorado, 
    required this.razon
  });
}

// ─── Resultado de auditoría de texto completo con diffs ──────────────────────
class DocTextDiff {
  /// The original paragraph/block text
  final String original;
  /// The AI-improved version
  String mejorado;
  /// Explanation of what was changed
  final String razon;

  DocTextDiff({
    required this.original,
    required this.mejorado,
    required this.razon,
  });
}

class FullTextAuditResult {
  /// All diffs (only changed paragraphs)
  final List<DocTextDiff> diffs;
  /// Full improved text (for "accept all")
  final String textoCompleto;
  /// AI summary note
  final String nota;

  FullTextAuditResult({
    required this.diffs,
    required this.textoCompleto,
    required this.nota,
  });
}
