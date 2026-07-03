import 'typification.dart';

class TypificationRepository {

  static const List<Typification> all = [

    Typification(

      id: 'robo_agravado',

      name: 'Robo Agravado / Hurto Agravado (Flagrancia)',

      logic: 'Delitos contra el patrimonio con uso de violencia o amenaza.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Recepción',

        'Cartilla de Derechos',

        'Oficio Petitorio',

      ],

    ),

    Typification(

      id: 'tid_microcomercializacion',

      name: 'Tráfico Ilícito de Drogas (Microcomercialización / Posesión)',

      logic: 'Posesión y comercialización de drogas.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Rótulo de Evidencias (Formato A-6)',

        'Hoja de Datos de Identificación (Formato 38)',

      ],

    ),

    Typification(

      id: 'peligro_comun',

      name: 'Peligro Común (Conducción en Estado de Ebriedad)',

      logic: 'Conducción de vehículo en estado de ebriedad.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro de Vehículo e Incautación',

        'Acta de Situación Vehicular',

        'Acta de Detención y Lectura de Derechos',

        'Oficio para Dosaje Etílico',

      ],

    ),

    Typification(

      id: 'tenencia_armas',

      name: 'Tenencia Ilegal de Armas de Fuego / Municiones',

      logic: 'Posesión no autorizada de armas de fuego.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Rótulo de Evidencias (Formato A-6)',

      ],

    ),

    Typification(

      id: 'violencia_mujer_grupo_familiar',

      name: 'Violencia contra la Mujer e Integrantes del Grupo Familiar (Ley 30364)',

      logic: 'Casos de violencia familiar amparados por la Ley 30364.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Detención y Lectura de Derechos',

        'Constancia de Buen Trato',

        'Cartilla de Derechos',

        'Oficio Petitorio',

      ],

    ),

    Typification(

      id: 'captura_requisitoria',

      name: 'Captura por Requisitoria (Orden Judicial Vigente)',

      logic: 'Detención por orden de captura judicial.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Hoja Básica de Requisitoria (Formato 37)',

        'Oficio Petitorio',

      ],

    ),

    Typification(

      id: 'homicidio_sicariato',

      name: 'Homicidio / Sicariato / Feminicidio (Primer Respondiente)',

      logic: 'Actuación como primer respondiente en delitos contra la vida.',

      recommendedTemplateNames: [

        'Acta de Llegada a la Escena del Delito',

        'Acta de Intervención',

        'Acta de Levantamiento de Cadáver',

        'Acta de Hallazgo y Recojo',

        'Acta de Lacrado',

      ],

    ),

    Typification(

      id: 'receptacion',

      name: 'Receptación (Posesión de equipos celulares o bienes robados)',

      logic: 'Posesión de bienes de procedencia ilícita.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Rótulo de Evidencias (Formato A-6)',

      ],

    ),

    Typification(

      id: 'extorsion',

      name: 'Extorsión (Cobro de cupos / Flagrancia)',

      logic: 'Intervención en flagrancia por extorsión.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Cartilla de Derechos',

      ],

    ),

    Typification(

      id: 'lesiones',

      name: 'Lesiones (Graves o Leves por riña callejera)',

      logic: 'Lesiones físicas producto de altercados.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Registro Personal e Incautación',

        'Oficio Petitorio',

        'Cartilla de Derechos',

      ],

    ),

    Typification(

      id: 'delitos_libertad_sexual',

      name: 'Delitos contra la Libertad Sexual (Violación / Tocamientos)',

      logic: 'Atentados contra la libertad sexual.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Oficio Petitorio',

        'Cartilla de Derechos',

      ],

    ),

    Typification(

      id: 'contrabando_receptacion_aduanera',

      name: 'Contrabando / Receptación Aduanera',

      logic: 'Ingreso o posesión ilegal de mercadería extranjera.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro de Vehículo e Incautación',

        'Acta de Situación Vehicular',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

      ],

    ),

    Typification(

      id: 'falsificacion_moneda',

      name: 'Falsificación de Moneda (Billetes / Monedas Falsas)',

      logic: 'Posesión o circulación de moneda falsa.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Rótulo de Evidencias (Formato A-6)',

      ],

    ),

    Typification(

      id: 'usurpacion_agravada',

      name: 'Usurpación Agravada (Invasión de Terrenos/Propiedad)',

      logic: 'Toma o invasión de propiedad ajena.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Registro Personal e Incautación',

        'Acta de Reconocimiento',

        'Cartilla de Derechos',

      ],

    ),

    Typification(

      id: 'secuestro',

      name: 'Secuestro (Rescate en inmueble)',

      logic: 'Privación de la libertad y rescate.',

      recommendedTemplateNames: [

        'Acta de Llegada a la Escena del Delito',

        'Acta de Allanamiento y Registro',

        'Acta de Intervención',

        'Acta de Detención y Lectura de Derechos',

        'Oficio Petitorio',

      ],

    ),

    Typification(

      id: 'falsedad_generica',

      name: 'Falsedad Genérica / Uso de Documento Falso',

      logic: 'Uso de documentos falsos o adulterados.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Rótulo de Evidencias (Formato A-6)',

      ],

    ),

    Typification(

      id: 'delitos_ambientales',

      name: 'Delitos Ambientales (Minería Ilegal / Tala Ilegal)',

      logic: 'Actividades extractivas ilegales.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro de Vehículo e Incautación',

        'Acta de Hallazgo y Recojo',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

      ],

    ),

    Typification(

      id: 'cohecho_activo',

      name: 'Cohecho Activo (Soborno a Efectivo Policial)',

      logic: 'Ofrecimiento de ventajas indebidas a funcionario público.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Registro Personal e Incautación',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Lacrado',

        'Rótulo de Evidencias (Formato A-6)',

      ],

    ),

    Typification(

      id: 'resistencia_autoridad',

      name: 'Resistencia o Desobediencia a la Autoridad',

      logic: 'Oposición física o desobediencia al personal policial.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Detención y Lectura de Derechos',

        'Acta de Registro Personal e Incautación',

        'Oficio Petitorio',

        'Parte Policial',

      ],

    ),

    Typification(

      id: 'hallazgo_vehiculo',

      name: 'Hallazgo de Vehículo Robado (Sin Detenidos - Abandono)',

      logic: 'Recuperación de vehículo reportado robado.',

      recommendedTemplateNames: [

        'Acta de Intervención',

        'Acta de Hallazgo y Recojo',

        'Acta de Situación Vehicular',

        'Acta de Lacrado',

        'Parte Policial',

      ],

    ),


    Typification(
      id: 'trata_personas',
      name: 'Trata de Personas (Fines de Explotación Sexual o Laboral)',
      logic: 'Explotación y retención de víctimas.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro Domiciliario',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Lacrado',
        'Cartilla de Derechos',
      ],
    ),
    Typification(
      id: 'marcaje_reglaje',
      name: 'Marcaje o Reglaje (Art. 317-A del Código Penal)',
      logic: 'Seguimiento y acopio de información para cometer delitos.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro de Vehículo e Incautación',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Lacrado',
        'Rótulo de Evidencias (Formato A-6)',
      ],
    ),
    Typification(
      id: 'estafa',
      name: 'Estafa y Otras Defraudaciones ("La Cascada", "Lotería", "Pepita de Oro")',
      logic: 'Defraudación mediante engaño y astucia.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Recepción',
        'Acta de Lacrado',
      ],
    ),
    Typification(
      id: 'hurto_autopartes',
      name: 'Hurto Agravado de Autopartes (Desmantelamiento en Vía Pública)',
      logic: 'Sustracción de piezas vehiculares.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Situación Vehicular',
        'Acta de Lacrado',
      ],
    ),
    Typification(
      id: 'fuga_accidente',
      name: 'Fuga del Lugar de Accidente de Tránsito (Omisión de Socorro)',
      logic: 'Abandono del lugar tras atropello o choque.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro de Vehículo e Incautación',
        'Acta de Situación Vehicular',
        'Acta de Detención y Lectura de Derechos',
        'Oficio Petitorio',
      ],
    ),
    Typification(
      id: 'salud_publica',
      name: 'Delitos Contra la Salud Pública (Medicamentos Adulterados/Vencidos)',
      logic: 'Comercialización de medicamentos ilícitos.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Lacrado',
        'Rótulo de Evidencias (Formato A-6)',
      ],
    ),
    Typification(
      id: 'derechos_intelectuales',
      name: 'Delitos Contra los Derechos Intelectuales (Piratería Industrial)',
      logic: 'Producción y venta de mercadería falsificada.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Lacrado',
        'Acta de Hallazgo y Recojo',
      ],
    ),
    Typification(
      id: 'maltrato_animal',
      name: 'Actos de Crueldad y Maltrato Animal (Flagrancia)',
      logic: 'Crueldad extrema hacia animales.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Hallazgo y Recojo',
        'Acta de Lacrado',
      ],
    ),
    Typification(
      id: 'danos_agravados',
      name: 'Daños Agravados (Vandalismo a Propiedad)',
      logic: 'Destrucción intencional de propiedad ajena.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro Personal e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Acta de Lacrado',
        'Cartilla de Derechos',
      ],
    ),
    Typification(
      id: 'trafico_migrantes',
      name: 'Tráfico Ilícito de Migrantes (Coyotaje)',
      logic: 'Traslado ilegal de ciudadanos extranjeros.',
      recommendedTemplateNames: [
        'Acta de Intervención',
        'Acta de Registro de Vehículo e Incautación',
        'Acta de Detención y Lectura de Derechos',
        'Cartilla de Derechos',
        'Acta de Lacrado',
      ],
    ),

  ];

}
