import 'package:intl/intl.dart';
import '../providers/intervention_provider.dart';


const Map<String, List<String>> ubigeoPeru = {
  "SANTA": ["CHIMBOTE", "NUEVO CHIMBOTE", "COISHCO", "CASMA", "NEPEÑA", "SANTA"],
  "LIMA": ["LIMA CENTRO", "MIRAFLORES", "SAN ISIDRO", "SANTIAGO DE SURCO", "CERCADO DE LIMA"],
  "CALLAO": ["CALLAO", "BELLAVISTA", "CARMEN DE LA LEGUA", "LA PERLA", "LA PUNTA", "VENTANILLA", "MI PERÚ"],
  "AREQUIPA": ["AREQUIPA", "CAYMA", "CERRO COLORADO", "YANAHUARA"],
  "CUSCO": ["CUSCO", "WANCHAQ", "SAN SEBASTIAN", "SAN JERONIMO"],
  "TRUJILLO": ["TRUJILLO", "LA ESPERANZA", "EL PORVENIR", "VICTOR LARCO HERRERA", "HUANCHACO"]
};

class WizardStep {
  final String title;
  final String description;
  final String tag;
  final String? helpText;
  final List<String>? suggestions;
  final bool isConditional;
  final String? conditionKey;
  final bool conditionValue;
  final bool isDni;
  final bool isConditionSelector;
  /// If true, the widget will load the last 2 saved comisarías from SharedPreferences
  /// and append them to the suggestions list (deduplicating).
  final bool loadRecentComisarias;
  final bool disableVoiceInput;

  WizardStep({
    required this.title,
    required this.description,
    required this.tag,
    this.suggestions,
    this.isConditional = false,
    this.conditionKey,
    this.conditionValue = true,
    this.isDni = false,
    this.isConditionSelector = false,
    this.helpText,
    this.loadRecentComisarias = false,
    this.disableVoiceInput = false,
  });
}

  List<WizardStep> getWizardSteps(InterventionProvider provider) {
    final typificationId = provider.currentSession?.typificationId ?? '';
    final List<WizardStep> steps = [];

    // ─── BLOQUE 1: DATOS INICIALES (Siempre presentes) ───
    steps.addAll([
      WizardStep(
        title: "Fecha de la Intervención",
        description: "Día en que ocurrieron los hechos:",
        tag: "[tiempo.fecha_hecho]",
        suggestions: [
          DateFormat('ddMMMyyyy').format(DateTime.now()).toUpperCase(),
          DateFormat('ddMMMyyyy').format(DateTime.now().subtract(const Duration(days: 1))).toUpperCase(),
          DateFormat('ddMMMyyyy').format(DateTime.now().add(const Duration(days: 1))).toUpperCase(),
        ],
        helpText: "Selecciona una de las sugerencias rápidas para autocompletar la fecha actual o la de ayer.",
        disableVoiceInput: true,
      ),
      WizardStep(
        title: "¿Intervino con un acompañante?",
        description: "¿Participó otro efectivo policial con usted en la intervención?",
        tag: "COND_ACOMPANANTE",
        isConditionSelector: true,
        conditionKey: "ACOMPANANTE",
        helpText: "Seleccione SÍ si necesita registrar en el acta a un segundo efectivo policial interviniente.",
      ),
      WizardStep(
        title: "Grado del Acompañante",
        description: "Seleccione el grado del efectivo PNP:",
        tag: "[acompanante.grado]",
        isConditional: true, conditionKey: "ACOMPANANTE", conditionValue: true,
        suggestions: ["S1 PNP", "S2 PNP", "S3 PNP", "ST1 PNP", "ST2 PNP", "ST3 PNP"],
      ),
      WizardStep(
        title: "Apellidos y Nombres",
        description: "Ingrese los apellidos y nombres del acompañante:",
        tag: "[acompanante.apellidos_nombres]",
        isConditional: true, conditionKey: "ACOMPANANTE", conditionValue: true,
      ),
      WizardStep(
        title: "CIP del Acompañante",
        description: "Número de Carné de Identidad Policial:",
        tag: "[acompanante.cip]",
        isConditional: true, conditionKey: "ACOMPANANTE", conditionValue: true,
      ),
      
      WizardStep(
        title: "Lugar de Redacción",
        description: "Lugar donde se redacta este acta. Si se redacta en la escena misma, seleccione 'IN SITU'. Si se redacta en la comisaría, seleccione el nombre de su unidad.",
        tag: "[acta.lugar_redaccion]",
        suggestions: [
          "IN SITU",
          if (provider.operatorUnit.trim().isNotEmpty) provider.operatorUnit.trim(),
        ],
        helpText: "'IN SITU' significa que el acta se redacta en el mismo lugar donde ocurrieron los hechos. Si no es así, indique la comisaría donde se redacta.",
        loadRecentComisarias: true,
      ),
      WizardStep(
        title: "Provincia",
        description: "Provincia donde ocurrió la intervención:",
        tag: "[lugar.provincia]",
        suggestions: ubigeoPeru.keys.toList(),
      ),
      WizardStep(
        title: "Distrito / Ciudad",
        description: "Seleccione el distrito o ciudad (depende de la provincia anterior):",
        tag: "[lugar.distrito]",
        suggestions: ubigeoPeru[provider.getTagValue('[lugar.provincia]')] ?? [],
      ),
      WizardStep(
        title: "Dirección / Calle",
        description: "Ingrese la dirección exacta, nombre de la calle, jirón, avenida o referencia precisa donde ocurrió la intervención policial:",
        tag: "[lugar.calle]",
      ),
      WizardStep(
        title: "Hora de Inicio de los Hechos",
        description: "Hora exacta en que se suscitaron los hechos o inició la intervención policial (no la hora de redacción del acta):",
        tag: "[tiempo.acta_hora_inicio]",
        suggestions: [
          DateFormat('HH:mm').format(DateTime.now()),
          DateFormat('HH:mm').format(DateTime.now().subtract(const Duration(minutes: 5))),
          DateFormat('HH:mm').format(DateTime.now().add(const Duration(minutes: 5))),
        ],
        helpText: "Esta es la hora en que comenzaron los hechos, NO la hora en que redactas el acta. Puede ingresar la hora manualmente si no coincide con las sugerencias. Use formato de 24 horas (Ej: 14:30).",
        disableVoiceInput: true,
      ),
      WizardStep(
        title: "DNI del Intervenido",
        description: "Ingrese el DNI para consulta automática en la API de Factiliza. Si los datos se encuentran y no están vacíos, los siguientes pasos se omitirán automáticamente.",
        tag: "[imputado.dni]",
        isDni: true,
      ),
      WizardStep(
        title: "Nombres y Apellidos",
        description: "Nombres y apellidos completos del intervenido:",
        tag: "[imputado.nombres_apellidos]",
      ),
      WizardStep(
        title: "Edad",
        description: "Edad del intervenido (ej: 25):",
        tag: "[imputado.edad]",
      ),
      WizardStep(
        title: "Nacionalidad",
        description: "Nacionalidad del intervenido (ej: Peruana, Venezolana, Colombiana):",
        tag: "[imputado.nacionalidad]",
        suggestions: ["Peruana", "Venezolana", "Colombiana"],
      ),
      WizardStep(
        title: "Fecha y Lugar de Nacimiento",
        description: "Fecha y lugar de nacimiento del intervenido:",
        tag: "[imputado.fecha_nacimiento]",
      ),
      WizardStep(
        title: "Lugar de Nacimiento",
        description: "Lugar de nacimiento del intervenido:",
        tag: "[imputado.lugar_nacimiento]",
      ),
      WizardStep(
        title: "Padres",
        description: "Nombres de los padres del intervenido:",
        tag: "[imputado.padres]",
      ),
      WizardStep(
        title: "Estado Civil",
        description: "Estado civil del intervenido:",
        tag: "[imputado.estado_civil]",
        suggestions: ["Soltero(a)", "Casado(a)", "Conviviente", "Divorciado(a)", "Viudo(a)"],
      ),
      WizardStep(
        title: "Grado de Instrucción",
        description: "Grado de instrucción del intervenido:",
        tag: "[imputado.grado_instruccion]",
        suggestions: ["Secundaria Completa", "Secundaria Incompleta", "Superior", "Primaria"],
      ),
      WizardStep(
        title: "Profesión / Ocupación",
        description: "Ocupación o profesión del intervenido:",
        tag: "[imputado.ocupacion]",
        suggestions: ["Independiente", "Empleado", "Estudiante", "Sin ocupación conocida"],
      ),
      WizardStep(
        title: "Religión",
        description: "Religión del intervenido:",
        tag: "[imputado.religion]",
        suggestions: ["Católica", "Evangélica", "Ninguna"],
      ),
      WizardStep(
        title: "Domicilio",
        description: "Dirección domiciliaria del intervenido:",
        tag: "[imputado.domicilio]",
      ),
      WizardStep(
        title: "Teléfono",
        description: "Número de teléfono del intervenido:",
        tag: "[imputado.telefono]",
      ),
      WizardStep(
        title: "Correo Electrónico",
        description: "Correo electrónico del intervenido:",
        tag: "[imputado.correo]",
        suggestions: ["No precisa"],
      ),
    ]);

    
    
    // ─── BLOQUE 2: DATOS ESPECÍFICOS SEGÚN TIPIFICACIÓN ───
    if (typificationId == 'robo_agravado' || typificationId == 'hurto_agravado') {
      steps.addAll([
        WizardStep(
          title: "Armas y Amenaza",
          description: "¿El delincuente percutó el arma al aire, apuntó a una zona vital específica de la víctima o solo la mostró en la cintura?",
          tag: "[robo.armas_amenaza]",
          suggestions: ["Apuntó el arma directamente a la cabeza de la víctima", "Mostró la cacha del arma en la cintura", "No usó arma visible, empleó violencia física"],
        ),
        WizardStep(
          title: "Ruta y Medios de Escape",
          description: "¿Se utilizaron vehículos (motocicletas/autos) en la huida? Precise color, características particulares y placa.",
          tag: "[robo.escape]",
          suggestions: ["Huyó a bordo de una motocicleta color negro, sin espejos ni placa a la vista", "Huyó a la carrera ingresando a un pasaje aledaño"],
        ),
        WizardStep(
          title: "Recuperación del Bien",
          description: "¿El bien sustraído fue recuperado en posesión física directa (bolsillos), o fue arrojado al pavimento/maleza?",
          tag: "[robo.recuperacion]",
          suggestions: ["Recuperado del bolsillo delantero derecho del intervenido", "Arrojó el celular al pavimento durante la persecución"],
        ),
      ]);
    } else if (typificationId == 'tid_microcomercializacion') {
      steps.addAll([
        WizardStep(
          title: "Parafernalia de Droga",
          description: "¿Al momento del registro, el intervenido portaba instrumentos de dosificación (coladores, balanzas grameras, recortes)?",
          tag: "[droga.parafernalia]",
          suggestions: ["Se halló una balanza gramera digital y recortes de papel tipo revista", "No se halló parafernalia"],
        ),
        WizardStep(
          title: "Ocultamiento Exacto",
          description: "¿La droga estaba adherida al cuerpo, oculta en partes íntimas, o camuflada en un compartimento (caleta)?",
          tag: "[droga.ocultamiento]",
          suggestions: ["Adherida al cuerpo con cinta de embalaje transparente", "Oculta en las partes íntimas", "Camuflada al interior del filtro de aire del vehículo"],
        ),
        WizardStep(
          title: "Contexto del Lugar",
          description: "¿El lugar presenta características arquitectónicas de ser un punto de venta (puertas reforzadas, mirillas, cámaras)?",
          tag: "[droga.contexto_lugar]",
          suggestions: ["Inmueble con puerta de metal reforzada y mirilla (pasa-droga)", "Esquina descampada sin iluminación"],
        ),
      ]);
    } else if (typificationId == 'peligro_comun') {
      steps.addAll([
        WizardStep(
          title: "Placa del Vehículo",
          description: "¿Cuál es la placa única nacional de rodaje del vehículo intervenido?",
          tag: "[vehiculo.placa_unica_nacional_rodaje]",
          suggestions: ["F3E-291", "C2M-394"],
        ),
        WizardStep(
          title: "Síntomas Etílicos",
          description: "¿Qué síntomas de presunta ebriedad o consumo de drogas presentó el conductor al momento de la intervención?",
          tag: "[peligro.sintomas]",
          suggestions: ["Aliento alcohólico, dificultad para hablar y ojos rojos", "Incoordinación motora y estado de somnolencia"],
        ),
        WizardStep(
          title: "Evidencia en Cabina",
          description: "¿Se visualizaron botellas, latas o vasos con presunto licor (abiertos o cerrados) en el habitáculo del vehículo?",
          tag: "[peligro.evidencia_cabina]",
          suggestions: ["Se hallaron dos latas de cerveza abiertas en el portavasos", "No se observó licor en la cabina"],
        ),
        WizardStep(
          title: "Maniobra Evasiva",
          description: "¿El conductor intentó cambiar de asiento con el copiloto o saltar a la parte posterior al notar la circulina?",
          tag: "[peligro.maniobra_evasiva]",
          suggestions: ["Intentó pasarse al asiento del copiloto de forma rápida", "Frenó intempestivamente y apagó el vehículo"],
        ),
        WizardStep(
          title: "Capacidad Motriz",
          description: "Al solicitarle descender, ¿el intervenido necesitó apoyo para caminar o cayó al pavimento?",
          tag: "[peligro.capacidad_motriz]",
          suggestions: ["Descendió tambaleándose, necesitando apoyarse en la puerta del vehículo", "Cayó al pavimento al intentar dar el primer paso"],
        ),
      ]);
    } else if (typificationId == 'tenencia_armas') {
      steps.addAll([
        WizardStep(
          title: "Estado de Alerta del Arma",
          description: "¿El arma incautada tenía un cartucho en la recámara (lista para disparar) o el seguro desactivado?",
          tag: "[arma.alerta]",
          suggestions: ["Arma rastrillada con cartucho en recámara y seguro desactivado", "Arma con cacerina pero sin cartucho en recámara"],
        ),
        WizardStep(
          title: "Uso contra el Personal PNP",
          description: "¿Durante la persecución, el sujeto intentó desenfundar el arma de su cintura o apuntó hacia los efectivos?",
          tag: "[arma.uso_pnp]",
          suggestions: ["Llevó la mano a la cintura intentando desenfundar, siendo reducido rápidamente", "Apuntó el arma hacia el personal PNP sin llegar a percutar"],
        ),
        WizardStep(
          title: "Condición de la Serie",
          description: "¿El número de serie del arma se encontraba erradicado (limado/borrado) de forma intencional o era legible?",
          tag: "[arma.serie_condicion]",
          suggestions: ["Número de serie totalmente erradicado/limado de forma intencional", "Serie legible y visible a simple vista"],
        ),
      ]);
    } else if (typificationId == 'violencia_mujer_grupo_familiar') {
      steps.addAll([
        WizardStep(
          title: "Agravantes Especiales",
          description: "¿El hecho de violencia ocurrió en presencia directa de menores de edad (hijos/sobrinos)?",
          tag: "[violencia.agravantes_menores]",
          suggestions: ["El ataque ocurrió en presencia de dos menores hijos, quienes lloraban asustados", "No se encontraban menores en el lugar"],
        ),
        WizardStep(
          title: "Amenazas Continuas",
          description: "Durante la intervención policial, ¿el agresor continuó amenazando de muerte o insultando a la víctima? Precise la frase.",
          tag: "[violencia.amenazas_continuas]",
          suggestions: ["Agresor profirió en voz alta: 'Cuando salgan los policías te voy a matar'", "Guardó silencio al momento de la intervención"],
        ),
        WizardStep(
          title: "Uso de Objetos",
          description: "¿El agresor utilizó algún objeto contundente (ej. plancha, silla, correa) para perpetrar el ataque? ¿Dónde quedó?",
          tag: "[violencia.uso_objetos]",
          suggestions: ["Utilizó una correa de cuero, la cual quedó tendida en el piso de la sala", "Agresión fue netamente con puños y patadas"],
        ),
      ]);
    } else if (typificationId == 'captura_requisitoria') {
      steps.addAll([
        WizardStep(
          title: "Maniobra de Ocultamiento",
          description: "Al ser abordado para control de identidad, ¿proporcionó un DNI falso o el documento de un familiar?",
          tag: "[requisitoria.ocultamiento_identidad]",
          suggestions: ["Dictó de memoria un DNI que le correspondía a su hermano", "Entregó el DNI físico de un tercero con rasgos similares"],
        ),
        WizardStep(
          title: "Intento de Evasión",
          description: "¿El intervenido aceleró el paso o intentó darse a la fuga al percatarse que el efectivo policial consultaba ESINPOL?",
          tag: "[requisitoria.evasion]",
          suggestions: ["Al ver que el efectivo consultaba en el celular, intentó huir corriendo", "Mantuvo actitud nerviosa pero permaneció en el lugar"],
        ),
        WizardStep(
          title: "Vigencia Confirmada",
          description: "¿Se corroboró con la oficina de Requisitorias que la orden de captura se encuentra 'VIGENTE' y sin levantamiento?",
          tag: "[requisitoria.vigencia]",
          suggestions: ["Se verificó telefónicamente con la base DIVREQQ que la orden está vigente sin oficio de levantamiento"],
        ),
      ]);
    } else if (typificationId == 'homicidio_sicariato') {
      steps.addAll([
        WizardStep(
          title: "Cartografía de Indicios",
          description: "¿A qué distancia aproximada y dirección cardinal respecto al occiso se hallaron casquillos o el arma?",
          tag: "[homicidio.cartografia]",
          suggestions: ["Aprox. a 2 metros al norte de la cabeza se hallaron 03 casquillos percutidos"],
        ),
        WizardStep(
          title: "Rumbo de Fuga",
          description: "¿Los testigos manifestaron el rumbo de fuga y el tipo de vehículo utilizado por los sicarios?",
          tag: "[homicidio.fuga]",
          suggestions: ["Testigos refieren que huyeron rumbo al sur a bordo de una moto lineal negra tipo Pulsar"],
        ),
        WizardStep(
          title: "Registro Ciudadano",
          description: "¿Se identificó in situ a transeúntes que hayan grabado el ataque con sus celulares antes del acordonamiento?",
          tag: "[homicidio.registro_ciudadano]",
          suggestions: ["Se identificó a un transeúnte que grabó los instantes posteriores, tomando sus datos", "No hubo registro ciudadano detectado"],
        ),
      ]);
    } else if (typificationId == 'receptacion') {
      steps.addAll([
        WizardStep(
          title: "Manifestación Espontánea",
          description: "¿Cuál fue la excusa exacta y literal que dio el intervenido sobre cómo obtuvo el equipo robado?",
          tag: "[receptacion.manifestacion]",
          suggestions: ["Refirió espontáneamente: 'Lo compré en la cachina a 50 soles porque estaba barato'"],
        ),
        WizardStep(
          title: "Alteración Física",
          description: "¿El equipo celular presentaba evidencias de manipulación técnica (bandeja SIM cambiada, carcasa abierta)?",
          tag: "[receptacion.alteracion_fisica]",
          suggestions: ["Presentaba la bandeja de SIM Card de otro color y signos de haber sido destapado a la fuerza"],
        ),
        WizardStep(
          title: "Verificación IMEI (Lógico vs Físico)",
          description: "¿Al marcar *#06#, el IMEI físico de la carcasa coincide con el IMEI lógico de la pantalla?",
          tag: "[receptacion.imei_logico_fisico]",
          suggestions: ["El IMEI lógico de la pantalla (*#06#) difiere totalmente del IMEI impreso en la carcasa trasera"],
        ),
      ]);
    } else if (typificationId == 'extorsion') {
      steps.addAll([
        WizardStep(
          title: "Evidencia Concomitante",
          description: "Al registro personal, ¿portaba manuscritos (cartas extorsivas), stickers criminales o municiones sueltas?",
          tag: "[extorsion.evidencia_concomitante]",
          suggestions: ["Se halló una hoja bond con mensajes amenazantes escritos a mano y dos municiones calibre 38"],
        ),
        WizardStep(
          title: "Comprobación del Celular In Situ",
          description: "En caso de flagrancia, ¿el celular sonó o recibió mensajes coordinando el pago en ese instante?",
          tag: "[extorsion.comprobacion_celular]",
          suggestions: ["El celular incautado recibió llamadas en el acto exigiendo a la víctima 'dónde está el sobre'"],
        ),
        WizardStep(
          title: "Modalidad Virtual / Cuentas",
          description: "Si fue extorsión virtual, ¿se evidenció un número de cuenta bancaria o Yape/Plin proporcionado?",
          tag: "[extorsion.modalidad_virtual]",
          suggestions: ["Se halló en los chats de WhatsApp un número de Yape al que exigían depositar los cupos"],
        ),
      ]);
    } else if (typificationId == 'lesiones') {
      steps.addAll([
        WizardStep(
          title: "Evidencia en Vestimenta",
          description: "¿La vestimenta o manos del presunto agresor presentaban máculas rojizas compatibles con el ataque?",
          tag: "[lesiones.evidencia_vestimenta]",
          suggestions: ["Las manos y el polo blanco del intervenido presentaban abundantes máculas rojizas (sangre)"],
        ),
        WizardStep(
          title: "Estado de Urgencia y Auxilio",
          description: "¿La víctima requirió traslado inmediato en el patrullero debido a hemorragia, o esperó ambulancia?",
          tag: "[lesiones.urgencia_auxilio]",
          suggestions: ["Debido a la gravedad de la hemorragia, fue trasladado de inmediato a urgencias en la unidad policial"],
        ),
        WizardStep(
          title: "Arma de Ocasión",
          description: "¿El agresor rompió un objeto en el lugar (botella de vidrio) para usarlo como arma blanca?",
          tag: "[lesiones.arma_ocasion]",
          suggestions: ["Rompió una botella de cerveza contra el piso y utilizó el pico como arma punzocortante"],
        ),
      ]);
    } else if (typificationId == 'delitos_libertad_sexual') {
      steps.addAll([
        WizardStep(
          title: "Evidencia Biológica en Escena",
          description: "En ambientes cerrados, ¿se visualizaron preservativos, lubricantes o prendas rasgadas esparcidas?",
          tag: "[sexual.evidencia_biologica]",
          suggestions: ["Se observaron preservativos usados en el suelo y ropa interior rasgada sobre la cama"],
        ),
        WizardStep(
          title: "Marcas de Defensa en Agresor",
          description: "¿El presunto agresor presenta arañazos recientes, mordeduras o marcas de defensa causados por la víctima?",
          tag: "[sexual.marcas_defensa]",
          suggestions: ["El intervenido presentaba arañazos recientes (estigmas ungueales) en cuello y rostro"],
        ),
        WizardStep(
          title: "Estado de Vulnerabilidad",
          description: "¿La víctima se encontraba bajo efectos evidentes de sustancias, alcohol o inconsciente a la llegada policial?",
          tag: "[sexual.estado_vulnerabilidad]",
          suggestions: ["La víctima se encontraba en estado de semi-inconsciencia, presuntamente sedada o ebria"],
        ),
      ]);
    } else if (typificationId == 'contrabando_receptacion_aduanera') {
      steps.addAll([
        WizardStep(
          title: "Modalidad de Ocultamiento",
          description: "¿La mercadería estaba oculta en caletas estructurales (doble fondo, llantas de repuesto, tanques)?",
          tag: "[contrabando.ocultamiento_estructural]",
          suggestions: ["Mercadería camuflada en un falso fondo soldado en la plataforma del camión frigorífico"],
        ),
        WizardStep(
          title: "Vulneración de Seguridad",
          description: "¿Los precintos de seguridad (sellos aduaneros) del contenedor estaban adulterados, rotos o clonados?",
          tag: "[contrabando.vulneracion_seguridad]",
          suggestions: ["Los sellos aduaneros de la puerta del furgón habían sido fracturados y reemplazados artesanalmente"],
        ),
        WizardStep(
          title: "Documentación Fraudulenta",
          description: "¿El conductor presentó guías de remisión que claramente no coincidían con el peso/naturaleza de la carga?",
          tag: "[contrabando.documentacion_fraudulenta]",
          suggestions: ["Presentó guía por sacos de arroz, hallándose cajas de licores extranjeros en el interior"],
        ),
      ]);
    } else if (typificationId == 'falsificacion_moneda') {
      steps.addAll([
        WizardStep(
          title: "Modus Operandi en Flagrancia",
          description: "¿El intervenido intentaba comprar un producto de muy bajo costo con un billete de alta denominación?",
          tag: "[moneda.modus_operandi]",
          suggestions: ["Intentaba comprar una caja de fósforos pagando con un billete falso de S/ 100 para obtener el vuelto"],
        ),
        WizardStep(
          title: "Series Repetidas",
          description: "Al revisar el fajo incautado, ¿varios billetes compartían exactamente el mismo número de serie?",
          tag: "[moneda.series_repetidas]",
          suggestions: ["Se corroboró que 5 billetes de S/ 50 compartían idéntico número de serie B548239C"],
        ),
        WizardStep(
          title: "Ocultamiento o Destrucción",
          description: "¿Al notar a la policía, el sujeto intentó romper, masticar o arrojar al suelo los billetes falsificados?",
          tag: "[moneda.ocultamiento_destruccion]",
          suggestions: ["Intentó triturar con las manos y arrojar a una alcantarilla los billetes falsos"],
        ),
      ]);
    } else if (typificationId == 'usurpacion_agravada') {
      steps.addAll([
        WizardStep(
          title: "Destrucción de Linderos",
          description: "¿Los invasores destruyeron los cercos perimétricos, chapas o instalaron candados nuevos?",
          tag: "[usurpacion.destruccion_linderos]",
          suggestions: ["Fracturaron el candado original colocando una cadena nueva con candado propio para impedir el paso"],
        ),
        WizardStep(
          title: "Roles y Cabecillas",
          description: "¿Se identificó en flagrancia a alguien dando órdenes, cobrando por lotes o dirigiendo la ocupación?",
          tag: "[usurpacion.roles_cabecillas]",
          suggestions: ["Se identificó a un individuo provisto de megáfono asignando áreas y dirigiendo a la turba"],
        ),
        WizardStep(
          title: "Armamento y Herramientas Pesadas",
          description: "¿Los usurpadores portaban armas de fuego, machetes, explosivos caseros o maquinaria pesada?",
          tag: "[usurpacion.armamento_maquinaria]",
          suggestions: ["El grupo portaba machetes, palos con clavos y bombas molotov caseras (botellas con combustible)"],
        ),
      ]);
    } else if (typificationId == 'secuestro') {
      steps.addAll([
        WizardStep(
          title: "Mecanismos de Sujeción",
          description: "¿Con qué material exacto estaba atada, engrilletada o amordazada la víctima al irrumpir la PNP?",
          tag: "[secuestro.sujecion]",
          suggestions: ["Se encontraba de manos atadas con cinta de embalaje industrial plateada y retazos de tela en la boca"],
        ),
        WizardStep(
          title: "Logística del Cautiverio",
          description: "¿La guarida contaba con colchones tirados, baldes o comida, evidenciando un cautiverio prolongado?",
          tag: "[secuestro.logistica_cautiverio]",
          suggestions: ["Habitación con un colchón de espuma viejo en el suelo, recipientes para orinar y restos de comida rápida"],
        ),
        WizardStep(
          title: "Custodia Armada",
          description: "¿Los captores intervenidos realizaban rondas de vigilancia armada exteriores o estaban con la víctima?",
          tag: "[secuestro.custodia_armada]",
          suggestions: ["Un sujeto se encontraba con arma de fuego en el pasadizo exterior vigilando la entrada"],
        ),
      ]);
    } else if (typificationId == 'falsedad_generica') {
      steps.addAll([
        WizardStep(
          title: "Detección Táctil / Visual In Situ",
          description: "Al tacto, ¿el documento carecía de hologramas, microimpresión, o presentaba foto plastificada casera?",
          tag: "[falsedad.deteccion_insitu]",
          suggestions: ["El material del DNI era similar a un papel plastificado casero, sin hologramas detectables al tacto"],
        ),
        WizardStep(
          title: "Uso Previo en Documentos",
          description: "¿Firmó actas policiales previas, papeletas o se identificó con la identidad falsa antes de descubrir el fraude?",
          tag: "[falsedad.uso_previo]",
          suggestions: ["Llegó a firmar el Acta de Intervención inicial con la firma e identidad del documento falso"],
        ),
        WizardStep(
          title: "Confesión Espontánea",
          description: "Al verse descubierto por el sistema AFIS/RENIEC, ¿manifestó espontáneamente su verdadera identidad?",
          tag: "[falsedad.confesion_espontanea]",
          suggestions: ["Al informarle que pasaríamos biometría AFIS, confesó su nombre real alegando tener requisitoria"],
        ),
      ]);
    } else if (typificationId == 'delitos_ambientales') {
      steps.addAll([
        WizardStep(
          title: "Daño Ecológico Inminente",
          description: "¿Se constató visualmente el vertimiento de combustibles, aceites o químicos hacia el cauce del río o suelo?",
          tag: "[ambiental.dano_ecologico]",
          suggestions: ["Se apreció mangueras vertiendo relaves químicos con coloración oscura directamente a las aguas del río"],
        ),
        WizardStep(
          title: "Actividad Concomitante (En Marcha)",
          description: "Al intervenir, ¿las motobombas, dragas, chupaderas o motosierras se encontraban operando activamente?",
          tag: "[ambiental.actividad_concomitante]",
          suggestions: ["Las tres motobombas (chupaderas) se encontraban encendidas succionando material del lecho del río"],
        ),
        WizardStep(
          title: "Cuantificación In Situ",
          description: "¿Qué cantidad aproximada de mineral aurífero (sacos) o trozas de madera estaban listas para el transporte?",
          tag: "[ambiental.cuantificacion]",
          suggestions: ["Se contabilizaron 50 sacos de polietileno repletos de presunto mineral aurífero junto al camión"],
        ),
      ]);
    } else if (typificationId == 'cohecho_activo') {
      steps.addAll([
        WizardStep(
          title: "Modo de Entrega de Dádiva",
          description: "¿El dinero fue entregado en mano, dejado en el tablero o camuflado entre el DNI/Brevete?",
          tag: "[cohecho.modo_entrega]",
          suggestions: ["Dejó sigilosamente un billete de 20 soles doblado al interior del Soat al entregarlo al policía"],
        ),
        WizardStep(
          title: "Intimidación o Registro Ciudadano",
          description: "¿El conductor intervenido grababa la intervención de forma oculta al momento de ofrecer/exigir arreglo?",
          tag: "[cohecho.intimidacion]",
          suggestions: ["Mantenía su celular grabando oculto bajo el muslo mientras insinuaba el soborno monetario"],
        ),
        WizardStep(
          title: "Respuesta y Advertencia Policial",
          description: "¿Cuál fue la advertencia legal exacta que le dio el efectivo antes de proceder a la detención?",
          tag: "[cohecho.respuesta_policial]",
          suggestions: ["Se le advirtió textualmente que su acción constituye delito de Corrupción de Funcionarios, procediendo a detenerlo"],
        ),
      ]);
    } else if (typificationId == 'resistencia_autoridad') {
      steps.addAll([
        WizardStep(
          title: "Agotamiento de Verbalización",
          description: "¿Cuántas veces y mediante qué medio se impartió la orden legal antes de que atacara o huyera?",
          tag: "[resistencia.verbalizacion]",
          suggestions: ["Se verbalizó a viva voz en tres ocasiones ordenando que deponga su actitud violenta, sin acatar"],
        ),
        WizardStep(
          title: "Incitación a la Turba",
          description: "¿El intervenido incitó a terceras personas (familiares, transeúntes) para que agredan a la policía?",
          tag: "[resistencia.incitacion_turba]",
          suggestions: ["Gritaba a sus familiares vecinos instigando a que arrojen piedras al patrullero para evitar la captura"],
        ),
        WizardStep(
          title: "Daños Materiales / Personales PNP",
          description: "¿Producto de la resistencia, se causó rotura de uniformes, daños al equipamiento PNP o abolladuras?",
          tag: "[resistencia.danos_pnp]",
          suggestions: ["Logró arrancar y destruir la radio portátil Tetra del efectivo policial arrojándola al piso"],
        ),
      ]);
    } else if (typificationId == 'hallazgo_vehiculo') {
      steps.addAll([
        WizardStep(
          title: "Violencia en Ignición (Chapa)",
          description: "¿La chapa de contacto estaba violentada, puenteada o adaptada con un objeto extraño ('peine')?",
          tag: "[hallazgo.violencia_ignicion]",
          suggestions: ["La chapa de encendido se encontraba destruida ('reventada') y con un peine de metal tipo T incrustado"],
        ),
        WizardStep(
          title: "Desmantelamiento Estructural",
          description: "¿El vehículo estaba montado sobre tacos sin llantas, o le faltaba el motor y ECU?",
          tag: "[hallazgo.desmantelamiento]",
          suggestions: ["El vehículo descansaba sobre ladrillos pesados, sin sus cuatro neumáticos y carente de computadora (ECU)"],
        ),
        WizardStep(
          title: "Indicios de Otros Delitos",
          description: "¿Se visualizó al interior del vehículo pasamontañas, sangre, o placas clonadas en papel?",
          tag: "[hallazgo.indicios_delitos]",
          suggestions: ["A través de la luna se visualizó un pasamontañas negro y manchas de presunta sangre en el asiento trasero"],
        ),
      ]);
    } else if (typificationId == 'trata_personas') {
      steps.addAll([
        WizardStep(
          title: "Circunstancias de la Víctima",
          description: "¿En qué circunstancias exactas se encontró a las presuntas víctimas (estaban encerradas, realizando trabajo forzoso)?",
          tag: "[trata.circunstancias]",
          suggestions: ["Se encontraban encerradas bajo llave en un cuarto precario", "Estaban siendo forzadas a realizar trabajo sin remuneración"],
        ),
        WizardStep(
          title: "Actitud del Tratante",
          description: "¿El intervenido (tratante) intentó evitar el ingreso del personal policial o coaccionar a las víctimas?",
          tag: "[trata.actitud]",
          suggestions: ["Intentó bloquear la puerta y amenazó a las víctimas para que guarden silencio", "No opuso resistencia pero intentó ocultarse"],
        ),
        WizardStep(
          title: "Elementos Vinculados",
          description: "¿Qué elementos vinculados a la explotación (libretas, pasaportes retenidos, dinero) se hallaron en poder del intervenido?",
          tag: "[trata.elementos]",
          suggestions: ["Se hallaron libretas de control de cobros y 3 pasaportes retenidos", "Se incautó una suma fuerte de dinero en efectivo"],
        ),
      ]);
    } else if (typificationId == 'marcaje_reglaje') {
      steps.addAll([
        WizardStep(
          title: "Acciones de Reglaje",
          description: "¿Qué acciones específicas realizaban los intervenidos que denoten seguimiento o reglaje a la posible víctima?",
          tag: "[reglaje.acciones]",
          suggestions: ["Realizaban observación sostenida desde un vehículo hacia la agencia bancaria", "Tomaban fotografías a la víctima sin su consentimiento"],
        ),
        WizardStep(
          title: "Elementos Incautados",
          description: "¿Se incautaron planos, croquis, fotografías, equipos de comunicación u otros elementos utilizados para el reglaje?",
          tag: "[reglaje.elementos]",
          suggestions: ["Se halló un croquis hecho a mano del perímetro del banco y 2 radios portátiles", "Se incautaron teléfonos celulares con fotografías de la vivienda de la víctima"],
        ),
        WizardStep(
          title: "Características del Vehículo",
          description: "¿El vehículo utilizado por los intervenidos tenía características para evadir identificación (placas adulteradas, lunas polarizadas)?",
          tag: "[reglaje.vehiculo]",
          suggestions: ["Vehículo con lunas totalmente oscurecidas y placa de rodaje cubierta con barro", "Motocicleta sin placas a la vista"],
        ),
      ]);
    } else if (typificationId == 'estafa') {
      steps.addAll([
        WizardStep(
          title: "Modus Operandi",
          description: "¿Cuál fue el modus operandi o el 'cuento' utilizado por el estafador (ej. balurdo, lotería, cascada)?",
          tag: "[estafa.modus]",
          suggestions: ["Utilizaron la modalidad de la 'Lotería', ofreciendo compartir el premio a cambio de efectivo", "Usaron el cuento de las 'Pepitas de Oro'"],
        ),
        WizardStep(
          title: "Objetos Fraudulentos",
          description: "¿Qué objetos fraudulentos (billetes falsos, paquetes, pepitas falsas) fueron hallados en posesión del intervenido o entregados por la víctima?",
          tag: "[estafa.objetos]",
          suggestions: ["Se halló un paquete simulando fardos de billetes (balurdo)", "La víctima entregó un boleto de lotería que resultó ser falso"],
        ),
        WizardStep(
          title: "Reconocimiento",
          description: "¿La víctima reconoció plenamente al intervenido como la persona que le solicitó el dinero o bienes?",
          tag: "[estafa.reconocimiento]",
          suggestions: ["La víctima reconoció plenamente e in situ al intervenido como el autor del engaño", "No hubo reconocimiento directo al momento de la intervención"],
        ),
      ]);
    } else if (typificationId == 'hurto_autopartes') {
      steps.addAll([
        WizardStep(
          title: "Herramientas Incautadas",
          description: "¿Qué herramientas (llaves T, cizallas, desarmadores) se hallaron en poder de los intervenidos al momento de la intervención?",
          tag: "[autopartes.herramientas]",
          suggestions: ["Se halló una 'llave T', una cizalla pequeña y diversos desarmadores", "No se encontraron herramientas en su posesión al ser intervenidos"],
        ),
        WizardStep(
          title: "Autopartes Faltantes y Recuperadas",
          description: "¿Qué autopartes (faros, batería, computadora) le faltaban al vehículo agraviado y cuáles fueron recuperadas?",
          tag: "[autopartes.recuperadas]",
          suggestions: ["Al vehículo le faltaba la batería y el autoradio, los cuales fueron recuperados del poder del intervenido", "Se recuperó un faro delantero derecho oculto en una mochila"],
        ),
        WizardStep(
          title: "Flagrancia del Acto",
          description: "¿El intervenido fue sorprendido en pleno acto de desmantelamiento o huyendo con las autopartes?",
          tag: "[autopartes.flagrancia]",
          suggestions: ["Fue sorprendido in fraganti mientras desconectaba la batería del vehículo", "Fue intervenido huyendo del lugar a escasos metros llevando consigo un espejo retrovisor"],
        ),
      ]);
    } else if (typificationId == 'fuga_accidente') {
      steps.addAll([
        WizardStep(
          title: "Daños en el Vehículo",
          description: "¿El vehículo intervenido presenta características vinculadas al accidente (parabrisas roto, abolladuras, rastros de sangre)?",
          tag: "[fuga.danos_vehiculo]",
          suggestions: ["Presenta el parabrisas delantero trizado y abolladuras recientes en el capot", "Se observaron posibles restos hemáticos en el parachoque delantero"],
        ),
        WizardStep(
          title: "Actitud del Conductor",
          description: "¿A qué distancia del lugar del accidente fue intervenido el conductor y en qué actitud se encontraba (intentando ocultar el vehículo, dándose a la fuga)?",
          tag: "[fuga.actitud_conductor]",
          suggestions: ["Fue intervenido a 5 cuadras del lugar de los hechos intentando darse a la fuga acelerando el vehículo", "Se encontraba intentando ocultar el vehículo al interior de una cochera"],
        ),
        WizardStep(
          title: "Signos de Ebriedad",
          description: "¿El conductor presentaba signos evidentes de haber ingerido bebidas alcohólicas o estupefacientes?",
          tag: "[fuga.signos_ebriedad]",
          suggestions: ["Presentaba evidente aliento alcohólico y dificultad para coordinar sus movimientos", "No presentaba signos evidentes de haber ingerido bebidas alcohólicas"],
        ),
      ]);
    } else if (typificationId == 'salud_publica') {
      steps.addAll([
        WizardStep(
          title: "Condiciones de Salubridad",
          description: "¿En qué condiciones de salubridad se almacenaban los medicamentos o productos intervenidos?",
          tag: "[salud.condiciones]",
          suggestions: ["Se almacenaban en condiciones insalubres, expuestos a la humedad y en cajas deterioradas", "Se encontraban en estantes sin el control de temperatura adecuado"],
        ),
        WizardStep(
          title: "Evidencias de Adulteración",
          description: "¿Se hallaron evidencias de adulteración (cajas regrabadas, fechas vencidas, etiquetas falsificadas)?",
          tag: "[salud.evidencias]",
          suggestions: ["Se encontraron productos con la fecha de expiración adulterada y etiquetas falsificadas", "Cajas de medicamentos que correspondían a lotes de instituciones públicas (Prohibida su venta)"],
        ),
        WizardStep(
          title: "Sustento Legal",
          description: "¿El intervenido pudo sustentar la procedencia legal y el registro sanitario de los productos?",
          tag: "[salud.sustento]",
          suggestions: ["El intervenido no pudo mostrar ningún documento que sustente la compra legal ni el registro sanitario", "Mostró facturas que no correspondían a los lotes intervenidos"],
        ),
      ]);
    } else if (typificationId == 'derechos_intelectuales') {
      steps.addAll([
        WizardStep(
          title: "Mercadería Incautada",
          description: "¿Qué tipo de mercadería pirata o falsificada se halló y en qué cantidades aproximadas?",
          tag: "[intelectual.mercaderia]",
          suggestions: ["Se hallaron aproximadamente 500 pares de zapatillas con logos falsificados de reconocidas marcas", "Gran cantidad de prendas de vestir con etiquetas de procedencia dudosa"],
        ),
        WizardStep(
          title: "Herramientas de Falsificación",
          description: "¿Se encontraron máquinas, matrices, etiquetas o sellos utilizados para la falsificación de los productos?",
          tag: "[intelectual.herramientas]",
          suggestions: ["Se halló una máquina remalladora, matrices metálicas y rollos de etiquetas falsas", "No se encontraron herramientas de producción, solo el producto final para comercialización"],
        ),
        WizardStep(
          title: "Actitud de los Intervenidos",
          description: "¿Los intervenidos abandonaron la mercadería y huyeron, o fueron detenidos en el lugar de comercialización/producción?",
          tag: "[intelectual.actitud]",
          suggestions: ["Al notar la presencia policial, abandonaron los sacos con mercadería y huyeron en diferentes direcciones", "Fueron intervenidos en flagrancia mientras ofrecían los productos al público"],
        ),
      ]);
    } else if (typificationId == 'maltrato_animal') {
      steps.addAll([
        WizardStep(
          title: "Daño Causado",
          description: "¿Qué tipo de daño, lesión o acto de crueldad se estaba infligiendo al animal al momento de la intervención?",
          tag: "[animal.dano]",
          suggestions: ["Se le estaba propinando golpes contundentes de manera reiterada sin justificación", "El animal presentaba signos graves de desnutrición y estaba amarrado a la intemperie"],
        ),
        WizardStep(
          title: "Instrumento Utilizado",
          description: "¿Se halló el instrumento u objeto utilizado para causar el daño (soga, cuchillo, palo)?",
          tag: "[animal.instrumento]",
          suggestions: ["Se halló en el lugar un palo de madera con posibles rastros de sangre", "No se utilizaron instrumentos, el acto fue mediante agresiones físicas directas (patadas)"],
        ),
        WizardStep(
          title: "Estado del Animal",
          description: "¿Cuál era el estado del animal agraviado y qué medidas se tomaron para su resguardo?",
          tag: "[animal.estado]",
          suggestions: ["El animal presentaba lesiones visibles y fue puesto a buen recaudo contactando a una asociación de rescate", "Se solicitó la inmediata atención veterinaria debido al estado de gravedad"],
        ),
      ]);
    } else if (typificationId == 'danos_agravados') {
      steps.addAll([
        WizardStep(
          title: "Objeto Utilizado",
          description: "¿Qué objeto contundente, químico o instrumento (piedras, pintura, herramientas) utilizó el intervenido para causar el daño?",
          tag: "[danos.objeto]",
          suggestions: ["Utilizó piedras de gran tamaño recogidas de la vía pública", "Empleó latas de pintura en aerosol para vandalizar la fachada"],
        ),
        WizardStep(
          title: "Nivel de Destrozo",
          description: "¿Qué nivel de destrozo se verificó en la propiedad agraviada (ventanas rotas, paredes pintadas, puertas forzadas)?",
          tag: "[danos.nivel]",
          suggestions: ["Se verificó la rotura total de dos ventanas de vidrio y abolladuras en la puerta principal", "Se registraron daños considerables en el parabrisas y espejos del vehículo"],
        ),
        WizardStep(
          title: "Captura",
          description: "¿El intervenido fue capturado en flagrancia causando el daño o inmediatamente después por señalamiento de testigos?",
          tag: "[danos.captura]",
          suggestions: ["Fue capturado en plena flagrancia delictiva al momento de arrojar los objetos contundentes", "Fue intervenido a pocos metros del lugar tras ser señalado directamente por los vecinos testigos"],
        ),
      ]);
    } else if (typificationId == 'trafico_migrantes') {
      steps.addAll([
        WizardStep(
          title: "Condición de los Migrantes",
          description: "¿Cuántos ciudadanos extranjeros indocumentados eran transportados y en qué condiciones se encontraban (hacinamiento, ocultos)?",
          tag: "[migrantes.condicion]",
          suggestions: ["Se encontraban 15 ciudadanos extranjeros indocumentados, hacinados en la parte posterior del furgón", "Estaban ocultos debajo de mercadería intentando evadir los controles policiales"],
        ),
        WizardStep(
          title: "Vehículo y Conductor",
          description: "¿Qué vehículo (tipo, placa) era utilizado para el traslado ilegal y quién lo conducía (el 'Coyote')?",
          tag: "[migrantes.vehiculo]",
          suggestions: ["El traslado se realizaba en un camión furgón cerrado conducido por el intervenido", "Utilizaban un ómnibus interprovincial donde el conductor no registró a los pasajeros en el manifiesto"],
        ),
        WizardStep(
          title: "Incautación de Dinero",
          description: "¿Se incautó dinero en efectivo producto del pago por el traslado ilegal de los migrantes?",
          tag: "[migrantes.dinero]",
          suggestions: ["Se incautó una cantidad considerable de dinero en efectivo en billetes de diversa denominación y moneda extranjera", "No se halló dinero en poder del conductor al momento de la intervención"],
        ),
      ]);
    }

    // ─── BLOQUE 3: DATOS FINALES (Hechos y Cierre) ───


    steps.addAll([
      WizardStep(
        title: "Hechos Precedentes",
        description: "¿Qué motivó la intervención policial? (Ej: Patrullaje de rutina, llamada radial, denuncia ciudadana, actitud sospechosa). Narre de forma objetiva las circunstancias previas.",
        tag: "[hechos.previos]",
      ),
      WizardStep(
        title: "Hechos Concomitantes",
        description: "¿Qué sucedió exactamente durante la intervención? (Ej: Hallazgo de especies, resistencia a la autoridad, flagrancia delictiva). Detalle paso a paso el accionar policial y del intervenido.",
        tag: "[hechos.concomitantes]",
      ),
      WizardStep(
        title: "Nivel de Fuerza / Resistencia",
        description: "¿Cómo respondió el intervenido y qué nivel de fuerza se usó? (Ej: Colaboró con la intervención, opuso tenaz resistencia, se usó fuerza progresiva). Detalle según los manuales de DD.HH.",
        tag: "[hechos.fuerza]",
      ),
      WizardStep(
        title: "Evidencia Hallada (General)",
        description: "¿Hay alguna otra evidencia u objeto de interés que registrar? (Especies, dinero, armas, drogas). Describa de forma precisa características, cantidad y ubicación exacta del hallazgo.",
        tag: "[registro.bienes_detalle]",
      ),

      WizardStep(
        title: "¿Comunicación al Fiscal?",
        description: "¿Se logró comunicar la intervención al Representante del Ministerio Público?",
        tag: "COND_FISCAL",
        isConditionSelector: true,
        conditionKey: "FISCAL",
      ),
      WizardStep(
        title: "Nombre del Fiscal",
        description: "Ingrese el grado (si aplica), apellidos y nombres completos del fiscal del Ministerio Público con quien se comunicó (Ejemplo: 'Fiscal Provincial Adjunto LÓPEZ RAMÍREZ, Juan Carlos'):",
        tag: "[fiscal.grado_nombres]",
        isConditional: true,
        conditionKey: "FISCAL",
        conditionValue: true,
        helpText: "Escriba el cargo y nombre completo del fiscal tal como aparece en sus credenciales oficiales del Ministerio Público.",
      ),
      WizardStep(
        title: "Disposición Fiscal",
        description: "Indique textualmente qué disposición o instrucción impartió el fiscal al ser comunicado de la intervención (Ejemplo: 'Dispuso el traslado del intervenido a la Comisaría PNP para las diligencias de ley'):",
        tag: "[fiscal.resultado_comunicacion]",
        isConditional: true,
        conditionKey: "FISCAL",
        conditionValue: true,
        suggestions: [
          "Dispuso el traslado del intervenido a la Comisaría PNP para las diligencias de ley.",
          "Dispuso que el intervenido pase en calidad de Citado y sea notificado.",
          "Dispuso la realización del peritaje de descarte en el lugar de los hechos.",
        ],
        helpText: "Registre la disposición exacta que dio el Fiscal. Esta información es esencial para la validez del acta.",
      ),
      WizardStep(
        title: "Motivo de No Comunicación al Fiscal",
        description: "Explique detalladamente por qué no fue posible comunicarse con el representante del Ministerio Público (exigencia legal Art. 67 CPP):",
        tag: "[fiscal.motivo_no_comunicacion]",
        isConditional: true,
        conditionKey: "FISCAL",
        conditionValue: false,
        suggestions: [
          "La zona donde ocurrió la intervención no cuenta con cobertura de señal telefónica ni radial.",
          "Se realizaron múltiples intentos de comunicación sin obtener respuesta del representante del Ministerio Público.",
        ],
        helpText: "Debe justificar documentalmente por qué no se comunicó al Fiscal. Omitir esto puede invalidar el acta.",
      ),
      WizardStep(
        title: "Hora de Cierre",
        description: "Hora exacta en la que se concluye la redacción del acta (Ej. 23:45):",
        tag: "[tiempo.acta_hora_cierre]",
        suggestions: [
          DateFormat('HH:mm').format(DateTime.now()),
          DateFormat('HH:mm').format(DateTime.now().add(const Duration(minutes: 10))),
          DateFormat('HH:mm').format(DateTime.now().add(const Duration(minutes: 20))),
          DateFormat('HH:mm').format(DateTime.now().add(const Duration(minutes: 30))),
        ],
      ),
    ]);

    // Renumerar los pasos dinámicamente
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final cleanTitle = step.title.replaceFirst(RegExp(r'^\d+\.\s*'), '');

      // Limit suggestions to structural or profile fields
      List<String>? finalSuggestions = step.suggestions;
      final allowedTags = [
        '[lugar.provincia]',
        '[lugar.distrito]',
        '[tiempo.acta_hora_inicio]',
        '[tiempo.acta_hora_cierre]',
        '[imputado.nacionalidad]',
        '[imputado.estado_civil]',
        '[imputado.grado_instruccion]',
        '[imputado.ocupacion]',
        '[imputado.religion]',
        '[imputado.correo]'
      ];
      if (!allowedTags.contains(step.tag) && !step.loadRecentComisarias) {
        finalSuggestions = null;
      }

      steps[i] = WizardStep(
        title: "${i + 1}. $cleanTitle",
        description: step.description,
        tag: step.tag,
        suggestions: finalSuggestions,
        isConditional: step.isConditional,
        conditionKey: step.conditionKey,
        conditionValue: step.conditionValue,
        isDni: step.isDni,
        isConditionSelector: step.isConditionSelector,
        helpText: step.helpText,
        loadRecentComisarias: step.loadRecentComisarias,
      );
    }

    return steps;
  }
