class DefaultTemplates {
  // ===========================================================================
  // BLOQUE 1: ACTAS MATRICES Y DE FLAGRANCIA
  // ===========================================================================

  static const String actaIntervencion = '''ACTA DE INTERVENCIÓN POLICIAL

En la provincia de [lugar.provincia], distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas, el personal policial interviniente conformado por: [instructor.grado_nombres]<IF_ACOMPANANTE> en compañía del efectivo policial [acompanante.grado] [acompanante.apellidos_nombres], CIP N° [acompanante.cip]</IF_ACOMPANANTE>, formula la presente acta para dejar constancia de los siguientes hechos ocurridos en la ubicación exacta de: [lugar.calle].

--- II. IDENTIFICACIÓN DEL INTERVENIDO ---
Nombres y Apellidos: [imputado.nombres_apellidos]
Edad: [imputado.edad] años | Nacionalidad: [imputado.nacionalidad]
Fecha y Lugar de Nac.: [imputado.fecha_nacimiento] en [imputado.lugar_nacimiento]
Padres: [imputado.padres]
Estado Civil: [imputado.estado_civil] | Grado de Instrucción: [imputado.grado_instruccion]
Profesión/Ocupación: [imputado.ocupacion] | Religión: [imputado.religion]
Documento de Identidad: [imputado.dni]
Domicilio Real: [imputado.domicilio]
Teléfono: [imputado.telefono] | Correo: [imputado.correo]

--- III. IDENTIFICACIÓN VEHICULAR ---
Se intervino el vehículo de Placa: [vehiculo.placa_unica_nacional_rodaje], Clase: [vehiculo.clase], Marca: [vehiculo.marca], Modelo: [vehiculo.modelo], Año: [vehiculo.anio], Color: [vehiculo.color].
Nro de Serie/VIN: [vehiculo.vin] | Nro de Motor: [vehiculo.motor].

--- IV. RELATO FÁCTICO ---
HECHOS PRECEDENTES: [hechos.previos]
HECHOS CONCOMITANTES: [hechos.concomitantes]
NIVEL DE FUERZA Y RESISTENCIA: [hechos.fuerza]
HECHOS POSTERIORES: [hechos.posteriores]

--- V. HALLAZGOS Y EVIDENCIAS ---
Se halló en posesión: [evi.objetos]
Ubicación exacta: [evi.ubicacion]
Cantidad: [evi.cantidad]
Características individualizantes: [evi.caracteristicas]

--- VI. COMUNICACIÓN AL MINISTERIO PÚBLICO ---
<IF_FISCAL>Se hace constar que se comunicó de los hechos al representante del Ministerio Público, [fiscal.grado_nombres], quien dispuso: [fiscal.resultado_comunicacion].</IF_FISCAL><IF_NOT_FISCAL>No se pudo establecer comunicación con el Ministerio Público por el siguiente motivo: [fiscal.motivo_no_comunicacion].</IF_NOT_FISCAL>

--- VII. CIERRE DEL ACTA Y FIRMAS ---
Siendo las [tiempo.acta_hora_cierre] horas del mismo día, se da por concluida la presente diligencia de intervención policial in situ, procediendo los intervinientes a estampar sus respectivas firmas y huellas dactilares en señal de conformidad y validez legal.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL INTERVENIDO
[instructor.grado_nombres]                    [imputado.nombres_apellidos]
CIP N° [instructor.cip]                       DNI N° [imputado.dni]

_________________________                     _________________________
(Firma y sello físico)                        (Firma y/o huella)
''';

  static const String actaLlegadaEscena = '''
ACTA DE LLEGADA AL LUGAR DE LOS HECHOS (ESCENA DEL DELITO)

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del da [tiempo.fecha_hecho], el instructor PNP [instructor.grado_nombres], identificado con CIP N° [instructor.cip], a bordo del vehculo policial [vehiculo_policial.placa], deja expresa constancia tcnica de su arribo a la escena del delito ubicada en: [acta.lugar_redaccion], procediendo conforme a los protocolos de actuacin:

I. INFORMACIÓN INICIAL Y AISLAMIENTO DE LA ESCENA:
Se tomó conocimiento del hecho por intermedio de: [escena.fuente_conocimiento].
Al llegar al lugar se constató lo siguiente: [narrativa.hechos_escena_llegada].
De inmediato se procedió a efectuar el acordonamiento y aislamiento de la escena utilizando [escena.metodo_aislamiento], con la finalidad de mantener su intangibilidad y evitar la alteracin de indicios.

II. PRESENCIA DE PERSONAS EN EL LUGAR:
Se identificó en las inmediaciones a las siguientes personas: [escena.personas_presentes]. Se dispuso su alejamiento de la zona.

IV. ENTREGA DE LA ESCENA:
Se mantuvo inalterable el lugar hasta las [tiempo.acta_hora_cierre] horas, momento en que se hace entrega física de la escena protegida al personal de [escena.personal_especializado_receptor].

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP (Primer Respondiente)       RECEPCIONA LA ESCENA
[instructor.grado_nombres]                    [receptor.grado_nombres]
CIP N° [instructor.cip]                       CIP N° [receptor.cip]
''';

  static const String actaLevantamientoCadaver = '''
ACTA DE LEVANTAMIENTO DE CADÁVER

A. FISCALÍA DE TURNO QUE AUTORIZA LA DILIGENCIA:
[fiscal.fiscalia] [5]
B. NOMBRE Y APELLIDO DEL FISCAL DE TURNO:
[fiscal.grado_nombres] [5]

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del día [tiempo.fecha_hecho], el instructor PNP [instructor.grado_nombres], conjuntamente con el Médico Legista Dr.(a) [medico.nombres_apellidos], y los peritos de criminalística, nos constituimos físicamente a [acta.lugar_redaccion], con la finalidad de realizar la presente diligencia de Levantamiento de Cadáver [5]:

C. INFORMACIÓN DEL OCCISO:
1. Nombres y apellidos del occiso: [occiso.nombres_apellidos]
2. Edad aproximada: [occiso.edad]
3. Documento de identidad (si hubiera): [occiso.dni]
4. Detalle de las pertenencias: [occiso.pertenencias] [5]

D. DEL LUGAR DE LOS HECHOS Y DESCRIPCIÓN DEL CADÁVER:
Posición del Cadáver: [occiso.posicion_cadaver] [5]
Ubicación del Cadáver (Referencia exacta): [occiso.ubicacion_exacta] [5]
Descripción de vestimenta (color, estado, prenda), señas particulares (tatuajes, cicatrices), raza, estatura y peso aproximado:
[occiso.descripcion_fisica_ropa] [5]

Describa signos de violencia en el occiso (heridas, contusiones, orificios, sangre en la escena) según lo señalado preliminarmente por el perito/médico:
[occiso.signos_violencia] [5]

E. RECOJO DE EVIDENCIAS Y REGISTRO PERSONAL (Art. 210° CPP):
En el registro personal al cadáver se encontró en sus prendas: [registro.bienes_hallados] [5].
Indicios en la escena (Vestigios, armas, casquillos, objetos contundentes vinculados al occiso): [escena.evidencias_halladas] [2].

F. DIAGNÓSTICO PRESUNTIVO DE MUERTE:
Causa básica y causa final (A determinar): [medico.diagnostico_presuntivo] [2]
Tiempo aproximado de muerte (Data): [medico.data_muerte] [2]

G. JUSTIFICACIÓN DEL REQUERIMIENTO Y TRASLADO (Art. 196° NCPP):
En cumplimiento de la normativa procesal, se ordena el levantamiento del cadáver y se dispone su traslado por parte de [occiso.medio_traslado], hacia la Morgue de [occiso.lugar_morgue], para la correspondiente necropsia de Ley y/o plena identificación [2].

--- Siendo las [tiempo.acta_hora_cierre] horas del mismo día, se da por concluida la diligencia, firmando los intervinientes.

(LADO IZQUIERDO)             (CENTRO)                     (LADO DERECHO)
EL INSTRUCTOR PNP            MÉDICO LEGISTA               EL FISCAL DE TURNO
[instructor.grado_nombres]   [medico.nombres_apellidos]   [fiscal.grado_nombres]
CIP N° [instructor.cip]      CMP N° [medico.cmp]          [fiscal.fiscalia] [2]
''';

  // ===========================================================================
  // BLOQUE 2: BSQUEDA DE PRUEBAS E INCAUTACIÓN
  // ===========================================================================

  static const String actaRegistroPersonal = '''
ACTA DE REGISTRO PERSONAL E INCAUTACIÓN

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], identificado con CIP N° [instructor.cip], procede a realizar la presente diligencia:

I. DATOS DEL INTERVENIDO:
Nombres y Apellidos: [imputado.nombres_apellidos]
DNI / Documento de Identidad: [imputado.dni]
Edad: [imputado.edad] aos | Estado Civil: [imputado.estado_civil]
Ocupacin: [imputado.ocupacion] | Domicilio: [imputado.domicilio]

II. DEL REGISTRO E INCAUTACIÓN:
Previa informacin del motivo de la intervencin, y en estricto cumplimiento del Artculo 210° del Cdigo Procesal Penal, se procedió a efectuar el registro personal del intervenido, obteniendo el siguiente resultado fáctico:
[registro.bienes_hallados]

Los bienes descritos son INCAUTADOS para su perennización, cadena de custodia y remisión a la unidad especializada o laboratorio.

--- Leída la presente acta, se da por concluida la diligencia a las [tiempo.acta_hora_cierre] horas. 

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL INTERVENIDO
[instructor.grado_nombres]                    [imputado.nombres_apellidos]
CIP N° [instructor.cip]                       DNI N° [imputado.dni]
''';

  static const String actaRegistroVehiculo = '''
ACTA DE REGISTRO VEHICULAR E INCAUTACIÓN

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], interviene el siguiente vehculo automotor:

I. DATOS DEL VEHÍCULO:
Placa de Rodaje: [vehiculo.placa] | Clase: [vehiculo.clase]
Marca: [vehiculo.marca] | Modelo: [vehiculo.modelo] | Color: [vehiculo.color]
N° Motor: [vehiculo.motor] | N° Serie/VIN: [vehiculo.vin]

II. IDENTIFICACIN DEL CONDUCTOR Y OCUPANTES:
Conductor: [conductor.nombres_apellidos] | DNI: [conductor.dni]
Ocupantes intervenidos: [vehiculo.lista_ocupantes]

III. DEL REGISTRO E INCAUTACIÓN:
Se procedió a efectuar el registro vehicular in situ, obteniendo el siguiente resultado fáctico:
[registro.bienes_hallados_vehiculo]
Los bienes descritos quedan INCAUTADOS para su remisión al laboratorio.

--- Se da por concluida la diligencia a las [tiempo.acta_hora_cierre] horas.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL CONDUCTOR / INTERVENIDO
[instructor.grado_nombres]                    [conductor.nombres_apellidos]
CIP N° [instructor.cip]                       DNI N° [conductor.dni]
''';

  static const String actaSituacionVehicular = '''
ACTA DE SITUACIÓN VEHICULAR

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del da [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], procede a levantar el presente inventario de conservación del vehculo:

I. CARACTERÍSTICAS TÉCNICAS:
Placa: [vehiculo.placa] | Marca: [vehiculo.marca] | Modelo: [vehiculo.modelo]
Ao de fab.: [vehiculo.anio] | Color: [vehiculo.color] 
Motor: [vehiculo.motor] | Chasis/VIN: [vehiculo.vin]

II. ESTADO DE CONSERVACIÓN:
Lunas y Parabrisas: [vehiculo.estado_lunas]
Espejos retrovisores: [vehiculo.estado_espejos]
Faros y luces: [vehiculo.estado_faros]
Llantas y aros: [vehiculo.estado_llantas]
Sistema de Radio/Audio: [vehiculo.estado_radio]
Tablero e Instrumentos: [vehiculo.estado_interiores]
Accesorios adicionales: [vehiculo.accesorios_adicionales]

III. OBSERVACIONES DE DAOS O FALTANTES:
[vehiculo.observaciones_danos]

--- Siendo las [tiempo.acta_hora_cierre] horas, se da por concluida la verificacin, firmando en conformidad.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             PROPIETARIO / CONDUCTOR
[instructor.grado_nombres]                    [conductor.nombres_apellidos]
CIP N° [instructor.cip]                       DNI N° [conductor.dni]
''';

  static const String actaAllanamiento = '''
ACTA DE REGISTRO DOMICILIARIO E INCAUTACIÓN

--- En [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del da [tiempo.fecha_hecho], en el inmueble ubicado en: [inmueble.direccion_exacta], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], procede a efectuar la diligencia.

I. CAUSAL DE EXCEPCIÓN A LA INVIOLABILIDAD DE DOMICILIO:
Se realiza el ingreso amparados en el Art. 214° y 259° del Cdigo Procesal Penal, por la siguiente causal fáctica y de urgencia: [inmueble.causal_ingreso].

II. IDENTIFICACIN DEL POSESIONARIO:
Se constató la presencia de: [inmueble.persona_presente_nombres], DNI N° [inmueble.persona_presente_dni].

III. DESARROLLO DEL REGISTRO E INCAUTACIÓN:
Se procedió al registro de los ambientes, obteniendo:
[registro.bienes_hallados_inmueble]
Dichas evidencias quedan INCAUTADAS.

--- Finalizada a las [tiempo.acta_hora_cierre] horas. 

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL POSESIONARIO
[instructor.grado_nombres]                    [inmueble.persona_presente_nombres]
''';

  static const String actaHallazgoRecojo = '''
ACTA DE HALLAZGO Y RECOJO

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del da [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], formula la presente diligencia:

I. CIRCUNSTANCIAS DEL HALLAZGO:
[narrativa.hechos_hallazgo]

II. DESCRIPCIÓN Y RECOJO DE ESPECIES:
Se procedió al aislamiento y recojo de lo siguiente:
[registro.bienes_hallados]
Las especies son perennizadas para el inicio de la cadena de custodia.

--- Siendo las [tiempo.acta_hora_cierre] horas, se da por concluida la diligencia.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             TESTIGO (Si lo hubiera)
[instructor.grado_nombres]                    [testigo.nombres_apellidos]
''';

  static const String actaRecepcion = '''
ACTA DE ENTREGA Y RECEPCIN

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del da [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], formula la presente:

I. IDENTIFICACIN DE LA PERSONA QUE ENTREGA:
Nombres y Apellidos: [entregante.nombres_apellidos]
DNI: [entregante.dni] | Domicilio: [entregante.domicilio]
Condicin: [entregante.condicion]

II. MOTIVO Y DESCRIPCIÓN DE LA RECEPCIN:
La persona hace entrega voluntaria de lo siguiente:
[registro.bienes_recepcionados]
Motivo de la entrega: [narrativa.hechos_recepcion]

III. ESTADO DE CONSERVACIÓN:
Estado fsico: [registro.estado_conservacion_recepcion].

--- Siendo las [tiempo.acta_hora_cierre] horas, se da por concluida la diligencia.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             LA PERSONA QUE ENTREGA
[instructor.grado_nombres]                    [entregante.nombres_apellidos]
''';

  // ===========================================================================
  // BLOQUE 3: CADENA DE CUSTODIA Y FORMATOS DE IDENTIFICACIN
  // ===========================================================================

  static const String actaLacrado = '''
ACTA DE LACRADO DE EVIDENCIAS / ESPECIES

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del da [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], procede al lacrado de evidencias:

I. IDENTIFICACIN DE LA EVIDENCIA A LACRAR:
Procedente de la intervencin, se asegura el siguiente elemento material:
Hallazgo N° [bien.numero_hallazgo]: [bien.cantidad] [bien.unidadMedida] - [bien.descripcion]

II. TIPO DE EMBALAJE Y ROTULADO:
La evidencia es introducida en [lacrado.tipo_envase], sellado con [lacrado.tipo_cinta]. 
Queda debidamente LACRADO e inalterable, siéndole adherido el Rótulo Formato A-6 del Ministerio Pblico. 

III. CONSTANCIA DE FIRMA Y CONFORMIDAD:
Las firmas se estamparon cruzando los bordes de la cinta de seguridad (lacre), garantizando que su contenido no sufra apertura.
--- Siendo las [tiempo.acta_hora_cierre] horas, se concluye la diligencia.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL INTERVENIDO / TESTIGO
[instructor.grado_nombres]                    [imputado.nombres_apellidos]
''';

  static const String rotuloA6 = '''
MINISTERIO PBLICO - FISCALÍA DE LA NACIÓN
FORMATO A - 6
RÓTULO DE INDICIOS / EVIDENCIAS / ELEMENTOS RECOGIDOS
(EN CADENA DE CUSTODIA)

NÚMERO DE HALLAZGO: [bien.numero_hallazgo]
CANTIDAD: [bien.cantidad]     UNIDAD DE MEDIDA: [bien.unidadMedida]
DESCRIPCIÓN DEL BIEN: [bien.descripcion]

SERVIDOR QUE RECOLECTA EL BIEN:
NOMBRE COMPLETO: [instructor.grado_nombres]
DNI / CIP Nº: [instructor.cip]
CARGO: INSTRUCTOR PNP
FIRMA: ____________________________________

FECHA DE EMBALAJE: [tiempo.fecha_hecho]
HORA (0-24): [tiempo.acta_hora_cierre]
''';

  static const String hojaIdentificacion = '''
[unidad.nombre]

HOJA DE DATOS DE IDENTIFICACIN N° [documento.numero_correlativo] - [unidad.siglas]

APELLIDOS                 : [imputado.apellidos]
NOMBRES                   : [imputado.nombres]
EDAD                      : [imputado.edad]
NACIONALIDAD              : [imputado.nacionalidad]
PROFESIÓN U OCUPACIN     : [imputado.ocupacion]
DNI – PASAPORTE U OTROS   : [imputado.dni]
DIRECCIÓN DOMICILIARIA    : [imputado.domicilio]
MOTIVO DE LA INTERVENCIN : [intervencion.motivo]
DOCUMENTO REDACTADO       : [intervencion.documento_redactado]
SEÑAS PARTICULARES        : [imputado.senas_particulares]

[lugar.distrito], [tiempo.fecha_hecho]

INSTRUCTOR PNP
[instructor.grado_nombres]
CIP N° [instructor.cip]
''';

  static const String hojaRequisitoria = '''
[unidad.nombre]

HOJA BÁSICA DE REQUISITORIA Nº [documento.numero_correlativo] - [unidad.siglas]

1. DATOS PERSONALES:
Apellidos y Nombres : [imputado.apellidos] [imputado.nombres]
Fecha de Nacimiento : [imputado.fecha_nacimiento] | Lugar: [imputado.lugar_nacimiento]
DNI (Pasaporte u otros) Nº: [imputado.dni]
Hijo de             : [imputado.nombre_padre] y de [imputado.nombre_madre]
Grado de Instruccin: [imputado.grado_instruccion]
Domicilio           : [imputado.domicilio]

2. CARACTERÍSTICAS FSICAS:
[imputado.caracteristicas_fisicas]

Lugar y Fecha: [lugar.distrito], [tiempo.fecha_hecho]

ES CONFORME
EL INSTRUCTOR PNP
[instructor.grado_nombres]
CIP N° [instructor.cip]
''';

  // ===========================================================================
  // BLOQUE 4: GARANTÍAS PROCESALES Y TESTIMONIOS
  // ===========================================================================

  static const String actaDetencion = '''
ACTA DE DETENCIÓN Y LECTURA DE DERECHOS DEL IMPUTADO

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], notifica a:

[imputado.nombres_apellidos], de [imputado.edad] aos, identificado con DNI N° [imputado.dni], domiciliado en [imputado.domicilio].

Se le notifica que se encuentra DETENIDO(A) en flagrante delito (Art. 259° CPP), por la presunta comisin del delito de: [intervencion.tipificacion].
Motivo de la detencin: [narrativa.hechos]

DERECHOS DEL DETENIDO (Art. 71.2 CPP):
1. Conocer los cargos formulados en su contra y el motivo de su detencin.
2. Designar a la persona o institución a la que debe comunicarse su detencin.
3. Ser asistido desde los actos iniciales de investigación por un Abogado Defensor.
4. Abstenerse de declarar; y si acepta hacerlo, que su Abogado esté presente.
5. Que no se empleen en su contra medios coactivos.
6. Ser examinado por un mdico legista.

El detenido solicita comunicar a: [detenido.persona_notificar], Tel: [detenido.telefono_notificar].
Solicita abogado: [detenido.abogado_solicitado].

--- Siendo las [tiempo.acta_hora_cierre] horas, se da por concluida la presente.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL DETENIDO
[instructor.grado_nombres]                    [imputado.nombres_apellidos]
''';

  static const String actaManifestacion = '''
ACTA DE MANIFESTACIÓN

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del [tiempo.fecha_hecho], presente el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], con la participación del Fiscal [fiscal.grado_nombres] y del abogado [abogado.nombres], Reg. CAL N° [abogado.colegiatura]; se procede a tomar manifestacin de:

[persona.nombres_apellidos], de [persona.edad] aos, DNI N° [persona.dni], ocupación [persona.ocupacion], en calidad de [persona.condicion].

PREGUNTA 01: ¿Diga si requiere el asesoramiento de un abogado defensor de su libre eleccin?
RESPUESTA 01: [manifestacion.respuesta_abogado]

PREGUNTA 02: ¿Detalle las circunstancias de los hechos materia de investigación?
RESPUESTA 02: [manifestacion.relato_hechos]

[manifestacion.preguntas_dinamicas]

PREGUNTA FINAL: ¿Tiene algo más que agregar o modificar?
RESPUESTA FINAL: [manifestacion.respuesta_final]

--- Leída la presente, se ratifica en su contenido total, concluyendo a las [tiempo.acta_hora_cierre] horas.

(LADO IZQ)                 (CENTRO)                   (LADO DER)
EL INSTRUCTOR PNP          EL FISCAL                  EL MANIFESTANTE
[instructor.grado_nombres] [fiscal.grado_nombres]     [persona.nombres_apellidos]

EL ABOGADO DEFENSOR
[abogado.nombres]
''';

  static const String actaReconocimiento = '''
ACTA DE RECONOCIMIENTO FSICO EN RUEDA DE PERSONAS

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del da [tiempo.fecha_hecho], presente el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], con participación obligatoria del Fiscal [fiscal.grado_nombres], y el Abogado Defensor [abogado.nombres] CAL N° [abogado.colegiatura]; se realiza Reconocimiento Físico solicitado por: [agraviado.nombres_apellidos], DNI N° [agraviado.dni].

I. PREPARACIÓN DE LA DILIGENCIA:
Se presenta al reconocedor la rueda conformada por: [reconocimiento.lista_rueda_personas].

II. DESARROLLO Y RESULTADO DEL RECONOCIMIENTO:
Habiéndosele preguntado si reconoce al presunto autor, manifestó lo siguiente:
Resultados: [reconocimiento.resultados].

--- Siendo las [tiempo.acta_hora_cierre] horas, se da por concluida la diligencia.

(LADO IZQ)                 (CENTRO)                   (LADO DER)
EL INSTRUCTOR PNP          EL FISCAL                  EL RECONOCEDOR
[instructor.grado_nombres] [fiscal.grado_nombres]     [agraviado.nombres_apellidos]
''';

  static const String cartillaDerechos = '''
CARTILLA DE DERECHOS DE LA VCTIMA / AGRAVIADO
(Art. 95° y 104° del Nuevo Cdigo Procesal Penal)

--- En [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del [tiempo.fecha_hecho], el instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], pone en conocimiento de la vctima/agraviado(a):
[agraviado.nombres_apellidos], identificado(a) con DNI N° [agraviado.dni], sus derechos fundamentales:

1. A recibir un trato digno y respetuoso.
2. A que los actos de investigación sean iniciados.
3. A ser evaluada clínicamente (Reconocimiento Mdico Legal).
4. A rendir su declaración con abogado de libre eleccin.
5. A ser informado de los resultados y restitución de bienes.
6. A impugnar el archivo de la investigación.

Solicitud adicional: [agraviado.solicitudes_adicionales]

--- Siendo las [tiempo.acta_hora_cierre] horas, previa lectura, firma e imprime su huella.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             LA VCTIMA / AGRAVIADO
[instructor.grado_nombres]                    [agraviado.nombres_apellidos]
''';

  static const String constanciaBuenTrato = '''
CONSTANCIA DE BUEN TRATO
(Protocolo de Actuación Interinstitucional)

--- En la ciudad de [lugar.provincia], Distrito de [lugar.distrito], siendo las [tiempo.acta_hora_inicio] horas del día [tiempo.fecha_hecho], en [acta.lugar_redaccion], el instructor PNP [instructor.grado_nombres], identificado con CIP N° [instructor.cip], deja expresa constancia de lo siguiente:

Que, la persona intervenida/agraviada, plenamente identificada como:
Nombres y Apellidos: [imputado.nombres_apellidos]
DNI / Documento de Identidad: [imputado.dni]
Edad: [imputado.edad] años | Domicilio: [imputado.domicilio]

Manifiesta de forma libre, espontánea y voluntaria HABER RECIBIDO UN BUEN TRATO físico, psicológico y moral por parte del personal de la Policía Nacional del Perú durante el desarrollo de la presente intervención policial motivada por [intervencion.motivo]; dejando constancia que se han respetado irrestrictamente sus derechos fundamentales amparados por la Constitución Política del Estado, no habiendo sido objeto de ningún tipo de agresión, coacción, amenaza o trato denigrante.

--- Leído el presente documento, y en señal de plena conformidad, siendo las [tiempo.acta_hora_cierre] horas del mismo día, se da por concluida la diligencia, procediendo a firmar e imprimir su huella dactilar.
(Constancia de negativa a firmar, de ser el caso): [firma.motivo_negativa]

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL CIUDADANO / INTERVENIDO
[instructor.grado_nombres]                    [imputado.nombres_apellidos]
CIP N° [instructor.cip]                       DNI N° [imputado.dni]
''';

  // ===========================================================================
  // BLOQUE 5: DOCUMENTOS ADMINISTRATIVOS Y PARTES
  // ===========================================================================

  static const String partePolicial = '''
[unidad.nombre]

PARTE Nº [documento.numero_correlativo] - [unidad.siglas]

ASUNTO : Da cuenta de intervencin policial por la presunta comisin del delito de [intervencion.tipificacion], y [parte.asunto_breve].
REF.   : [parte.referencia]

I. ANTECEDENTES:
[parte.antecedentes] 

II. AMPLIACIÓN DETALLADA:
[parte.ampliacion_detallada] 

III. ACCIONES Y DISPOSICIONES ADOPTADAS:
- Se comunicó de inmediato a las [fiscal.hora_comunicacion] horas al Fiscal [fiscal.grado_nombres] de la [fiscal.fiscalia].
- [parte.acciones_adoptadas]

IV. SITUACIÓN DE PERSONAS, ESPECIES Y/O INSTRUMENTOS:
- Imputado(s): [imputado.situacion_legal]
- Especies: [registro.resumen_especies_incautadas]

V. RECOMENDACIONES:
Lo que se cumple en dar cuenta a la Superioridad.

VI. ANEXOS:
- [lista_actas_generadas]

[lugar.distrito], [tiempo.fecha_hecho]

EL INSTRUCTOR PNP
[instructor.grado_nombres]
CIP N° [instructor.cip]

ES CONFORME
EL COMISARIO / JEFE DE LA UNIDAD
[jefe_unidad.grado_nombres]
''';

  static const String oficioPetitorio = '''
[unidad.nombre]

OFICIO N° [documento.numero_correlativo] - [unidad.siglas]

SEOR      : JEFE DEL INSTITUTO DE MEDICINA LEGAL - [lugar.provincia]
ASUNTO     : Solicita Reconocimiento Mdico Legal (RML) y/o [oficio.tipo_examen].
REFERENCIA : Intervención por presunto delito de [intervencion.tipificacion].

Tengo el honor de dirigirme a Ud., a fin de solicitarle se practique el Reconocimiento Mdico Legal y el examen de [oficio.tipo_examen], a:

Nombres y Apellidos : [persona.nombres_apellidos]
Identificado con DNI: [persona.dni]
Edad                : [persona.edad] aos
Situacin Legal     : [persona.condicion]

El efectivo policial custodio, [custodio.grado_nombres], espera los resultados.

[lugar.distrito], [tiempo.fecha_hecho]

DIOS GUARDE A UD.

EL JEFE DE LA DEPENDENCIA
[jefe_unidad.grado_nombres]
''';

  static const String oficioDosajeEtilico = '''
[unidad.nombre]

OFICIO N° [documento.numero_correlativo] - [unidad.siglas]

SEOR      : [oficio.destinatario_sanidad]
ASUNTO     : Solicita Examen Químico Toxicológico (Dosaje Etlico).
REFERENCIA : Intervención por presunto delito de [intervencion.tipificacion].

Tengo el honor de dirigirme a Ud., a fin de solicitarle se practique con carácter de MUY URGENTE la extraccin de muestra biolgica (sangre) y examen de DOSAJE ETLICO, a:

Nombres y Apellidos : [persona.nombres_apellidos]
Identificado con DNI: [persona.dni]
Situacin Legal     : [persona.condicion]

Dicha prueba resulta indispensable para determinar la concentración de alcohol expresado en (g/L). 
Asimismo, solicito que se prevea la recoleccin, etiquetado y lacrado de la respectiva CONTRAMUESTRA de sangre, a fin de garantizar la cadena de custodia.

[lugar.distrito], [tiempo.fecha_hecho]

DIOS GUARDE A UD.

EL JEFE DE LA DEPENDENCIA / INSTRUCTOR PNP
[jefe_unidad.grado_nombres]
''';

  static const String citacionPolicial = '''
[unidad.nombre]

CITACIÓN POLICIAL N° [documento.numero_correlativo] - [unidad.siglas]

Se cita a: [citado.nombres_apellidos], DNI N° [citado.dni], con domicilio en [citado.domicilio].

Para que se apersone a esta Dependencia, ubicada en [unidad.direccion], el da [citacion.fecha_comparecencia] a las [citacion.hora_comparecencia] horas, para la diligencia de: [citacion.motivo_diligencia].

Diligencia en agravio de [agraviado.nombres_apellidos].
Debe concurrir portando su DNI y, si lo considera pertinente, con su Abogado Defensor. 

[lugar.distrito], [tiempo.fecha_hecho]

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL CITADO (Constancia de recepcin)
[instructor.grado_nombres]                    Recibí el: [tiempo.fecha_hecho]
''';

  static const String notificacionPolicial = '''
[unidad.nombre]

NOTIFICACIÓN POLICIAL N° [documento.numero_correlativo] - [unidad.siglas]

El instructor PNP [instructor.grado_nombres], CIP N° [instructor.cip], procede a NOTIFICAR a:
Nombres y Apellidos : [notificado.nombres_apellidos]
Identificado con DNI: [notificado.dni]
En su condicin de  : [notificado.condicion]

SOBRE LO SIGUIENTE:
[notificacion.cuerpo_mensaje]

Dejándose constancia de haber sido informado.

[lugar.distrito], [tiempo.fecha_hecho] a las [tiempo.acta_hora_cierre] horas.

(LADO IZQUIERDO)                              (LADO DERECHO)
EL INSTRUCTOR PNP                             EL NOTIFICADO
[instructor.grado_nombres]                    [notificado.nombres_apellidos]
''';

  // ===========================================================================
  // MOTOR DINÁMICO DE BSQUEDA DE PLANTILLAS (GET FALLBACK CONTENT)
  // ===========================================================================

  static String getFallbackContent(String title) {
    final clean = title.toLowerCase();

    // 1. Actas Matrices y de Escena
    if (clean.contains('acta de intervencin') ||
        clean.contains('intervencin policial') ||
        clean.contains('intervencion')) {
      return actaIntervencion;
    }
    if (clean.contains('escena') ||
        clean.contains('llegada al lugar') ||
        clean.contains('primer respondiente') ||
        clean.contains('aislamiento')) {
      return actaLlegadaEscena;
    }
    if (clean.contains('levantamiento de cadáver') || 
        clean.contains('cadaver') || 
        clean.contains('occiso')) {
      return actaLevantamientoCadaver;
    }

    // 2. Actas de Búsqueda y Registro
    if (clean.contains('registro personal')) return actaRegistroPersonal;
    if (clean.contains('registro de vehculo') ||
        clean.contains('registro vehicular') ||
        clean.contains('vehicular e incautación')) {
      return actaRegistroVehiculo;
    }
    if (clean.contains('situacin vehicular') ||
        clean.contains('situacion vehicular') ||
        clean.contains('inventario')) {
      return actaSituacionVehicular;
    }
    if (clean.contains('allanamiento') || clean.contains('domiciliario')) {
      return actaAllanamiento;
    }
    if (clean.contains('hallazgo')) return actaHallazgoRecojo;
    if (clean.contains('recepcin') ||
        clean.contains('recepcion') ||
        clean.contains('entrega')) {
      return actaRecepcion;
    }

    // 3. Cadena de Custodia e Identificación
    if (clean.contains('lacrado') || clean.contains('embalaje')) {
      return actaLacrado;
    }
    if (clean.contains('rótulo') ||
        clean.contains('rotulo') ||
        clean.contains('formato a-6') ||
        clean.contains('a-6')) {
      return rotuloA6;
    }
    if (clean.contains('hoja de datos') ||
        clean.contains('identificación') ||
        clean.contains('identificacion') ||
        clean.contains('formato 38')) {
      return hojaIdentificacion;
    }
    if (clean.contains('requisitoria') ||
        clean.contains('requisitorias') ||
        clean.contains('formato 37')) {
      return hojaRequisitoria;
    }

    // 4. Garantas y Testimonios
    if (clean.contains('detencin') ||
        clean.contains('detencion') ||
        clean.contains('derechos del imputado')) {
      return actaDetencion;
    }
    if (clean.contains('manifestacin') ||
        clean.contains('manifestacion') ||
        clean.contains('declaración')) {
      return actaManifestacion;
    }
    if (clean.contains('reconocimiento fsico') || clean.contains('rueda')) {
      return actaReconocimiento;
    }
    if (clean.contains('cartilla') ||
        clean.contains('derechos de la vctima') ||
        clean.contains('agraviado')) {
      return cartillaDerechos;
    }
    if (clean.contains('buen trato') || clean.contains('constancia de buen')) {
      return constanciaBuenTrato;
    }

    // 5. Documentos Administrativos
    if (clean.contains('parte policial') ||
        clean.contains('formato 61') ||
        clean.contains('parte nº')) {
      return partePolicial;
    }
    if (clean.contains('dosaje etílico') || clean.contains('alcoholemia')) {
      return oficioDosajeEtilico;
    }
    if (clean.contains('oficio petitorio') ||
        clean.contains('medicina legal') ||
        clean.contains('oficio')) {
      return oficioPetitorio;
    }
    if (clean.contains('citación') || clean.contains('citacion')) {
      return citacionPolicial;
    }
    if (clean.contains('notificacin') || clean.contains('notificacion')) {
      return notificacionPolicial;
    }

    // Alerta de escape si el documento no es detectado
    return 'Documento autogenerado o sin plantilla local estricta configurada en el motor.\nUtilice el Gestor de Plantillas Avanzado para editar su contenido visual o presione el botón "LLENAR FORMULARIO CENTRAL" para inyectar la narrativa procesal.';
  }
}
