class TagDefinition {
  final String name; // Nombre para mostrar
  final String tag; // Etiqueta para insertar: [variable.campo]
  final String category; // Categoría para organizar
  final List<String>? options; // Opciones preconfiguradas

  const TagDefinition({
    required this.name,
    required this.tag,
    required this.category,
    this.options,
  });
}

class TagsRepository {
  static const List<TagDefinition> allTags = [
    // BLOQUE 1: VARIABLES DE TIEMPO
    TagDefinition(
      name: 'Hora del Hecho (24h)',
      tag: '[tiempo.hora_hecho]',
      category: 'BLOQUE 1: VARIABLES DE TIEMPO',
    ),
    TagDefinition(
      name: 'Fecha del Hecho',
      tag: '[tiempo.fecha_hecho]',
      category: 'BLOQUE 1: VARIABLES DE TIEMPO',
    ),
    TagDefinition(
      name: 'Hora Inicio del Acta (Mixto)',
      tag: '[tiempo.acta_hora_inicio]',
      category: 'BLOQUE 1: VARIABLES DE TIEMPO',
    ),
    TagDefinition(
      name: 'Hora Cierre del Acta (Mixto)',
      tag: '[tiempo.acta_hora_cierre]',
      category: 'BLOQUE 1: VARIABLES DE TIEMPO',
    ),

    // BLOQUE 2: VARIABLES DE LUGAR Y VÍAS
    TagDefinition(
      name: 'Tipo de Vía (Desplegable)',
      tag: '[lugar.tipo_via]',
      category: 'BLOQUE 2: VARIABLES DE LUGAR Y VÍAS',
    ),
    TagDefinition(
      name: 'Nombre de la Vía',
      tag: '[lugar.nombre_via]',
      category: 'BLOQUE 2: VARIABLES DE LUGAR Y VÍAS',
    ),
    TagDefinition(
      name: 'Distrito',
      tag: '[lugar.distrito]',
      category: 'BLOQUE 2: VARIABLES DE LUGAR Y VÍAS',
    ),
    TagDefinition(
      name: 'Provincia',
      tag: '[lugar.provincia]',
      category: 'BLOQUE 2: VARIABLES DE LUGAR Y VÍAS',
    ),
    TagDefinition(
      name: 'Departamento',
      tag: '[lugar.departamento]',
      category: 'BLOQUE 2: VARIABLES DE LUGAR Y VÍAS',
    ),

    // BLOQUE 3: VARIABLES DE IDENTIDAD
    TagDefinition(
      name: 'Identificación Rápida (NENEOIDD)',
      tag: '[neneoidd]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Nombres y Apellidos',
      tag: '[imputado.nombres_apellidos]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Edad',
      tag: '[imputado.edad]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Nacionalidad',
      tag: '[imputado.nacionalidad]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Lugar de Nacimiento',
      tag: '[imputado.lugar_nacimiento]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Fecha de Nacimiento',
      tag: '[imputado.fecha_nacimiento]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Nombres de Padres',
      tag: '[imputado.nombres_padres]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Estado Civil',
      tag: '[imputado.estado_civil]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Grado de Instrucción',
      tag: '[imputado.grado_instruccion]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Ocupación',
      tag: '[imputado.ocupacion]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Religión',
      tag: '[imputado.religion]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - DNI',
      tag: '[imputado.dni]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Domicilio',
      tag: '[imputado.domicilio]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Correo',
      tag: '[imputado.correo]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Imputado - Teléfono',
      tag: '[imputado.telefono]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),

    // BLOQUE 3: VARIABLES DE TESTIGO
    TagDefinition(
      name: 'Testigo - Nombres y Apellidos',
      tag: '[testigo.nombres_apellidos]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Testigo - DNI',
      tag: '[testigo.dni]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Testigo - Domicilio',
      tag: '[testigo.domicilio]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Testigo - Teléfono',
      tag: '[testigo.telefono]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Testigo - Vínculo/Parentesco',
      tag: '[testigo.vinculo]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),

    // BLOQUE 3: VARIABLES DE AGRAVIADO
    TagDefinition(
      name: 'Agraviado - Nombres y Apellidos',
      tag: '[agraviado.nombres_apellidos]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),
    TagDefinition(
      name: 'Agraviado - DNI',
      tag: '[agraviado.dni]',
      category: 'BLOQUE 3: VARIABLES DE IDENTIDAD',
    ),

    // BLOQUE 4: VARIABLES VEHICULARES
    TagDefinition(
      name: 'Placa Única Nacional de Rodaje',
      tag: '[vehiculo.placa_unica_nacional_rodaje]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Clase de Vehículo',
      tag: '[vehiculo.clase]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Marca del Vehículo',
      tag: '[vehiculo.marca]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Modelo del Vehículo',
      tag: '[vehiculo.modelo]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Color del Vehículo',
      tag: '[vehiculo.color]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Número de Motor',
      tag: '[vehiculo.motor]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Número de Serie',
      tag: '[vehiculo.serie]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Checklist - Exterior (Positivos)',
      tag: '[vehiculo.lista_exterior_positiva]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Checklist - Interior (Positivos)',
      tag: '[vehiculo.lista_interior_positiva]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Checklist - Motor (Positivos)',
      tag: '[vehiculo.lista_motor_positiva]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),
    TagDefinition(
      name: 'Observaciones y Faltantes',
      tag: '[vehiculo.observaciones]',
      category: 'BLOQUE 4: VARIABLES VEHICULARES',
    ),

    // BLOQUE 5: VARIABLES DE ESPECIES - DROGAS
    TagDefinition(
      name: 'Droga - Tipo de Envoltorio',
      tag: '[droga.tipo_envoltorio]',
      category: 'BLOQUE 5: VARIABLES DE ESPECIES (DROGAS)',
    ),
    TagDefinition(
      name: 'Droga - Contenido y Apariencia',
      tag: '[droga.contenido_apariencia]',
      category: 'BLOQUE 5: VARIABLES DE ESPECIES (DROGAS)',
    ),

    // BLOQUE 5: VARIABLES DE ESPECIES - ARMAS
    TagDefinition(
      name: 'Arma - Tipo',
      tag: '[arma.tipo]',
      category: 'BLOQUE 5: VARIABLES DE ESPECIES (ARMAS)',
    ),
    TagDefinition(
      name: 'Arma - Mecanismo',
      tag: '[arma.mecanismo]',
      category: 'BLOQUE 5: VARIABLES DE ESPECIES (ARMAS)',
    ),

    // BLOQUE 6: VARIABLES DEL MINISTERIO PÚBLICO / INSTRUCTOR
    TagDefinition(
      name: 'Instructor - Grado y Nombres',
      tag: '[instructor.grado_nombres]',
      category: 'BLOQUE 6: VARIABLES DEL MINISTERIO PÚBLICO',
    ),
    TagDefinition(
      name: 'Instructor - CIP',
      tag: '[instructor.cip]',
      category: 'BLOQUE 6: VARIABLES DEL MINISTERIO PÚBLICO',
    ),
    TagDefinition(
      name: 'Fiscal - Grado y Nombres',
      tag: '[fiscal.grado_nombres]',
      category: 'BLOQUE 6: VARIABLES DEL MINISTERIO PÚBLICO',
    ),
    TagDefinition(
      name: 'Fiscal - Fiscalía',
      tag: '[fiscal.fiscalia]',
      category: 'BLOQUE 6: VARIABLES DEL MINISTERIO PÚBLICO',
    ),
    TagDefinition(
      name: 'Fiscal - Hora de Comunicación',
      tag: '[fiscal.hora_comunicacion]',
      category: 'BLOQUE 6: VARIABLES DEL MINISTERIO PÚBLICO',
    ),
    TagDefinition(
      name: 'Fiscal - Teléfono Usado',
      tag: '[fiscal.telefono_usado]',
      category: 'BLOQUE 6: VARIABLES DEL MINISTERIO PÚBLICO',
    ),

    // BLOQUE 7: VARIABLES DE CIERRE Y LEGALIDAD
    TagDefinition(
      name: 'Firma - Se Negó el Imputado',
      tag: '[firma.se_nego_imputado]',
      category: 'BLOQUE 7: VARIABLES DE CIERRE Y LEGALIDAD',
    ),
    TagDefinition(
      name: 'Firma - Motivo de Negativa',
      tag: '[firma.motivo_negativa]',
      category: 'BLOQUE 7: VARIABLES DE CIERRE Y LEGALIDAD',
      options: [
        'Por recomendación estricta de su abogado defensor, quien le indicó no firmar ningún documento en la dependencia policial.',
        'Aduciendo que el contenido del acta no guarda relación con los hechos ocurridos.',
        'Porque manifiesta no querer firmar o avalar sus propios dichos vertidos durante la intervención.',
      ],
    ),
    TagDefinition(
      name: 'Acta - Lugar de Redacción',
      tag: '[acta.lugar_redaccion]',
      category: 'BLOQUE 7: VARIABLES DE CIERRE Y LEGALIDAD',
    ),
    TagDefinition(
      name: 'Acta - Dependencia Policial',
      tag: '[acta.dependencia_policial]',
      category: 'BLOQUE 7: VARIABLES DE CIERRE Y LEGALIDAD',
    ),
    TagDefinition(
      name: 'Acta - Circunstancia Apremiante',
      tag: '[acta.circunstancia_apremiante]',
      category: 'BLOQUE 7: VARIABLES DE CIERRE Y LEGALIDAD',
    ),

    // BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA (EL BLINDAJE DEL CPP)
    TagDefinition(
      name: 'Detención - Motivo Fáctico',
      tag: '[detencion.motivo_factico]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Abogado - Nombres',
      tag: '[abogado.nombres]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Abogado - Teléfono',
      tag: '[abogado.telefono]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Abogado - Dirección',
      tag: '[abogado.direccion]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Abogado - Es de Oficio',
      tag: '[abogado.es_de_oficio]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Intérprete - Nombres',
      tag: '[interprete.nombres]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Intérprete - Requiere',
      tag: '[interprete.requiere]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Intérprete - Idioma',
      tag: '[interprete.idioma]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Imputado - Solicita Examen Médico',
      tag: '[imputado.solicita_examen_medico]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Persona - Vínculo a Comunicar',
      tag: '[persona.vinculo]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
    ),
    TagDefinition(
      name: 'Imputado - Base Legal de Detención',
      tag: '[imputado.base_legal_detencion]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
      options: [
        "Detención en flagrancia delictiva, conforme al Art. 2° literal 'f', inciso 24 de la Constitución Política del Perú y Art. 259° del Código Procesal Penal.",
        'Detención por mandato escrito y motivado del Juez.',
      ],
    ),
    TagDefinition(
      name: 'Derechos - Lectura de Artículos',
      tag: '[derechos.lectura_articulos]',
      category: 'BLOQUE 8: GARANTÍAS Y DEFENSA TÉCNICA',
      options: [
        'Se le informa que tiene derecho a: 1. Hacer valer sus derechos por sí mismo o por un Abogado Defensor. 2. A que no se empleen en su contra medios coactivos, intimidatorios o contrarios a su dignidad. 3. A ser examinado por un médico legista cuando su estado de salud lo requiera.',
      ],
    ),

    // BLOQUE 9: EJECUCIÓN DE REGISTROS (PERSONAL, VEHICULAR Y DOMICILIARIO)
    TagDefinition(
      name: 'Registro - Razones Comunicadas',
      tag: '[registro.razones_comunicadas]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
      options: [
        'Búsqueda de elementos incriminatorios (armas, drogas o especies) tras su negativa a exhibirlos de forma voluntaria.',
        'Para completar la investigación y descartar la posesión de otros elementos ilícitos, pese a haber exhibido voluntariamente el bien inicial.',
      ],
    ),
    TagDefinition(
      name: 'Registro - Solicitud de Exhibición',
      tag: '[registro.solicitud_exhibicion]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
    ),
    TagDefinition(
      name: 'Registro - Descripción Bien Buscado',
      tag: '[registro.descripcion_bien_buscado]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
    ),
    TagDefinition(
      name: 'Registro - Ubicación Exacta Hallazgo',
      tag: '[registro.ubicacion_exacta_hallazgo]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
    ),
    TagDefinition(
      name: 'Registro - Actos para Ubicar Testigo',
      tag: '[registro.actos_ubicacion_testigo]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
    ),
    TagDefinition(
      name: 'Registro - Circunstancias Sexo Distinto',
      tag: '[registro.circunstancias_sexo_distinto]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
    ),
    TagDefinition(
      name: 'Registro - Razones Equipaje',
      tag: '[registro.razones_equipaje]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
    ),
    TagDefinition(
      name: 'Registro - Medio Audiovisual/Filmación',
      tag: '[registro.medio_audiovisual_filmacion]',
      category: 'BLOQUE 9: EJECUCIÓN DE REGISTROS',
    ),

    // BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN MATERIA DEL DELITO
    TagDefinition(
      name: 'Bien - Número de Hallazgo',
      tag: '[bien.numero_hallazgo]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),
    TagDefinition(
      name: 'Bien - Cantidad',
      tag: '[bien.cantidad]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),
    TagDefinition(
      name: 'Bien - Unidad de Medida',
      tag: '[bien.unidadMedida]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),
    TagDefinition(
      name: 'Bien - Descripción',
      tag: '[bien.descripcion]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),
    TagDefinition(
      name: 'Bien - Condición Legal',
      tag: '[bien.condicion_legal]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),
    TagDefinition(
      name: 'Bien - Destino Final',
      tag: '[bien.destino_final]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),
    TagDefinition(
      name: 'Incautación - Marca/Rótulo',
      tag: '[incautacion.marca_rotulo]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),
    TagDefinition(
      name: 'Custodia - Funcionario Encargado',
      tag: '[custodia.funcionario_encargado]',
      category: 'BLOQUE 10: CADENA DE CUSTODIA E INCAUTACIÓN',
    ),

    // BLOQUE 11: REGLAS DEL MINISTERIO PÚBLICO (AMPLIACIÓN)
    TagDefinition(
      name: 'Fiscal - Número Llamadas',
      tag: '[fiscal.numero_llamadas]',
      category: 'BLOQUE 11: REGLAS DEL MINISTERIO PÚBLICO (AMPLIACIÓN)',
    ),
    TagDefinition(
      name: 'Fiscal - Resultado Comunicación',
      tag: '[fiscal.resultado_comunicacion]',
      category: 'BLOQUE 11: REGLAS DEL MINISTERIO PÚBLICO (AMPLIACIÓN)',
      options: [
        'El Fiscal tomó conocimiento y dispuso la ejecución inmediata de las diligencias de urgencia e imprescindibles en el lugar.',
        'El Fiscal tomó conocimiento, dispuso perennizar la escena, el traslado del detenido y la ejecución de diligencias inaplazables.',
      ],
    ),
    TagDefinition(
      name: 'Fiscal de Familia - Nombres',
      tag: '[fiscal_familia.nombres]',
      category: 'BLOQUE 11: REGLAS DEL MINISTERIO PÚBLICO (AMPLIACIÓN)',
    ),
    TagDefinition(
      name: 'Fiscal de Familia - Fiscalía',
      tag: '[fiscal_familia.fiscalia]',
      category: 'BLOQUE 11: REGLAS DEL MINISTERIO PÚBLICO (AMPLIACIÓN)',
    ),
    TagDefinition(
      name: 'Fiscal de Familia - Celular',
      tag: '[fiscal_familia.celular]',
      category: 'BLOQUE 11: REGLAS DEL MINISTERIO PÚBLICO (AMPLIACIÓN)',
    ),

    // BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL
    TagDefinition(
      name: 'Narrativa Fáctica (Hechos)',
      tag: '[narrativa.hechos]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
    ),
    TagDefinition(
      name: 'Acta - Razones Cambio Lugar',
      tag: '[acta.razones_cambio_lugar]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
      options: [
        'Para salvaguardar la integridad física del imputado (peligro de linchamiento o agresión por parte de la población/agraviados).',
        'Para salvaguardar la integridad física de los funcionarios intervinientes (zona roja o turba hostil).',
        'Para neutralizar una posible fuga o rescate del imputado por parte de terceros o cómplices.',
        'Por presentarse fenómenos de índole climatológica (lluvia torrencial, truenos, etc.) que destruyen la documentación.',
        'Por falta de garantías logísticas como la oscuridad extrema o apagón en la vía pública.',
      ],
    ),
    TagDefinition(
      name: 'Tiempo - Duración Diligencia',
      tag: '[tiempo.duracion_diligencia]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
    ),
    TagDefinition(
      name: 'Resolución - Confirmatoria Nro',
      tag: '[resolucion.confirmatoria_nro]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
    ),
    TagDefinition(
      name: 'Resolución - Fecha',
      tag: '[resolucion.fecha]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
    ),
    TagDefinition(
      name: 'Persona - Condición/Situación',
      tag: '[persona.condicion_situacion]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
    ),
    TagDefinition(
      name: 'Notificación - Superior Ordena',
      tag: '[notificacion.superior_ordena]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
    ),
    TagDefinition(
      name: 'Notificación - Causa',
      tag: '[notificacion.causa]',
      category: 'BLOQUE 12: DILIGENCIAS ESPECÍFICAS Y CONTROL TEMPORAL',
    ),

    // BLOQUE 13: VARIABLES DE IDENTIFICACIÓN ADICIONALES
    TagDefinition(
      name: 'Imputado - Señas Particulares',
      tag: '[imputado.senas_particulares]',
      category: 'BLOQUE 13: VARIABLES DE IDENTIFICACIÓN ADICIONALES',
    ),
    TagDefinition(
      name: 'Imputado - Lugar de Trabajo',
      tag: '[imputado.lugar_trabajo]',
      category: 'BLOQUE 13: VARIABLES DE IDENTIFICACIÓN ADICIONALES',
    ),
    TagDefinition(
      name: 'Vehículo - Año de Fabricación',
      tag: '[vehiculo.ano_fabricacion]',
      category: 'BLOQUE 13: VARIABLES DE IDENTIFICACIÓN ADICIONALES',
    ),
    TagDefinition(
      name: 'Vehículo - Otros Datos',
      tag: '[vehiculo.otros_datos]',
      category: 'BLOQUE 13: VARIABLES DE IDENTIFICACIÓN ADICIONALES',
    ),

    // BLOQUE 14: PROCEDIMIENTOS COMPLEMENTARIOS
    TagDefinition(
      name: 'Reconocimiento - Tipo Exhibición',
      tag: '[reconocimiento.tipo_exhibicion]',
      category: 'BLOQUE 14: PROCEDIMIENTOS COMPLEMENTARIOS',
    ),
    TagDefinition(
      name: 'Reconocimiento - Resultados',
      tag: '[reconocimiento.resultados]',
      category: 'BLOQUE 14: PROCEDIMIENTOS COMPLEMENTARIOS',
    ),
    TagDefinition(
      name: 'Dosaje - Nro Oficio',
      tag: '[dosaje.nro_oficio]',
      category: 'BLOQUE 14: PROCEDIMIENTOS COMPLEMENTARIOS',
    ),
    TagDefinition(
      name: 'Dosaje - Resultado',
      tag: '[dosaje.resultado]',
      category: 'BLOQUE 14: PROCEDIMIENTOS COMPLEMENTARIOS',
    ),

    // BLOQUE 13: PARTE POLICIAL Y SIGE
    TagDefinition(
      name: 'Número de Registro SIGE',
      tag: '[sige.numero_registro]',
      category: 'BLOQUE 13: PARTE POLICIAL Y SIGE',
    ),
    TagDefinition(
      name: 'Parte Policial - Número Correlativo',
      tag: '[documento.numero_correlativo]',
      category: 'BLOQUE 13: PARTE POLICIAL Y SIGE',
    ),
    TagDefinition(
      name: 'Parte Policial - Siglas de la Unidad',
      tag: '[documento.siglas_unidad]',
      category: 'BLOQUE 13: PARTE POLICIAL Y SIGE',
    ),
    TagDefinition(
      name: 'Referencia / Base (Ej. Llamada 105)',
      tag: '[documento.referencia]',
      category: 'BLOQUE 13: PARTE POLICIAL Y SIGE',
    ),
    TagDefinition(
      name: 'Narrativa - Antecedentes',
      tag: '[narrativa.antecedentes]',
      category: 'BLOQUE 13: PARTE POLICIAL Y SIGE',
    ),

    // BLOQUE 14: ALLANAMIENTO Y REGISTRO DOMICILIARIO
    TagDefinition(
      name: 'Allanamiento - Motivo Legal de Ingreso (Candado Constitucional)',
      tag: '[allanamiento.motivo_ingreso]',
      category: 'BLOQUE 14: ALLANAMIENTO Y REGISTRO DOMICILIARIO',
    ),
    TagDefinition(
      name: 'Lugar - Tipo de Vía (Jr., Av., Ca., etc.)',
      tag: '[lugar.tipo_via]',
      category: 'BLOQUE 14: ALLANAMIENTO Y REGISTRO DOMICILIARIO',
    ),
    TagDefinition(
      name: 'Lugar - Nombre de Vía',
      tag: '[lugar.nombre_via]',
      category: 'BLOQUE 14: ALLANAMIENTO Y REGISTRO DOMICILIARIO',
    ),
    TagDefinition(
      name: 'Registro - Ubicación Exacta del Hallazgo',
      tag: '[registro.ubicacion_exacta_hallazgo]',
      category: 'BLOQUE 14: ALLANAMIENTO Y REGISTRO DOMICILIARIO',
    ),

    // BLOQUE 15: ESCENA DEL DELITO
    TagDefinition(
      name: 'Escena - Información Recibida / Cómo Tomó Conocimiento',
      tag: '[escena.informacion_recibida]',
      category: 'BLOQUE 15: ESCENA DEL DELITO',
    ),
    TagDefinition(
      name: 'Escena - Datos de Lesionados (Si los hay)',
      tag: '[escena.lesionados_datos]',
      category: 'BLOQUE 15: ESCENA DEL DELITO',
    ),
    TagDefinition(
      name: 'Escena - Medios de Aislamiento (Cintas, personal, tranqueras)',
      tag: '[escena.aislamiento_medios]',
      category: 'BLOQUE 15: ESCENA DEL DELITO',
    ),
    TagDefinition(
      name: 'Escena - Manipulación Observada (Sí/No)',
      tag: '[escena.manipulacion_observada]',
      category: 'BLOQUE 15: ESCENA DEL DELITO',
    ),
    TagDefinition(
      name: 'Escena - Indicios y Evidencias Observadas',
      tag: '[escena.indicios_observados]',
      category: 'BLOQUE 15: ESCENA DEL DELITO',
    ),
    TagDefinition(
      name: 'Escena - Hora de Llegada de Peritos / MP',
      tag: '[escena.hora_llegada_peritos]',
      category: 'BLOQUE 15: ESCENA DEL DELITO',
    ),
    TagDefinition(
      name: 'Escena - Personal que Recibe la Escena (Relevo)',
      tag: '[escena.personal_relevo]',
      category: 'BLOQUE 15: ESCENA DEL DELITO',
    ),

    // BLOQUE 16: RECONOCIMIENTO FÍSICO (Art. 189° CPP)
    TagDefinition(
      name: 'Abogado Defensor - Nombres',
      tag: '[abogado.nombres]',
      category: 'BLOQUE 16: RECONOCIMIENTO FÍSICO',
    ),
    TagDefinition(
      name: 'Reconocimiento - Descripción Previa del Testigo',
      tag: '[reconocimiento.descripcion_previa]',
      category: 'BLOQUE 16: RECONOCIMIENTO FÍSICO',
    ),
    TagDefinition(
      name: 'Reconocimiento - Resultado del Reconocimiento',
      tag: '[reconocimiento.resultado]',
      category: 'BLOQUE 16: RECONOCIMIENTO FÍSICO',
    ),

    // BLOQUE 17: ACTA DE RECEPCIÓN
    TagDefinition(
      name: 'Testigo - Teléfono / Celular',
      tag: '[testigo.telefono]',
      category: 'BLOQUE 17: ACTA DE RECEPCIÓN',
    ),
    TagDefinition(
      name: 'Recepción - Motivo de la Entrega',
      tag: '[recepcion.motivo]',
      category: 'BLOQUE 17: ACTA DE RECEPCIÓN',
    ),

    // BLOQUE 18: OFICIOS, CITACIONES Y NOTIFICACIONES
    TagDefinition(
      name: 'Dependencia - Dirección de la Comisaría',
      tag: '[dependencia.direccion]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),
    TagDefinition(
      name: 'Citación - Fecha Programada de Comparecencia',
      tag: '[citacion.fecha_programada]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),
    TagDefinition(
      name: 'Citación - Hora Programada de Comparecencia',
      tag: '[citacion.hora_programada]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),
    TagDefinition(
      name: 'Citación - Motivo de la Diligencia',
      tag: '[citacion.motivo_diligencia]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),
    TagDefinition(
      name: 'Citación - Número de Citación (1ra / 2da / 3ra)',
      tag: '[citacion.numero_orden]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),
    TagDefinition(
      name: 'Notificación - Causa de la Notificación',
      tag: '[notificacion.causa]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),
    TagDefinition(
      name: 'Notificación - Superior que Ordena',
      tag: '[notificacion.superior_ordena]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),
    TagDefinition(
      name: 'Testigo - Domicilio',
      tag: '[testigo.domicilio]',
      category: 'BLOQUE 18: OFICIOS Y CITACIONES',
    ),

    // BLOQUE 19: AGRAVIADO Y DERECHOS DE VÍCTIMA
    TagDefinition(
      name: 'Agraviado - Nombres y Apellidos',
      tag: '[agraviado.nombres_apellidos]',
      category: 'BLOQUE 19: AGRAVIADO Y DERECHOS DE VÍCTIMA',
    ),
    TagDefinition(
      name: 'Agraviado - DNI',
      tag: '[agraviado.dni]',
      category: 'BLOQUE 19: AGRAVIADO Y DERECHOS DE VÍCTIMA',
    ),
    TagDefinition(
      name: 'Agraviado - Domicilio',
      tag: '[agraviado.domicilio]',
      category: 'BLOQUE 19: AGRAVIADO Y DERECHOS DE VÍCTIMA',
    ),
    TagDefinition(
      name: 'Acta - Lugar de Redacción del Acta',
      tag: '[acta.lugar_redaccion]',
      category: 'BLOQUE 19: AGRAVIADO Y DERECHOS DE VÍCTIMA',
    ),
    // BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS
    TagDefinition(
      name: 'Imputado - Apellidos',
      tag: '[imputado.apellidos]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Imputado - Nombres',
      tag: '[imputado.nombres]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Imputado - Nombre del Padre',
      tag: '[imputado.nombre_padre]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Imputado - Nombre de la Madre',
      tag: '[imputado.nombre_madre]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Imputado - Dirección de Trabajo',
      tag: '[imputado.direccion_trabajo]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Imputado - Profesión',
      tag: '[imputado.profesion]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Imputado - Características Físicas',
      tag: '[imputado.caracteristicas_fisicas]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Intervención - Motivo',
      tag: '[intervencion.motivo]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Intervención - Documento Redactado',
      tag: '[intervencion.documento_redactado]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    TagDefinition(
      name: 'Intervención - Observaciones',
      tag: '[intervencion.observaciones]',
      category: 'BLOQUE 20: HOJAS DE IDENTIFICACIÓN Y REQUISITORIAS',
    ),
    // BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS
    TagDefinition(
      name: 'Registro - Descripción Detallada de Bienes Hallados',
      tag: '[registro.bienes_detalle]',
      category: 'BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS',
    ),
    TagDefinition(
      name: 'Manifestación - Respuesta 01 (Derecho a Abogado)',
      tag: '[manifestacion.respuesta_01]',
      category: 'BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS',
    ),
    TagDefinition(
      name: 'Manifestación - Respuesta 02 (Reconocimiento de Cargo)',
      tag: '[manifestacion.respuesta_02]',
      category: 'BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS',
    ),
    TagDefinition(
      name: 'Manifestación - Respuesta 03 (Detalles del Hecho)',
      tag: '[manifestacion.respuesta_03]',
      category: 'BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS',
    ),
    TagDefinition(
      name: 'Manifestación - Respuesta 04 (Propiedad de Especies)',
      tag: '[manifestacion.respuesta_04]',
      category: 'BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS',
    ),
    TagDefinition(
      name: 'Manifestación - Respuesta 05 (Cierre y Descargo)',
      tag: '[manifestacion.respuesta_05]',
      category: 'BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS',
    ),
    TagDefinition(
      name: 'Manifestación - Observaciones y Preguntas Libres',
      tag: '[manifestacion.observaciones]',
      category: 'BLOQUE 21: UNIFICACIÓN DE EDITORES DE ACTAS',
    ),
    // BLOQUE 22: LEVANTAMIENTO DE CADÁVER Y MÉDICO LEGISTA
    TagDefinition(
      name: 'Occiso - Nombres y Apellidos',
      tag: '[occiso.nombres_apellidos]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Edad',
      tag: '[occiso.edad]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - DNI',
      tag: '[occiso.dni]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Pertenencias',
      tag: '[occiso.pertenencias]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Posición del Cadáver',
      tag: '[occiso.posicion_cadaver]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Ubicación Exacta',
      tag: '[occiso.ubicacion_exacta]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Descripción Física y Ropa',
      tag: '[occiso.descripcion_fisica_ropa]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Signos de Violencia',
      tag: '[occiso.signos_violencia]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Medio de Traslado',
      tag: '[occiso.medio_traslado]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Occiso - Lugar de Morgue',
      tag: '[occiso.lugar_morgue]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Médico - Nombres y Apellidos',
      tag: '[medico.nombres_apellidos]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Médico - CMP',
      tag: '[medico.cmp]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Médico - Diagnóstico Presuntivo',
      tag: '[medico.diagnostico_presuntivo]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Médico - Data de Muerte',
      tag: '[medico.data_muerte]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
    TagDefinition(
      name: 'Escena - Evidencias Halladas',
      tag: '[escena.evidencias_halladas]',
      category: 'BLOQUE 22: LEVANTAMIENTO DE CADÁVER',
    ),
  ];

  static List<TagDefinition> searchTags(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return allTags
        .where(
          (tag) =>
              tag.name.toLowerCase().contains(lowerQuery) ||
              tag.tag.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  static final Map<String, TagDefinition> tagMap = {
    for (var t in allTags) t.tag: t
  };

  static final List<String> categories = allTags.map((tag) => tag.category).toSet().toList();

  static List<String> getCategories() {
    return categories;
  }
}
