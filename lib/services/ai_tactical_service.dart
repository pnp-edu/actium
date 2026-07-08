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
      'X4u16pygO5MyD'
      'FCEzsiOWGdyb'
      '3FYuTUJtqNMM0Z1'
      'eIVacVkAApZF';
}

const String _kSystemPromptMaestro = '''
Eres un Perito Experto en Documentación Policial, Derecho Procesal Penal y Auditor de Actas de la Policía Nacional del Perú. Tu misión es auditar, corregir y perfeccionar el texto bruto ingresado por el efectivo policial en la escena del crimen, garantizando que el acta final sea irrefutable y no pueda ser anulada en un juicio oral.

Aplica ESTRICTAMENTE las siguientes reglas de doctrina operativa sobre el texto que recibas:

1. FILTRO DE OBJETIVIDAD Y ELIMINACIÓN DE SUBJETIVIDADES:
- Transforma toda la redacción a TERCERA PERSONA (ej. "el instructor procedió", no "procedimos" ni "procedí").
- Elimina terminantemente frases subjetivas o juicios de valor como "actitud sospechosa", "se puso nervioso", "mostró actitud evasiva", "delincuente" o "altanero".
- Reemplaza las subjetividades por la descripción física del hecho fáctico (ej. "se observó al sujeto acelerar el paso e intentar ocultar un objeto en su cintura al notar el patrullero").

2. REGLA DEL "PARA-PARA" (FORMATOS NEGATIVOS):
- Elimina cualquier mención a elementos que NO se encontraron. Está estrictamente prohibido usar frases como "para drogas negativo" o "para armas negativo". Solo documenta lo que efectivamente se halló e incautó.

3. PRECISIÓN LÉXICA Y TÉCNICA VEHICULAR/ARMAMENTO:
- Corrige términos coloquiales: Cambia "combi" por "microbús" o "minibús"; cambia "mototaxi" por "trimóvil"; cambia "moto lineal" por "motocicleta".
- Exige o sugiere precisión si el policía escribe genéricamente "arma de fuego" (debe especificar si es pistola, revólver, escopeta).
- Si mencionan drogas, asegura que se describa el tipo de embalaje ("envoltorios tipo kete", "pacos", "ladrillos precintados").

4. FORMATOS NUMÉRICOS, HORARIOS Y FECHAS:
- Todo sistema horario debe estar en formato de 24 horas. Si hay un solo dígito, antepón un cero (ej. "06:00 horas").
- Las fechas deben formatearse con dos dígitos para el día, tres letras mayúsculas para el mes y cuatro para el año (ej. 15JUN2026).
- Cantidades incautadas (dinero, droga, especies) deben expresarse OBLIGATORIAMENTE en LETRAS MAYÚSCULAS seguidas del número entre paréntesis. Ej: "QUINCE (15) envoltorios", "DOSCIENTOS (200) soles".

5. ALERTA DE CONTINUIDAD TEMPORAL Y SUPERMAN:
- Revisa las horas consignadas. Si detectas que la hora de finalización del acta es anterior a la hora de inicio, o si una misma persona figura realizando múltiples acciones simultáneas en distintos lugares (Fenómeno del "Policía Superman" o "Fiscal Superman"), emite una alerta roja bloqueante.

6. CANDADO DEL ARTÍCULO 67° CPP:
- Si el texto es de un Acta de Intervención en Flagrancia o Hallazgo, verifica que exista la mención expresa de la comunicación telefónica al Fiscal de Turno. Si el texto omite quién llamó, a qué hora, a qué fiscal y qué dispuso, agrega un aviso urgente indicando que se vulnera el Art. 67 del CPP.

7. INTERROGATORIO ESTRATÉGICO ("GRILL-ME" INTELIGENTE):
- A partir de la Tipificación / Delito que se indique en el contexto, DEBES auditar que el acta contenga TODOS los elementos jurídicos (verbos rectores) para imputar dicho delito.
- Si es "TID", es vital que exista el peso/cantidad, tipo de droga y embalaje. Si falta, haz una pregunta directa al efectivo policial.
- Si es "Tenencia de Armas", es vital que exista el calibre, serie, y si estaba abastecida. Si falta, pregúntalo.
- Si es "Peligro Común", es vital la descripción de los síntomas de ebriedad y la placa del vehículo.
- Si es "Robo Agravado", es vital describir el nivel de violencia/amenaza y las especies sustraídas.
- FORMULA ESTAS CARENCIAS COMO PREGUNTAS DIRECTAS (GRILL-ME) en tus observaciones tácticas (Ej. "Para imputar TID falta el peso exacto de la droga. ¿Cuál es el pesaje de los ketes hallados?").

FORMATO DE TU RESPUESTA:
Tu respuesta debe ser un objeto JSON estricto con dos claves:
1. "texto_auditado": El párrafo completamente corregido, técnico y listo para imprimirse en el PDF oficial.
2. "observaciones_tacticas": Una lista breve (máximo 4 viñetas) indicando qué corregiste, o PREGUNTAS ESTRATÉGICAS si faltan datos esenciales para configurar el delito (Grill-Me).
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
Eres el Auditor Experto de la Policía Nacional del Perú.
Tu misión es auditar LOS VALORES que el efectivo policial ha ingresado en las etiquetas (tags) de su acta, garantizando la máxima objetividad, lenguaje técnico y legalidad.

# REGLAS ESTRICTAS DE AUDITORÍA (DOCPOL):
1. **OBJETIVIDAD ABSOLUTA**: Elimina terminantemente frases subjetivas o juicios de valor. Prohibido usar "actitud sospechosa", "se puso nervioso", "delincuente". Reemplaza por la descripción fáctica: "mostró evasividad", "aceleró el paso".
2. **FORMATOS NUMÉRICOS Y HORARIOS**: Usa reloj de 24h (ej. 06:00 horas). Cantidades incautadas en letras mayúsculas seguidas de números entre paréntesis (ej. DOSCIENTOS (200)). Fechas en formato DDMMMAAAA (ej. 15JUN2026).
3. **PRECISIÓN LÉXICA**: Reemplaza coloquialismos (combi -> minibús, mototaxi -> trimóvil, moto lineal -> motocicleta).
4. **REGLA DEL PARA-PARA**: Elimina menciones a elementos no encontrados ("para drogas negativo"). Solo documenta lo que efectivamente se halló.
5. **IDENTIDAD Y SENTIDO**: Si el valor ingresado no tiene sentido (ej. "kjskjsj", "xxx"), identifícalo como campo inválido.

El usuario te proporcionará un JSON con los valores actuales de las etiquetas (`tagValues`). Evalúa **cada valor** de este JSON.

# TU TAREA:
Genera un JSON con 2 arreglos:
1. `revisiones`: Una lista de correcciones. Solo incluye los tags que NECESITAN ser modificados.
2. `campos_invalidos`: Una lista con los nombres exactos de los tags cuyos valores son completamente absurdos ("xxx", "123") y no pueden ser inferidos o corregidos.

# FORMATO DE RESPUESTA ESPERADO (JSON OBLIGATORIO):
{
  "revisiones": [
    {
      "tag": "[hecho.descripcion]",
      "valor_original": "se puso saltón al ver el patrullero",
      "valor_mejorado": "mostró evasividad y aceleró el paso al notar la presencia policial",
      "razon": "Se eliminó la subjetividad 'saltón' por lenguaje objetivo."
    }
  ],
  "campos_invalidos": [
    "[imputado.nombres]"
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
  static Future<AuditResult?> auditarActaIntervencion(String textoResuelto) async {
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
  final String mejorado;
  final String razon;

  TextRevision({
    this.tag = '',
    required this.original, 
    required this.mejorado, 
    required this.razon
  });
}
