import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  // ─── CONFIGURACIÓN DE PÁGINAS Y FOLIACIÓN DOCTRINAL PNP ───────────────────
  static const _pnpPageFormat = PdfPageFormat.a4;
  static const _pnpPageMargin = pw.EdgeInsets.only(
    left: 3.5 * PdfPageFormat.cm,
    right: 2.0 * PdfPageFormat.cm,
    top: 2.5 * PdfPageFormat.cm,
    bottom: 2.5 * PdfPageFormat.cm,
  );

  static pw.PageTheme _getPnpPageTheme() {
    return pw.PageTheme(
      pageFormat: _pnpPageFormat,
      margin: _pnpPageMargin,
    );
  }

  static pw.Widget Function(pw.Context) _buildFoliationHeader(int initialFolio) {
    return (pw.Context context) {
      return pw.Align(
        alignment: pw.Alignment.topRight,
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            'Folio ${(initialFolio + context.pageNumber - 1).toString().padLeft(2, '0')}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );
    };
  }
  
  static pw.Widget Function(pw.Context) _buildFooter(String text) {
    return (pw.Context context) {
      return pw.Align(
        alignment: pw.Alignment.bottomCenter,
        child: pw.Text(
          text,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    };
  }

  static pw.Widget _wrapWithFoliation(pw.Context context, pw.Widget child, bool includeFoliation, int initialFolio) {
    if (!includeFoliation) return child;
    return pw.Stack(
      children: [
        child,
        pw.Positioned(
          right: 0,
          top: 0,
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Text(
              'Folio ${(initialFolio + context.pageNumber - 1).toString().padLeft(2, '0')}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Método unificado para añadir cualquier acta por su título
  static Future<void> appendDocumentPages(
    pw.Document pdf,
    String title,
    Map<String, String> tags, {
    String tipificacion = '',
    List<String> docTitles = const [],
    bool includeFoliation = false,
    int initialFolio = 1,
    String? piePagina,
  }) async {
    final cleanTitle = title.toLowerCase();
    if (cleanTitle.contains('manifestación') || cleanTitle.contains('manifestacion')) {
      await addManifestacionPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('detención') || cleanTitle.contains('detencion')) {
      await addDetencionPages(pdf, tags, tipificacion, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('registro personal')) {
      await addRegistroPersonalPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('hallazgo')) {
      await addHallazgoRecojoPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('lacrado')) {
      await addLacradoPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('registro de vehículo') || cleanTitle.contains('registro vehicular') || cleanTitle.contains('registro de vehiculo')) {
      await addRegistroVehicularPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('vehicular') || cleanTitle.contains('situación vehicular')) {
      await addSituacionVehicularPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('domiciliario') || cleanTitle.contains('allanamiento')) {
      await addRegistroDomiciliarioPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('escena')) {
      await addLlegadaEscenaPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('reconocimiento')) {
      await addReconocimientoFisicoPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('recepción') || cleanTitle.contains('recepcion') || cleanTitle.contains('entrega')) {
      await addActaRecepcionPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('identificación') || cleanTitle.contains('hoja de datos') || cleanTitle.contains('identificacion')) {
      await addHojaIdentificacionPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('requisitoria') || cleanTitle.contains('hoja básica de requisitoria')) {
      await addHojaRequisitoriaPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('rótulo') || cleanTitle.contains('rotulo') || cleanTitle.contains('formato a-6') || cleanTitle.contains('a-6')) {
      await addRotuloA6Pages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('acta de intervención') || cleanTitle.contains('intervención policial') || cleanTitle.contains('intervencion')) {
      await addActaIntervencionPages(pdf, tags, tipificacion, docTitles, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('parte policial')) {
      await addPartePolicialPages(pdf, tags, tipificacion, docTitles, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('oficio petitorio')) {
      await addOficioPetitorioPages(pdf, tags, tipificacion, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('citación') || cleanTitle.contains('citacion')) {
      await addCitacionPolicialPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('notificación') || cleanTitle.contains('notificacion')) {
      await addNotificacionPolicialPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else if (cleanTitle.contains('derechos') || cleanTitle.contains('víctima') || cleanTitle.contains('victima')) {
      await addDerechosVictimaPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    } else {
      // Fallback genérico
      await addManifestacionPages(pdf, tags, includeFoliation: includeFoliation, initialFolio: initialFolio, piePagina: piePagina);
    }
  }

  
  static Future<void> addManifestacionPages(pw.Document pdf, Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          final titleText =
              'ACTA DE MANIFESTACIÓN QUE RINDE EL/LA INTERVENIDO(A) ${v('[imputado.nombres_apellidos]')} (${v('[imputado.edad]')} años)';

          elements.add(pw.Center(
              child: pw.Text(titleText,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center)));
          elements.add(pw.SizedBox(height: 20));

          final paragraph1 =
              '--- En ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas del ${v('[tiempo.fecha_hecho]')}, presentes en las instalaciones de la dependencia policial, el instructor ${v('[instructor.grado_nombres]')}, procede a recibir la manifestación de la persona identificada como ${v('[imputado.nombres_apellidos]')}, natural de ${v('[imputado.lugar_nacimiento]')}, nacido(a) el ${v('[imputado.fecha_nacimiento]')}, hijo(a) de ${v('[imputado.nombre_padre]')} y de ${v('[imputado.nombre_madre]')}, de estado civil ${v('[imputado.estado_civil]')}, con grado de instrucción ${v('[imputado.grado_instruccion]')}, de ocupación ${v('[imputado.ocupacion]')}, identificado con DNI N° ${v('[imputado.dni]')}, domiciliado(a) en ${v('[imputado.domicilio]')}, con teléfono ${v('[imputado.telefono]')} y correo electrónico ${v('[imputado.correo]')}.';

          elements.add(pw.Text(paragraph1, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          final abogadoN = v('[abogado.nombres]');
          final fiscalN = v('[fiscal.grado_nombres]');
          final tieneAbogado = abogadoN.isNotEmpty && abogadoN != '_______________';
          final tieneFiscal = fiscalN.isNotEmpty && fiscalN != '_______________';

          if (tieneAbogado || tieneFiscal) {
            String parts = '';
            if (tieneAbogado) {
              parts += 'su Abogado Defensor $abogadoN';
            }
            if (tieneFiscal) {
              if (parts.isNotEmpty) parts += ' y ';
              parts += 'el Representante del Ministerio Público $fiscalN, de la ${v('[fiscal.fiscalia]')}';
            }
            final paragraph2 =
                'Diligencia que se realiza con la participación de $parts.';
            elements.add(pw.Text(paragraph2, textAlign: pw.TextAlign.justify));
            elements.add(pw.SizedBox(height: 10));
          }

          elements.add(pw.Text(
              '01. PREGUNTADO, DIGA: ¿Si para rendir su presente manifestación requiere el asesoramiento de un abogado defensor de su elección?'));
          elements.add(pw.Text('DIJO: ${v('[manifestacion.respuesta_01]')}'));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text(
              '02. PREGUNTADO, DIGA: ¿Si reconoce o niega los cargos que se le imputan por el hecho delictivo que motiva su detención?'));
          elements.add(pw.Text('DIJO: ${v('[manifestacion.respuesta_02]')}'));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text(
              '03. PREGUNTADO, DIGA: Exprese detalladamente las circunstancias en las que se produjo su intervención y detención por parte del personal policial.'));
          elements.add(pw.Text('DIJO: ${v('[manifestacion.respuesta_03]')}'));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text(
              '04. PREGUNTADO, DIGA: ¿Si las especies o bienes que le fueron incautados durante el registro personal son de su propiedad u procedencia ilícita?'));
          elements.add(pw.Text('DIJO: ${v('[manifestacion.respuesta_04]')}'));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text(
              '05. PREGUNTADO, DIGA: ¿Si tiene algo más que agregar o modificar a su presente manifestación?'));
          elements.add(pw.Text('DIJO: ${v('[manifestacion.respuesta_05]')}'));
          elements.add(pw.SizedBox(height: 10));

          final obs = v('[manifestacion.observaciones]');
          if (obs.isNotEmpty && obs != '_______________') {
            elements.add(pw.Text('Preguntas / Observaciones adicionales de los participantes:'));
            elements.add(pw.Text(obs, textAlign: pw.TextAlign.justify));
            elements.add(pw.SizedBox(height: 10));
          }

          final closingParagraph =
              '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas del mismo día, previa lectura, se da por concluida la presente diligencia, procediendo a firmar e imprimir su índice digital derecho los participantes en señal de conformidad.';
          elements.add(
              pw.Text(closingParagraph, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          final instructorSign = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR'),
              pw.Text(v('[instructor.grado_nombres]')),
              pw.Text('(Sello Redondo de la Dependencia)',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );

          final manifestanteSign = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL MANIFESTANTE'),
              pw.Text(v('[imputado.nombres_apellidos]')),
              pw.Text('DNI N° ${v('[imputado.dni]')}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );

          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [instructorSign, manifestanteSign],
          ));

          final intReq = v('[interprete.requiere]').toUpperCase();
          final intName = v('[interprete.nombres]');
          final hasInterprete = intReq == 'SI' && intName.isNotEmpty && intName != '_______________';
          
          final testName = v('[testigo.nombres_apellidos]');
          final hasTestigo = testName.isNotEmpty && testName != '_______________';

          if (tieneAbogado || tieneFiscal || hasInterprete || hasTestigo) {
            elements.add(pw.SizedBox(height: 50));

            List<pw.Widget> extraSigns = [];

            if (tieneAbogado) {
              extraSigns.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('_________________________'),
                  pw.Text('EL ABOGADO DEFENSOR'),
                  pw.Text(abogadoN),
                ],
              ));
            }
            if (tieneFiscal) {
              extraSigns.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('_________________________'),
                  pw.Text('EL REPRESENTANTE DEL M.P.'),
                  pw.Text(fiscalN),
                ],
              ));
            }
            if (hasInterprete) {
              extraSigns.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('_________________________'),
                  pw.Text('EL INTÉRPRETE'),
                  pw.Text(intName),
                ],
              ));
            }
            if (hasTestigo) {
              extraSigns.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('_________________________'),
                  pw.Text('EL TESTIGO'),
                  pw.Text(testName),
                ],
              ));
            }

            // Group into pairs for rows
            for (var i = 0; i < extraSigns.length; i += 2) {
              if (i + 1 < extraSigns.length) {
                elements.add(pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    extraSigns[i],
                    extraSigns[i + 1],
                  ],
                ));
              } else {
                elements.add(pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    extraSigns[i],
                  ],
                ));
              }
              elements.add(pw.SizedBox(height: 50));
            }
          }

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateManifestacionPdf(Map<String, String> tags) async {
    final pdf = pw.Document();
    await addManifestacionPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  
  static Future<void> addDetencionPages(pw.Document pdf, 
      Map<String, String> tags, String typificationName, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ACTA DE DETENCIÓN Y LECTURA DE DERECHOS DEL IMPUTADO',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        decoration: pw.TextDecoration.underline),
                    textAlign: pw.TextAlign.center),
              ],
            ),
          ));
          elements.add(pw.SizedBox(height: 20));

          final intro =
              '--- En el distrito de ${v('[lugar.distrito]')}, provincia de ${v('[lugar.provincia]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas del ${v('[tiempo.fecha_hecho]')}, presentes en ${v('[acta.lugar_redaccion]')}, el instructor ${v('[instructor.grado_nombres]')}, procedió a redactar la presente acta con el siguiente detalle:';
          elements.add(pw.Text(intro, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('I. DATOS DEL DETENIDO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text('Nombres y Apellidos : ${v('[imputado.nombres_apellidos]')}\n'
              'Edad                : ${v('[imputado.edad]')} años\n'
              'Identificado con    : DNI/CE N° ${v('[imputado.dni]')}\n'
              'Domiciliado en      : ${v('[imputado.domicilio]')}'));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('II. MOTIVO Y BASE LEGAL DE LA DETENCIÓN:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          final motivoLegal =
              'En este acto se le notifica que se encuentra DETENIDO en flagrante delito, por estar inmerso en el presunto ilícito de $typificationName, bajo el siguiente marco legal:\n${v('[imputado.base_legal_detencion]')}';
          elements.add(pw.Text(motivoLegal, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text('Motivo fáctico (Breve descripción):\n${v('[detencion.motivo_factico]')}',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.Text('III. LECTURA DE DERECHOS (Art. 71.2° CPP):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          final lectura =
              'En dicha condición y de manera inmediata a su intervención, se le da lectura de los siguientes derechos que la Constitución y las Leyes le conceden:\n${v('[derechos.lectura_articulos]')}';
          elements.add(pw.Text(lectura, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Asimismo, conforme al inciso "c" del referido artículo, se le consultó a qué persona o institución desea que se le comunique su detención en forma inmediata, manifestando:\n'
              'Persona/Institución a comunicar: ${v('[persona.vinculo]')}\n'
              'Teléfono de contacto: ${v('[abogado.telefono]')}'));
          elements.add(pw.SizedBox(height: 10));

          // ── III.A GARANTÍAS Y PEDIDOS LEGALES ESPECIALES ───────────
          elements.add(pw.Text('III.A GARANTÍAS Y PEDIDOS LEGALES ESPECIALES:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          final interpreteReq = (tags['[interprete.requiere]'] ?? 'NO').toUpperCase();
          final interpreteIdioma = v('[interprete.idioma]');
          final interpreteNombres = v('[interprete.nombres]');
          final abogadoNombres = v('[abogado.nombres]');
          final abogadoTelefono = v('[abogado.telefono]');
          final abogadoDireccion = v('[abogado.direccion]');
          final abogadoOficio = (tags['[abogado.es_de_oficio]'] ?? 'NO').toUpperCase();
          final examMedico = (tags['[imputado.solicita_examen_medico]'] ?? 'NO').toUpperCase();

          elements.add(pw.Text(
              '1. Asistencia de Intérprete: ¿Requiere intérprete?: $interpreteReq (Idioma/Lengua: $interpreteIdioma | Nombre: $interpreteNombres)\n'
              '2. Asistencia de Abogado Defensor: ¿Designa abogado de su libre elección?: $abogadoNombres (Tlf: $abogadoTelefono | Domicilio: $abogadoDireccion | ¿Es de oficio?: $abogadoOficio)\n'
              '3. Examen Médico: ¿Solicita formalmente ser examinado por un médico legista?: $examMedico',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('IV. COMUNICACIONES DE LEY (Art. 67° CPP):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          final fiscalMsg =
              'A efectos de garantizar la legalidad de la intervención, a las ${v('[fiscal.hora_comunicacion]')} horas, se comunicó telefónicamente de la presente detención al Representante del Ministerio Público, ${v('[fiscal.grado_nombres]')}, de la ${v('[fiscal.fiscalia]')}, mediante el teléfono celular ${v('[fiscal.telefono_usado]')}, resultando de la comunicación que el Fiscal dispuso: ${v('[fiscal.resultado_comunicacion]')}.';
          elements.add(pw.Text(fiscalMsg, textAlign: pw.TextAlign.justify));

          int? edad = int.tryParse(tags['[imputado.edad]'] ?? '');
          if (edad != null && edad < 18) {
            elements.add(pw.SizedBox(height: 5));
            elements.add(pw.Text(
                'Se comunicó al Fiscal de Familia de Turno: ${v('[fiscal_familia.nombres]')} de la ${v('[fiscal_familia.fiscalia]')}.',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          }
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('V. CONSTANCIA DE FIRMA Y TRATO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Se deja constancia que el procedimiento de detención se realizó con estricto respeto a los Derechos Humanos.'));
          
          String seNego = tags['[firma.se_nego_imputado]'] ?? 'NO';
          elements.add(pw.Text('¿El detenido se negó a firmar la presente acta?: $seNego'));
          
          if (seNego.toUpperCase() == 'SI' || seNego.toUpperCase() == 'SÍ') {
            elements.add(pw.Text(
                'Dejando constancia que el intervenido se negó a firmar el presente documento aduciendo las siguientes razones: ${v('[firma.motivo_negativa]')}.',
                textAlign: pw.TextAlign.justify));
          }
          elements.add(pw.SizedBox(height: 10));

          final cierre =
              '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas del mismo día, previa lectura, se da por concluida la presente diligencia, procediendo a firmar e imprimir su índice digital derecho en señal de conformidad.';
          elements.add(pw.Text(cierre, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          final instFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR PNP'),
              pw.Text(v('[instructor.grado_nombres]')),
              pw.Text('CIP N° ${v('[instructor.cip]')}'),
            ],
          );

          final detFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL DETENIDO (ENTERADO)'),
              pw.Text(v('[imputado.nombres_apellidos]')),
              pw.Text('DNI N° ${v('[imputado.dni]')}'),
            ],
          );

          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              instFirm,
              detFirm,
            ],
          ));

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateDetencionPdf(
      Map<String, String> tags, String typificationName) async {
    final pdf = pw.Document();
    await addDetencionPages(pdf, tags, typificationName, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  
  static Future<void> addRegistroPersonalPages(pw.Document pdf, Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ACTA DE REGISTRO PERSONAL E INCAUTACIÓN',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        decoration: pw.TextDecoration.underline),
                    textAlign: pw.TextAlign.center),
              ],
            ),
          ));
          elements.add(pw.SizedBox(height: 20));

          final intro =
              '--- En la ciudad de ${v('[lugar.provincia]')}, Distrito de ${v('[lugar.distrito]')}, Provincia ${v('[lugar.provincia]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas, del día ${v('[tiempo.fecha_hecho]')}, presentes en ${v('[acta.lugar_redaccion]')}, el instructor ${v('[instructor.grado_nombres]')}, con CIP N° ${v('[instructor.cip]')}, perteneciente a ${v('[acta.dependencia_policial]')}, procedió a registrar a:';
          elements.add(pw.Text(intro, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('I. DATOS DE EL/LA RETENIDO/A – DETENIDO/A [1]',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text('Nombres y Apellidos: ${v('[imputado.nombres_apellidos]')}\n'
              'DNI N°: ${v('[imputado.dni]')}', textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('II. MOTIVACIÓN PREVIA AL REGISTRO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text('Lo que se comunica a el/la intervenido/a previo a la realización del registro:\n${v('[registro.razones_comunicadas]')}',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          // ── II.A SOLICITUD DE EXHIBICIÓN Y ENTREGA DEL BIEN BUSCADO ──
          elements.add(pw.Text('II.A SOLICITUD DE EXHIBICIÓN Y ENTREGA DEL BIEN BUSCADO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          final exhibicionRes = (tags['[registro.solicitud_exhibicion]'] ?? 'NEGATIVO').toUpperCase();
          final bienBuscado = v('[registro.descripcion_bien_buscado]');
          elements.add(pw.Text(
              '¿El/La intervenido/a accedió a la exhibición y entrega voluntaria del bien buscado?: $exhibicionRes\n'
              'Descripción del bien incautado o solicitado: $bienBuscado',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('III. PRESENCIA DE TESTIGOS [3]:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Por lo que, el presente registro se realiza en presencia de: ${v('[testigo.nombres_apellidos]')}, identificado con DNI N° ${v('[testigo.dni]')}.\n'
              'Domiciliado en ${v('[testigo.domicilio]')}, con celular N° ${v('[testigo.telefono]')} y parentesco ${v('[testigo.vinculo]')}.\n'
              '(En caso no se pueda ubicar fácilmente a la persona, indicar los actos que se realizaron para su respectiva ubicación):\n${v('[registro.actos_ubicacion_testigo]')}\n'
              '(Si el registro es efectuado por una persona de sexo distinto explicará cuales fueron las circunstancias apremiantes):\n${v('[registro.circunstancias_sexo_distinto]')}',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('IV. DEL REGISTRO [3]:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Ubicación y descripción de los bienes objeto de registro (Lugar donde se encontró y características de los bienes y objetos):\n${v('[registro.ubicacion_exacta_hallazgo]')}',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          final bienesDetalle = v('[registro.bienes_detalle]');
          if (bienesDetalle.isEmpty || bienesDetalle == '_______________') {
            elements.add(pw.Text(
                'Al registro personal, NO se halló en su poder especies, bienes o evidencias de naturaleza delictiva.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
          } else {
            elements.add(pw.Text(bienesDetalle, textAlign: pw.TextAlign.justify));
          }

          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('V. FILMACIÓN DE LA INTERVENCIÓN [3]:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Si el registro fue filmado, precisar el medio audiovisual utilizado:\n${v('[registro.medio_audiovisual_filmacion]')}',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text(
              'VI. RAZONES QUE MOTIVARON QUE EL ACTA NO SE LEVANTE EN EL LUGAR DE LA INTERVENCIÓN [3]:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(v('[acta.razones_cambio_lugar]'),
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('VII. CONSTANCIA DE FIRMA Y CONFORMIDAD:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          
          String seNego = tags['[firma.se_nego_imputado]'] ?? 'NO';
          if (seNego.toUpperCase() == 'SI' || seNego.toUpperCase() == 'SÍ') {
            elements.add(pw.Text(
                '(De ser el caso) Indicar la razón por la que no puede o no quiere firmar el acta [3]:\n${v('[firma.motivo_negativa]')}',
                textAlign: pw.TextAlign.justify));
          }
          elements.add(pw.SizedBox(height: 10));

          final cierre =
              '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas del mismo día, se da por concluida la presente diligencia y una vez leída en señal de conformidad, suscriben los participantes [3].';
          elements.add(pw.Text(cierre, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          final instFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR PNP'),
              pw.Text(v('[instructor.grado_nombres]')),
              pw.Text('SA - ${v('[instructor.cip]')}'),
            ],
          );

          final detFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL DETENIDO/RETENIDO [3]'),
              pw.Text('Nombre: ${v('[imputado.nombres_apellidos]')}'),
              pw.Text('DNI N° ${v('[imputado.dni]')}'),
            ],
          );

          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              instFirm,
              detFirm,
            ],
          ));

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateRegistroPersonalPdf(Map<String, String> tags) async {
    final pdf = pw.Document();
    await addRegistroPersonalPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }

  static Future<void> addRegistroVehicularPages(pw.Document pdf,
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: _getPnpPageTheme(),
        header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null,
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          // ── ENCABEZADO ──────────────────────────────────────────
          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ACTA DE REGISTRO VEHICULAR E INCAUTACIÓN',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        decoration: pw.TextDecoration.underline),
                    textAlign: pw.TextAlign.center),
              ],
            ),
          ));
          elements.add(pw.SizedBox(height: 20));

          // ── PÁRRAFO INTRODUCTORIO ────────────────────────────────
          final intro =
              '--- En la ciudad de ${v('[lugar.provincia]')}, Distrito de ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas del ${v('[tiempo.fecha_hecho]')}, en el lugar ubicado en ${v('[acta.lugar_redaccion]')}, el instructor PNP ${v('[instructor.grado_nombres]')}, identificado con CIP N° ${v('[instructor.cip]')}, interviene el siguiente vehículo automotor:';
          elements.add(pw.Text(intro, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          // ── I. DATOS DEL VEHÍCULO ────────────────────────────
          elements.add(pw.Text('I. DATOS DEL VEHÍCULO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Placa de Rodaje: ${v('[vehiculo.placa]')} | Clase: ${v('[vehiculo.clase]')}\n'
              'Marca: ${v('[vehiculo.marca]')} | Modelo: ${v('[vehiculo.modelo]')} | Color: ${v('[vehiculo.color]')}\n'
              'N° Motor: ${v('[vehiculo.motor]')} | N° Serie/VIN: ${v('[vehiculo.vin]')}'));
          elements.add(pw.SizedBox(height: 15));

          // ── II. IDENTIFICACIÓN DEL CONDUCTOR Y OCUPANTES ─────────
          elements.add(pw.Text('II. IDENTIFICACIÓN DEL CONDUCTOR Y OCUPANTES:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Conductor: ${v('[conductor.nombres_apellidos]')} | DNI: ${v('[conductor.dni]')}\n'
              'Ocupantes intervenidos: ${v('[vehiculo.lista_ocupantes]')}'));
          elements.add(pw.SizedBox(height: 15));

          // ── III. DEL REGISTRO E INCAUTACIÓN ───────────────────────
          elements.add(pw.Text('III. DEL REGISTRO E INCAUTACIÓN:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Previa información del motivo de la intervención y solicitud de exhibición de bienes, se procedió a efectuar el registro vehicular in situ, obteniendo el siguiente resultado fáctico:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(v('[registro.bienes_hallados_vehiculo]'),
              textAlign: pw.TextAlign.justify,
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Los bienes descritos quedan debidamente INCAUTADOS para su perennización y remisión al laboratorio.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          // ── IV. COMUNICACIÓN AL MINISTERIO PÚBLICO ────────────────
          elements.add(pw.Text('IV. COMUNICACIÓN AL MINISTERIO PÚBLICO (Art. 67° CPP):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Se hace constar que se dio cuenta de los actos urgentes a las ${v('[fiscal.hora_comunicacion]')} horas, al Fiscal ${v('[fiscal.grado_nombres]')} de la ${v('[fiscal.fiscalia]')}, mediante el número telefónico ${v('[fiscal.telefono_usado]')}, disponiendo: ${v('[fiscal.resultado_comunicacion]')}.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          // ── V. CONSTANCIA DE FIRMA Y CONFORMIDAD ──────────────────
          elements.add(pw.Text('V. CONSTANCIA DE FIRMA Y CONFORMIDAD:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          
          String seNego = tags['[firma.se_nego_imputado]'] ?? 'NO';
          if (seNego.toUpperCase() == 'SI' || seNego.toUpperCase() == 'SÍ' || (v('[firma.motivo_negativa]').isNotEmpty && v('[firma.motivo_negativa]') != '_______________')) {
            elements.add(pw.Text('Motivo de negativa a firmar: ${v('[firma.motivo_negativa]')}'));
          } else {
            elements.add(pw.Text('El conductor / intervenido firma en señal de conformidad.'));
          }
          elements.add(pw.SizedBox(height: 10));

          final cierre =
              'Se da por concluida la diligencia a las ${v('[tiempo.acta_hora_cierre]')} horas.';
          elements.add(pw.Text(cierre, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          final instFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR PNP'),
              pw.Text(v('[instructor.grado_nombres]')),
              pw.Text('CIP N° ${v('[instructor.cip]')}'),
            ],
          );

          final condFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL CONDUCTOR / INTERVENIDO'),
              pw.Text(v('[conductor.nombres_apellidos]')),
              pw.Text('DNI N° ${v('[conductor.dni]')}'),
            ],
          );

          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              instFirm,
              condFirm,
            ],
          ));

          return elements;
        },
      ),
    );
  }

  static Future<Uint8List> generateRegistroVehicularPdf(Map<String, String> tags) async {
    final pdf = pw.Document();
    await addRegistroVehicularPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }

  
  static Future<void> addHallazgoRecojoPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ACTA DE HALLAZGO Y RECOJO',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        decoration: pw.TextDecoration.underline)),
              ],
            ),
          ));
          elements.add(pw.SizedBox(height: 20));

          final intro =
              '--- En la ciudad de ${v('[lugar.provincia]')}, Distrito de ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas, del ${v('[tiempo.fecha_hecho]')}, sito en ${v('[acta.lugar_redaccion]')}, el instructor policial que suscribe, procedió a formular la presente Acta de Hallazgo y Recojo, en las circunstancias siguientes:';
          elements.add(pw.Text(intro, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('I. CIRCUNSTANCIAS DEL HALLAZGO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(v('[narrativa.hechos]'),
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('II. DEL RECOJO Y DESCRIPCIÓN:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Procediendo a recoger lo siguiente (descripción detallada del objeto, especie o bien):',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          final bienesDetalle = v('[registro.bienes_detalle]').trim();
          if (bienesDetalle.isEmpty || bienesDetalle == '_______________') {
            elements.add(pw.Text(
                'No se encontraron especies, bienes o evidencias de naturaleza delictiva.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
          } else {
            elements.add(pw.Text(bienesDetalle, textAlign: pw.TextAlign.justify));
          }

          elements.add(pw.SizedBox(height: 10));

          final testigoNombre = tags['[testigo.nombres_apellidos]'];
          if (testigoNombre != null && testigoNombre.trim().isNotEmpty) {
            elements.add(pw.Text('Testigo de Hallazgo:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            elements.add(pw.Text(
                'La presente diligencia se realizó en presencia del testigo $testigoNombre, identificado con DNI N° ${v('[testigo.dni]')}.',
                textAlign: pw.TextAlign.justify));
            elements.add(pw.SizedBox(height: 10));
          }

          final cierre =
              '--- Leída la presente se firma en señal de conformidad por los presentes a las ${v('[tiempo.acta_hora_cierre]')} horas del día de la fecha.';
          elements.add(pw.Text(cierre, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          final instFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR'),
              pw.Text(v('[instructor.grado_nombres]')),
              pw.Text('CIP N° ${v('[instructor.cip]')}'),
            ],
          );

          pw.Widget? testFirm;
          if (testigoNombre != null && testigoNombre.trim().isNotEmpty) {
            testFirm = pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('_________________________'),
                pw.Text('EL TESTIGO'),
                pw.Text('Nombre: $testigoNombre'),
                pw.Text('DNI N° ${v('[testigo.dni]')}'),
              ],
            );
          }

          elements.add(pw.Row(
            mainAxisAlignment: testFirm != null
                ? pw.MainAxisAlignment.spaceBetween
                : pw.MainAxisAlignment.start,
            children: [
              instFirm,
              ?testFirm,
            ],
          ));

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateHallazgoRecojoPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addHallazgoRecojoPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  
  static Future<void> addLacradoPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ACTA DE LACRADO DE EVIDENCIAS / ESPECIES',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        decoration: pw.TextDecoration.underline)),
              ],
            ),
          ));
          elements.add(pw.SizedBox(height: 20));

          final intro =
              '--- En la ciudad de ${v('[lugar.provincia]')}, distrito de ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas del ${v('[tiempo.fecha_hecho]')}, en el lugar ubicado en ${v('[acta.lugar_redaccion]')}, el Instructor Policial que suscribe conjuntamente con el imputado (o testigo) ${v('[imputado.nombres_apellidos]')}, de ${v('[imputado.edad]')} años de edad, identificado con DNI N° ${v('[imputado.dni]')}.';
          elements.add(pw.Text(intro, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          final fiscalNombre = tags['[fiscal.grado_nombres]'];
          if (fiscalNombre != null && fiscalNombre.trim().isNotEmpty) {
            elements.add(pw.Text(
                'Diligencia que cuenta con la participación del Representante del Ministerio Público: $fiscalNombre de la ${v('[fiscal.fiscalia]')}.',
                textAlign: pw.TextAlign.justify));
            elements.add(pw.SizedBox(height: 10));
          }

          elements.add(pw.Text('I. DESCRIPCIÓN DEL LACRADO Y ROTULADO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Se procede al cierre, rotulado y LACRADO de las especies, drogas y/o evidencias previamente incautadas o recogidas, las mismas que se detallan a continuación para mantener su perennidad e intangibilidad:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          final bienesDetalle = v('[registro.bienes_detalle]').trim();
          if (bienesDetalle.isEmpty || bienesDetalle == '_______________') {
            elements.add(pw.Text(
                'No se registran especies para lacrar.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
          } else {
            elements.add(pw.Text(bienesDetalle, textAlign: pw.TextAlign.justify));
          }

          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('II. CONSTANCIA DE CUSTODIA E INTEGRIDAD:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Dichas especies se introducen en sus respectivos envases, cajas y/o sobres, procediendo a ser cerrados y lacrados, firmando los intervinientes sobre la cinta de seguridad y bordes para garantizar su inalterabilidad, designando como encargado de la custodia física y traslado al efectivo policial: ${v('[custodia.funcionario_encargado]')}.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          String seNego = tags['[firma.se_nego_imputado]'] ?? 'NO';
          if (seNego.toUpperCase() == 'SI' || seNego.toUpperCase() == 'SÍ') {
            elements.add(pw.Text('III. CONSTANCIA DE NEGATIVA A FIRMAR (De ser el caso):',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            elements.add(pw.SizedBox(height: 5));
            elements.add(pw.Text(v('[firma.motivo_negativa]'),
                textAlign: pw.TextAlign.justify));
            elements.add(pw.SizedBox(height: 10));
          }

          final cierre =
              '--- Leída la presente, se firma en señal de conformidad por los presentes a las ${v('[tiempo.acta_hora_cierre]')} horas, del día de la fecha.';
          elements.add(pw.Text(cierre, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          final instFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR'),
              pw.Text(v('[instructor.grado_nombres]')),
              pw.Text('CIP N° ${v('[instructor.cip]')}'),
            ],
          );

          final detFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL IMPUTADO / TESTIGO'),
              pw.Text(v('[imputado.nombres_apellidos]')),
              pw.Text('DNI N° ${v('[imputado.dni]')}'),
            ],
          );

          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              instFirm,
              detFirm,
            ],
          ));

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateLacradoPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addLacradoPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  
  static Future<void> addSituacionVehicularPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ACTA DE SITUACIÓN VEHICULAR',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        decoration: pw.TextDecoration.underline)),
              ],
            ),
          ));
          elements.add(pw.SizedBox(height: 20));

          final claseVehiculo = v('[vehiculo.clase]').toLowerCase();
          final isMayor = (claseVehiculo.contains('auto') || claseVehiculo.contains('camion') || claseVehiculo.contains('bus')) ? '(X)' : '( )';
          final isMenor = (claseVehiculo.contains('moto') || claseVehiculo.contains('trimovil') || claseVehiculo.contains('bicimoto')) ? '(X)' : '( )';

          final intro =
              '--- En la ciudad de ${v('[lugar.provincia]')}, Distrito de ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas, del día ${v('[tiempo.fecha_hecho]')}, presentes en ${v('[acta.lugar_redaccion]')}, el instructor ${v('[instructor.grado_nombres]')}, con CIP N° ${v('[instructor.cip]')}, procedió a describir la situación del vehículo mayor $isMayor menor $isMenor, con el siguiente detalle:';
          elements.add(pw.Text(intro, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('I. DESCRIPCIÓN GENERAL:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              '1. N° de placa (Única de Rodaje): ${v('[vehiculo.placa_unica_nacional_rodaje]')}\n'
              '2. Clase: ${v('[vehiculo.clase]')} | Color: ${v('[vehiculo.color]')}\n'
              '3. Marca y Modelo: ${v('[vehiculo.marca]')} / ${v('[vehiculo.modelo]')}\n'
              '4. Motor N°: ${v('[vehiculo.motor]')} | Serie/Chasis N°: ${v('[vehiculo.serie]')}\n'
              '5. Año de Fabricación: ${v('[vehiculo.ano_fabricacion]')}\n'
              '6. Estado de conservación: ${v('[vehiculo.otros_datos]')}'));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('II. PARTE EXTERIOR, INTERIOR Y ACCESORIOS DE MOTOR:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'La descripción y características del vehículo (parte exterior, interior y accesorios) descritos en forma específica, encontrándose los siguientes elementos:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 5));

          final extList = tags['[vehiculo.lista_exterior_positiva]'] ?? 'Sin novedades';
          final intList = tags['[vehiculo.lista_interior_positiva]'] ?? 'Sin novedades';
          final motList = tags['[vehiculo.lista_motor_positiva]'] ?? 'Sin novedades';

          elements.add(pw.Text('- Exterior: $extList', textAlign: pw.TextAlign.justify));
          elements.add(pw.Text('- Interior: $intList', textAlign: pw.TextAlign.justify));
          elements.add(pw.Text('- Motor: $motList', textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('III. PERENNIZACIÓN AUDIOVISUAL:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text('Si el registro fue filmado, precisar el medio audiovisual utilizado:'));
          elements.add(pw.Text(v('[registro.medio_audiovisual_filmacion]'),
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('IV. OBSERVACIONES Y FALTANTES:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(v('[vehiculo.observaciones]'),
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text('V. CONSTANCIA DE FIRMA Y CONFORMIDAD:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));

          String seNego = tags['[firma.se_nego_imputado]'] ?? 'NO';
          if (seNego.toUpperCase() == 'SI' || seNego.toUpperCase() == 'SÍ') {
            elements.add(pw.Text('"De ser el caso" Indicar la razón por la que no puede o no quiere firmar el acta:'));
            elements.add(pw.Text(v('[firma.motivo_negativa]'),
                textAlign: pw.TextAlign.justify));
          } else {
            elements.add(pw.Text('El conductor / intervenido firma en señal de conformidad.'));
          }
          elements.add(pw.SizedBox(height: 10));

          final cierre =
              '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas, del día de la fecha, se da por concluida la presente diligencia y una vez leída en señal de conformidad, suscriben los participantes.';
          elements.add(pw.Text(cierre, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ENTREGUÉ CONFORME', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('RECIBÍ CONFORME', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ));
          elements.add(pw.SizedBox(height: 30));

          final detFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL CONDUCTOR / INTERVENIDO'),
              pw.Text('Nombre: ${v('[imputado.nombres_apellidos]')}'),
              pw.Text('DNI N°: ${v('[imputado.dni]')}'),
            ],
          );

          final instFirm = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR PNP'),
              pw.Text(v('[instructor.grado_nombres]')),
              pw.Text('CIP N° ${v('[instructor.cip]')}'),
            ],
          );

          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              detFirm,
              instFirm,
            ],
          ));

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateSituacionVehicularPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addSituacionVehicularPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  
  static Future<void> addPartePolicialPages(pw.Document pdf, 
      Map<String, String> tags, String typificationName, List<String> documentTitles, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          
          elements.add(pw.Text(v('[dependencia.nombre]'),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)));
          elements.add(pw.SizedBox(height: 20));

          elements.add(pw.Text(
              'PARTE Nº ${v('[documento.numero_correlativo]')} - ${v('[documento.siglas_unidad]')}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, decoration: pw.TextDecoration.underline)));
          elements.add(pw.Text(
              'REGISTRO SIGE N°: ${v('[sige.numero_registro]')}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)));
          elements.add(pw.SizedBox(height: 20));

          elements.add(pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 60, child: pw.Text('ASUNTO :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(
                child: pw.Text(
                    'Da cuenta de intervención policial en flagrante delito por $typificationName, y la detención de la persona de ${v('[imputado.nombres_apellidos]')}.',
                    textAlign: pw.TextAlign.justify),
              ),
            ],
          ));
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 60, child: pw.Text('REF.   :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Expanded(
                child: pw.Text(v('[documento.referencia]')),
              ),
            ],
          ));
          elements.add(pw.SizedBox(height: 20));

          elements.add(pw.Text('I. ANTECEDENTES O INFORMACIÓN PRELIMINAR:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(v('[narrativa.antecedentes]'), textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          elements.add(pw.Text('II. AMPLIACIÓN DETALLADA (HECHOS):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              '${v('[narrativa.hechos]')} (El hecho ocurrió en jurisdicción de ${v('[lugar.distrito]')}).',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          elements.add(pw.Text('III. ACCIONES O DISPOSICIONES ADOPTADAS:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Para perennizar la intervención y asegurar la cadena de custodia, in situ se formularon las siguientes actas:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 5));

          for (var title in documentTitles) {
            elements.add(pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 2),
              child: pw.Text('- $title'),
            ));
          }
          elements.add(pw.SizedBox(height: 10));

          elements.add(pw.Text(
              'Asimismo, en estricto cumplimiento del Art. 67° del Código Procesal Penal, se comunicó del hecho al Representante del Ministerio Público, ${v('[fiscal.grado_nombres]')} de la ${v('[fiscal.fiscalia]')} a las ${v('[fiscal.hora_comunicacion]')} horas, mediante el celular ${v('[fiscal.telefono_usado]')}, indicando lo siguiente: ${v('[fiscal.resultado_comunicacion]')}.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          elements.add(pw.Text('IV. RECOMENDACIÓN O SUGERENCIA:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Lo que se cumple en informar a la Superioridad para los fines pertinentes, adjuntando al presente la documentación formulada e indicios incautados, poniendo a disposición en calidad de DETENIDO al intervenido con irrestricto respeto a sus Derechos Humanos.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 20));

          elements.add(pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('${v('[lugar.distrito]')}, ${v('[tiempo.fecha_hecho]')}'),
          ));
          elements.add(pw.SizedBox(height: 50));

          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('_________________________'),
                pw.Text('EL INSTRUCTOR'),
                pw.Text(v('[instructor.grado_nombres]')),
                pw.Text('CIP N° ${v('[instructor.cip]')}'),
              ],
            ),
          ));

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generatePartePolicialPdf(
      Map<String, String> tags, String typificationName, List<String> documentTitles) async {
    final pdf = pw.Document();
    await addPartePolicialPages(pdf, tags, typificationName, documentTitles, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 08: ACTA DE REGISTRO DOMICILIARIO / ALLANAMIENTO
  // Candado Constitucional: Art. 2° Inc. 9 de la Constitución Política
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addRegistroDomiciliarioPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    String v(String tag) => tags[tag] ?? '_______________';

    // CANDADO CONSTITUCIONAL: las tres únicas causales legales válidas.
    // Si el campo no fue completado, el acta lo expone como VACÍO para
    // que sea visible el error antes de imprimir, no después.
    const causalesValidas = [
      'Por existir flagrante delito y en persecución estricta del presunto autor.',
      'Por existir peligro inminente de perpetración de un delito o destrucción de evidencia.',
      'Por libre, expreso y voluntario consentimiento del propietario u ocupante.',
    ];

    final motivoIngreso = tags['[allanamiento.motivo_ingreso]'] ?? '';
    final motivoValido = causalesValidas.contains(motivoIngreso.trim());
    final motivoFinal = motivoValido
        ? motivoIngreso.trim()
        : '⚠ CAUSAL NO SELECCIONADA — ACTA INCOMPLETA. Marque la excepción constitucional antes de imprimir.';

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          // ── ENCABEZADO ──────────────────────────────────────────
          elements.add(pw.Center(
            child: pw.Column(
              children: [
                pw.Text('ACTA DE REGISTRO DOMICILIARIO E INCAUTACIÓN',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        decoration: pw.TextDecoration.underline)),
              ],
            ),
          ));
          elements.add(pw.SizedBox(height: 20));

          // ── PÁRRAFO INTRODUCTORIO ────────────────────────────────
          elements.add(pw.Text(
              '--- En el distrito de ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} horas del día ${v('[tiempo.fecha_hecho]')}, el instructor PNP ${v('[instructor.grado_nombres]')}, procedió a formular la presente diligencia bajo los siguientes parámetros legales y fácticos:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          // ── I. UBICACIÓN DEL INMUEBLE ────────────────────────────
          elements.add(pw.Text('I. UBICACIÓN DEL INMUEBLE:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'El inmueble objeto de la presente intervención se ubica en ${v('[lugar.tipo_via]')} ${v('[lugar.nombre_via]')}, jurisdicción del distrito de ${v('[lugar.distrito]')}, provincia de ${v('[lugar.provincia]')}.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          // ── II. CANDADO CONSTITUCIONAL ───────────────────────────
          elements.add(pw.Text(
              'II. MOTIVACIÓN CONSTITUCIONAL DEL INGRESO (Art. 2° Inc. 9 de la Constitución):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Se deja expresa constancia que el ingreso a dicho inmueble por parte del personal policial, sin contar con mandato judicial previo, se ejecutó estrictamente amparado en la siguiente excepción legal:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 8));
          elements.add(pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: motivoValido ? PdfColors.grey600 : PdfColors.red,
                width: motivoValido ? 1 : 2,
              ),
            ),
            child: pw.Text(
              motivoFinal,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: motivoValido ? PdfColors.black : PdfColors.red,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ));
          elements.add(pw.SizedBox(height: 15));

          // ── III. DATOS DEL PROPIETARIO ───────────────────────────
          elements.add(pw.Text('III. DATOS DEL PROPIETARIO U OCUPANTE (De encontrarse presente):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Nombres y Apellidos : ${v('[imputado.nombres_apellidos]')}\n'
              'Identificado con    : DNI N° ${v('[imputado.dni]')}'));
          elements.add(pw.SizedBox(height: 15));

          // ── III.A SOLICITUD DE EXHIBICIÓN Y ENTREGA DEL BIEN BUSCADO ──
          elements.add(pw.Text('III.A SOLICITUD DE EXHIBICIÓN Y ENTREGA DEL BIEN BUSCADO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          final exhibicionResDom = (tags['[registro.solicitud_exhibicion]'] ?? 'NEGATIVO').toUpperCase();
          final bienBuscadoDom = v('[registro.descripcion_bien_buscado]');
          elements.add(pw.Text(
              '¿El propietario u ocupante accedió a la exhibición y entrega voluntaria del bien buscado?: $exhibicionResDom\n'
              'Descripción del bien incautado o solicitado: $bienBuscadoDom',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          // ── IV. REGISTRO Y HALLAZGOS (BUCLE DINÁMICO) ───────────
          elements.add(pw.Text('IV. DEL REGISTRO DE AMBIENTES Y HALLAZGOS:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Se procedió a efectuar el registro minucioso y detallado de los ambientes del inmueble, obteniendo el siguiente resultado:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 8));

          final bienesDetalle = v('[registro.bienes_detalle]').trim();
          if (bienesDetalle.isEmpty || bienesDetalle == '_______________') {
            elements.add(pw.Text(
                'No se encontraron especies, bienes o evidencias de naturaleza delictiva.',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
          } else {
            elements.add(pw.Text(bienesDetalle, textAlign: pw.TextAlign.justify));
          }
          elements.add(pw.SizedBox(height: 15));

          // ── V. PERENNIZACIÓN AUDIOVISUAL ─────────────────────────
          elements.add(pw.Text('V. PERENNIZACIÓN DE LA DILIGENCIA:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'Se deja constancia que el desarrollo del presente registro y los hallazgos descritos fueron perennizados mediante el siguiente equipo audiovisual: ${v('[registro.medio_audiovisual_filmacion]')}.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 15));

          // ── VI. CONSTANCIA DE TRATO Y CONFORMIDAD ───────────────
          elements.add(pw.Text('VI. CONSTANCIA DE TRATO Y CONFORMIDAD:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          elements.add(pw.SizedBox(height: 5));
          elements.add(pw.Text(
              'La diligencia se ejecutó con irrestricto respeto a los Derechos Humanos y al patrimonio.',
              textAlign: pw.TextAlign.justify));

          final seNego = (tags['[firma.se_nego_imputado]'] ?? 'NO').toUpperCase();
          if (seNego == 'SI' || seNego == 'SÍ') {
            elements.add(pw.SizedBox(height: 5));
            elements.add(pw.Text(
                '"De ser el caso" Indicar la razón por la que el propietario/ocupante no puede o no quiere firmar el acta:'));
            elements.add(pw.Text(v('[firma.motivo_negativa]'),
                textAlign: pw.TextAlign.justify));
          }
          elements.add(pw.SizedBox(height: 15));

          // ── CIERRE ───────────────────────────────────────────────
          elements.add(pw.Text(
              '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas del mismo día, previa lectura, se da por concluida la presente, procediendo a firmar e imprimir el índice digital derecho los participantes.',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 50));

          // ── FIRMAS ───────────────────────────────────────────────
          elements.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('_________________________'),
                  pw.Text('EL INSTRUCTOR PNP',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(v('[instructor.grado_nombres]')),
                  pw.Text('CIP N° ${v('[instructor.cip]')}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('_________________________'),
                  pw.Text('EL PROPIETARIO / OCUPANTE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(v('[imputado.nombres_apellidos]')),
                  pw.Text('DNI N° ${v('[imputado.dni]')}'),
                ],
              ),
            ],
          ));

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateRegistroDomiciliarioPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addRegistroDomiciliarioPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 09: ACTA DE LLEGADA A LA ESCENA DEL DELITO (F-17)
  // Exclusiva para el "primer respondiente". Preserva la intangibilidad.
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addLlegadaEscenaPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    pdf.addPage(pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
      
      
      build: (ctx) {
        final lesionados = tags['[escena.lesionados_datos]'] ?? '';
        final hayLesionados = lesionados.trim().isNotEmpty;
        final elements = <pw.Widget>[];

        // ── ENCABEZADO ──────────────────────────────────────────
        elements.add(pw.Center(child: pw.Column(children: [
          pw.Text('ACTA DE LLEGADA AL LUGAR DE LOS HECHOS (ESCENA DEL DELITO)',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  decoration: pw.TextDecoration.underline)),
        ])));
        elements.add(pw.SizedBox(height: 18));

        // ── INTRO ────────────────────────────────────────────────
        elements.add(pw.Text(
            '--- En ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} '
            'horas, del día ${v('[tiempo.fecha_hecho]')}; se procede a formular la presente '
            'Acta conforme al siguiente detalle:',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── I. UBICACIÓN Y LLEGADA ───────────────────────────────
        elements.add(pw.Text('I. UBICACIÓN Y LLEGADA:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text(
            'Lugar / Ubicación de la Escena: ${v('[lugar.tipo_via]')} '
            '${v('[lugar.nombre_via]')}, ${v('[lugar.distrito]')}.\n'
            'Personal policial que llegó a la Escena: ${v('[instructor.grado_nombres]')}, '
            'identificado con CIP N° ${v('[instructor.cip]')}.\n'
            'Tomó conocimiento y/o se desplazó a la Escena por disposición de: '
            '${v('[escena.informacion_recibida]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── II. VERIFICACIÓN Y AISLAMIENTO ───────────────────────
        elements.add(pw.Text('II. VERIFICACIÓN Y AISLAMIENTO:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text(
            'Descripción de instalaciones, vehículos, muebles o presunto hecho delictivo:',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
        elements.add(pw.Text(v('[narrativa.hechos]'),
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 8));
        elements.add(pw.Text(
            '¿Se observan signos de violencia, daños o manipulación? (NO MANIPULAR): '
            '${v('[escena.manipulacion_observada]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 8));

        if (hayLesionados) {
          elements.add(pw.Text(
              'Presencia y/o hallazgo de personas heridas o lesionadas:',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
          elements.add(pw.Text(lesionados, textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 8));
        }

        elements.add(pw.Text(
            'Detalle de indicios, evidencias, objetos, especies que se observen '
            '(armas, sangre, fluidos):',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
        elements.add(pw.Text(v('[escena.indicios_observados]'),
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── III. MEDIOS DE PROTECCIÓN Y ENTREGA ──────────────────
        elements.add(pw.Text('III. MEDIOS DE PROTECCIÓN Y ENTREGA DE ESCENA:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text(
            'Medios empleados para el aislamiento y protección de la escena '
            '(Cintas, tranqueras, personal): ${v('[escena.aislamiento_medios]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 6));
        elements.add(pw.Text(
            'Fecha y hora de llegada del Personal de la Unidad Especializada '
            '(Pesquisas/Peritos) o Representante del Ministerio Público: '
            '${v('[escena.hora_llegada_peritos]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 6));
        elements.add(pw.Text(
            'Personal a quien se le hace entrega de la Escena: '
            '${v('[escena.personal_relevo]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── CIERRE ───────────────────────────────────────────────
        elements.add(pw.Text(
            '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas del mismo día, '
            'se levanta la presente Acta, firmando en señal de conformidad.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 50));

        // ── FIRMAS ───────────────────────────────────────────────
        elements.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('_________________________'),
              pw.Text('PERSONAL QUE LLEGÓ INICIALMENTE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[instructor.grado_nombres]'), style: const pw.TextStyle(fontSize: 9)),
              pw.Text('CIP N° ${v('[instructor.cip]')}', style: const pw.TextStyle(fontSize: 9)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('_________________________'),
              pw.Text('PERSONAL QUE SE HACE CARGO',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[escena.personal_relevo]'), style: const pw.TextStyle(fontSize: 9)),
            ]),
          ],
        ));

        return elements;
      },
    ));
    
  
  }

  static Future<Uint8List> generateLlegadaEscenaPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addLlegadaEscenaPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 10: ACTA DE RECONOCIMIENTO FÍSICO (F-20)
  // Candado Legal — Art. 189° NCPP. Solo válido en dependencia policial
  // con presencia del Fiscal y Abogado Defensor.
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addReconocimientoFisicoPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    // CANDADO LEGAL: si no se registra Fiscal o Abogado, el acta
    // advierte visualmente que la diligencia carece de validez procesal.
    final fiscalNombre = tags['[fiscal.grado_nombres]'] ?? '';
    final abogadoNombre = tags['[abogado.nombres]'] ?? '';
    final candadoValido =
        fiscalNombre.trim().isNotEmpty && abogadoNombre.trim().isNotEmpty;

    pdf.addPage(pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
      
      
      build: (ctx) {
        final elements = <pw.Widget>[];

        // ── ENCABEZADO ──────────────────────────────────────────
        elements.add(pw.Center(child: pw.Column(children: [
          pw.Text('POLICÍA NACIONAL DEL PERÚ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('ACTA DE RECONOCIMIENTO FÍSICO Y FOTOGRÁFICO',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline)),
        ])));
        elements.add(pw.SizedBox(height: 14));

        // ALERTA CANDADO ─────────────────────────────────────────
        if (!candadoValido) {
          elements.add(pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red, width: 2)),
            child: pw.Text(
              '⚠ DILIGENCIA INVÁLIDA — Art. 189° NCPP exige presencia del Fiscal '
              'y Abogado Defensor. Complete ambos campos antes de imprimir.',
              style: pw.TextStyle(
                  color: PdfColors.red, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ));
        }

        // ── BASE LEGAL E INTRO ───────────────────────────────────
        elements.add(pw.Text(
            '--- Diligencia practicada conforme a lo establecido en los Arts. '
            '68.1.e; 72.2; 189 y 190 del NCPP.\n'
            'En ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} '
            'horas del ${v('[tiempo.fecha_hecho]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 8));
        elements.add(pw.Text(
            'Autoridad Fiscal a cargo de la diligencia: '
            '${fiscalNombre.isEmpty ? '⚠ NO REGISTRADO' : fiscalNombre}.',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: fiscalNombre.isEmpty ? PdfColors.red : PdfColors.black,
            )));
        elements.add(pw.Text(
            'Con presencia del Abogado Defensor: '
            '${abogadoNombre.isEmpty ? '⚠ NO REGISTRADO' : abogadoNombre}.',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: abogadoNombre.isEmpty ? PdfColors.red : PdfColors.black,
            )));
        elements.add(pw.SizedBox(height: 14));

        // ── I. DESCRIPCIÓN PREVIA ────────────────────────────────
        elements.add(pw.Text('I. DESCRIPCIÓN PREVIA:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text(
            'Conforme al Artículo 189° del NCPP, antes de poner a la vista a '
            'los sujetos, se solicitó al agraviado/testigo '
            '${v('[testigo.nombres_apellidos]')} que describa las características '
            'de la persona a reconocer.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text('Describió lo siguiente:',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
        elements.add(pw.Text(v('[reconocimiento.descripcion_previa]'),
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── II. DEL RECONOCIMIENTO ───────────────────────────────
        elements.add(pw.Text('II. DEL RECONOCIMIENTO:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text(
            'Acto seguido, se le puso a la vista, junto con otras personas de '
            'aspecto exterior semejante (mínimo 5 personas), preguntándole si se '
            'encuentra entre las personas que observa aquella a quien se refirió.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 6));
        elements.add(pw.Text(
            'Resultados del reconocimiento: ${v('[reconocimiento.resultado]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 6));
        elements.add(pw.Text(
            'Perennización Audiovisual: ${v('[registro.medio_audiovisual_filmacion]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── CIERRE ───────────────────────────────────────────────
        elements.add(pw.Text(
            '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas, se da por '
            'concluida la diligencia.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 50));

        // ── BLOQUE DE 4 FIRMAS ───────────────────────────────────
        elements.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('___________________'),
              pw.Text('EL INSTRUCTOR',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[instructor.grado_nombres]'), style: const pw.TextStyle(fontSize: 9)),
              pw.Text('CIP N° ${v('[instructor.cip]')}', style: const pw.TextStyle(fontSize: 9)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('___________________'),
              pw.Text('EL AGRAVIADO / TESTIGO',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[testigo.nombres_apellidos]'), style: const pw.TextStyle(fontSize: 9)),
              pw.Text('DNI N° ${v('[testigo.dni]')}', style: const pw.TextStyle(fontSize: 9)),
            ]),
          ],
        ));
        elements.add(pw.SizedBox(height: 30));
        elements.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('___________________'),
              pw.Text('EL FISCAL',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(fiscalNombre.isEmpty ? '_______________' : fiscalNombre,
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(v('[fiscal.fiscalia]'), style: const pw.TextStyle(fontSize: 9)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('___________________'),
              pw.Text('EL ABOGADO DEFENSOR',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(abogadoNombre.isEmpty ? '_______________' : abogadoNombre,
                  style: const pw.TextStyle(fontSize: 9)),
            ]),
          ],
        ));

        return elements;
      },
    ));
    
  
  }

  static Future<Uint8List> generateReconocimientoFisicoPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addReconocimientoFisicoPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 11: ACTA DE RECEPCIÓN (F-06)
  // Entrega voluntaria de bienes por ciudadanos o víctimas.
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addActaRecepcionPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    pdf.addPage(pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
      
      
      build: (ctx) {
        final elements = <pw.Widget>[];

        // ── ENCABEZADO ──────────────────────────────────────────
        elements.add(pw.Center(child: pw.Column(children: [
          pw.Text('ACTA DE ENTREGA Y RECEPCIÓN',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  decoration: pw.TextDecoration.underline)),
        ])));
        elements.add(pw.SizedBox(height: 18));

        // ── INTRO ────────────────────────────────────────────────
        elements.add(pw.Text(
            '--- En ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} '
            'horas, del ${v('[tiempo.fecha_hecho]')}. El instructor '
            '${v('[instructor.grado_nombres]')}, procede a realizar la presente diligencia.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── I. DATOS DEL ENTREGANTE ──────────────────────────────
        elements.add(pw.Text('I. DATOS DE LA PERSONA QUE REALIZA LA ENTREGA:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text(
            'Nombres y Apellidos: ${v('[testigo.nombres_apellidos]')}\n'
            'DNI N°: ${v('[testigo.dni]')} | Celular: ${v('[testigo.telefono]')}'));
        elements.add(pw.SizedBox(height: 14));

        // ── II. CIRCUNSTANCIAS Y BIENES (BUCLE) ─────────────────
        elements.add(pw.Text(
            'II. CIRCUNSTANCIAS Y DESCRIPCIÓN DEL BIEN:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 5));
        elements.add(pw.Text(
            'Razones que motivan la entrega: ${v('[recepcion.motivo]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 8));
        elements.add(pw.Text('Procediendo a recibir lo siguiente:',
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
        elements.add(pw.SizedBox(height: 5));

        final bienesDetalle = v('[registro.bienes_detalle]').trim();
        if (bienesDetalle.isEmpty || bienesDetalle == '_______________') {
          elements.add(pw.Text('- (Ningún bien registrado)',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600)));
        } else {
          elements.add(pw.Text(bienesDetalle, textAlign: pw.TextAlign.justify));
        }

        elements.add(pw.SizedBox(height: 10));
        elements.add(pw.Text(
            'El bien incautado quedará bajo custodia temporal del efectivo: '
            '${v('[custodia.funcionario_encargado]')}.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── CIERRE ───────────────────────────────────────────────
        elements.add(pw.Text(
            '--- Leída la presente, se firma a las '
            '${v('[tiempo.acta_hora_cierre]')} horas.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 50));

        // ── FIRMAS ───────────────────────────────────────────────
        elements.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[instructor.grado_nombres]'), style: const pw.TextStyle(fontSize: 9)),
              pw.Text('CIP N° ${v('[instructor.cip]')}', style: const pw.TextStyle(fontSize: 9)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
              pw.Text('_________________________'),
              pw.Text('EL CIUDADANO (ENTREGANTE)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[testigo.nombres_apellidos]'), style: const pw.TextStyle(fontSize: 9)),
              pw.Text('DNI N° ${v('[testigo.dni]')}', style: const pw.TextStyle(fontSize: 9)),
            ]),
          ],
        ));

        return elements;
      },
    ));
    
  
  }

  static Future<Uint8List> generateActaRecepcionPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addActaRecepcionPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 12: OFICIO PETITORIO (F-56)
  // Solicitud de Reconocimiento Médico Legal / Dosaje Etílico.
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addOficioPetitorioPages(pw.Document pdf, 
      Map<String, String> tags, String tipificacion, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    pdf.addPage(pw.Page(pageFormat: _pnpPageFormat, margin: _pnpPageMargin, build: (ctx) => _wrapWithFoliation(ctx, pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── MEMBRETE ──────────────────────────────────────────
          pw.Center(
            child: pw.Column(children: [
              pw.Text('POLICÍA NACIONAL DEL PERÚ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.SizedBox(height: 3),
              pw.Text(v('[dependencia.nombre]'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            ]),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 14),

          // ── DATOS DEL OFICIO ──────────────────────────────────
          pw.Text(
              'OFICIO N° ${v('[documento.numero_correlativo]')} - ${v('[documento.siglas_unidad]')}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('SEÑOR  : MÉDICO LEGISTA DE TURNO DEL MINISTERIO PÚBLICO',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('ASUNTO : Solicita Reconocimiento Médico Legal (RML) de la persona que se indica.'),
          pw.Text('REF.   : Intervención Policial en Flagrante Delito.'),
          pw.SizedBox(height: 16),

          // ── CUERPO ────────────────────────────────────────────
          pw.Text(
              '--- Es grato dirigirme a Ud., a fin de solicitarle se sirva disponer a quien corresponda, '
              'se practique el Reconocimiento Médico Legal (RML) a la persona de:',
              textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Nombres y Apellidos : ${v('[imputado.nombres_apellidos]')}'),
                pw.Text('Identificado con DNI: ${v('[imputado.dni]')}'),
                pw.Text('Edad                : ${v('[imputado.edad]')} años'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
              'Por encontrarse inmerso en la presunta comisión del delito de $tipificacion, '
              'diligencia de carácter Urgente e Imprescindible para el esclarecimiento de los hechos. '
              'Custodia a cargo del instructor ${v('[instructor.grado_nombres]')}.',
              textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 14),
          pw.Text(
              'Es propicia la oportunidad para expresarle los sentimientos de mi especial consideración.',
              textAlign: pw.TextAlign.justify),

          pw.Spacer(),

          // ── FIRMA ─────────────────────────────────────────────
          pw.Text('Dios guarde a Ud.'),
          pw.SizedBox(height: 4),
          pw.Text('${v('[lugar.distrito]')}, ${v('[tiempo.fecha_hecho]')}'),
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('_______________________________'),
                pw.Text('EL INSTRUCTOR',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(v('[instructor.grado_nombres]')),
                pw.Text('CIP N° ${v('[instructor.cip]')}'),
              ],
            ),
          ),
        ],
      ), includeFoliation, initialFolio)));
    
  
  }

  static Future<Uint8List> generateOficioPetitorioPdf(
      Map<String, String> tags, String tipificacion) async {
    final pdf = pw.Document();
    await addOficioPetitorioPages(pdf, tags, tipificacion, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 13: CITACIÓN POLICIAL (F-30)
  // Asegura la comparecencia de testigos y agraviados.
  // Marca automáticamente 1ra, 2da o 3ra citación.
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addCitacionPolicialPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    // Determinar número de citación para marcar el checkbox correcto
    final numCitacion = int.tryParse(tags['[citacion.numero_orden]'] ?? '1') ?? 1;

    pdf.addPage(pw.Page(pageFormat: _pnpPageFormat, margin: _pnpPageMargin, build: (ctx) => _wrapWithFoliation(ctx, pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── MEMBRETE ──────────────────────────────────────────
          pw.Center(
            child: pw.Column(children: [
              pw.Text('POLICÍA NACIONAL DEL PERÚ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.SizedBox(height: 3),
              pw.Text(v('[dependencia.nombre]'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'CITACIÓN POLICIAL N° ${v('[documento.numero_correlativo]')} - ${v('[documento.siglas_unidad]')}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      decoration: pw.TextDecoration.underline)),
            ]),
          ),
          pw.SizedBox(height: 20),

          // ── DESTINATARIO ──────────────────────────────────────
          pw.Text('SEÑOR  : ${v('[testigo.nombres_apellidos]')}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text('DNI N° : ${v('[testigo.dni]')}'),
          pw.Text('DOMICILIO: ${v('[testigo.domicilio]')}'),
          pw.SizedBox(height: 16),

          // ── CUERPO ────────────────────────────────────────────
          pw.Text(
              '--- Sírvase Ud. concurrir a esta Dependencia Policial, '
              'sita en ${v('[dependencia.direccion]')}, '
              'el día ${v('[citacion.fecha_programada]')} '
              'a las ${v('[citacion.hora_programada]')} horas, '
              'para la diligencia de ${v('[citacion.motivo_diligencia]')}, '
              'dispuesta por ${v('[instructor.grado_nombres]')} '
              'en coordinación con el R.M.P.',
              textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 20),

          // ── CHECKBOXES DE NÚMERO DE CITACIÓN ─────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _checkboxRow('[${numCitacion == 1 ? 'X' : ' '}]  1ra. Citación.'),
                pw.SizedBox(height: 4),
                _checkboxRow('[${numCitacion == 2 ? 'X' : ' '}]  2da. Citación.'),
                pw.SizedBox(height: 4),
                _checkboxRow('[${numCitacion == 3 ? 'X' : ' '}]  3ra. Citación.'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── FIRMA DEL INSTRUCTOR ──────────────────────────────
          pw.Text('${v('[lugar.distrito]')}, ${v('[tiempo.fecha_hecho]')}'),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                pw.Text('_______________________________'),
                pw.Text('EL INSTRUCTOR',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(v('[instructor.grado_nombres]')),
                pw.Text('CIP N° ${v('[instructor.cip]')}'),
              ]),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(thickness: 0.5),

          // ── SECCIÓN "ENTERADO" ────────────────────────────────
          pw.Text('ENTERADO:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Fecha y hora: ${v('[tiempo.acta_hora_cierre]')}'),
          pw.Text('Nombres y Apellidos: ${v('[testigo.nombres_apellidos]')}'),
          pw.SizedBox(height: 25),
          pw.Text('Firma: ________________________   (Impresión Digital)'),
        ],
      ), includeFoliation, initialFolio)));
    
  
  }

  static Future<Uint8List> generateCitacionPolicialPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addCitacionPolicialPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 14: NOTIFICACIÓN POLICIAL (F-54)
  // Comunicación escrita formal de disposición superior.
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addNotificacionPolicialPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    pdf.addPage(pw.Page(pageFormat: _pnpPageFormat, margin: _pnpPageMargin, build: (ctx) => _wrapWithFoliation(ctx, pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── MEMBRETE ──────────────────────────────────────────
          pw.Center(
            child: pw.Column(children: [
              pw.Text('POLICÍA NACIONAL DEL PERÚ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.SizedBox(height: 3),
              pw.Text(v('[dependencia.nombre]'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'NOTIFICACIÓN POLICIAL N° ${v('[documento.numero_correlativo]')} - ${v('[documento.siglas_unidad]')}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      decoration: pw.TextDecoration.underline)),
            ]),
          ),
          pw.SizedBox(height: 30),

          // ── CUERPO ────────────────────────────────────────────
          pw.Text(
              '${v('[imputado.nombres_apellidos]')}, identificado con '
              'DNI N° ${v('[imputado.dni]')}, deberá presentarse a esta '
              'Dependencia Policial por motivo de ${v('[notificacion.causa]')}, '
              'por orden de ${v('[notificacion.superior_ordena]')}.',
              textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 24),
          pw.Text('${v('[lugar.distrito]')}, ${v('[tiempo.fecha_hecho]')}'),
          pw.SizedBox(height: 6),
          pw.Text('HORA: ${v('[tiempo.acta_hora_inicio]')}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

          pw.Spacer(),

          // ── FIRMA ─────────────────────────────────────────────
          pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('_______________________________'),
                pw.Text('EL INSTRUCTOR',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(v('[instructor.grado_nombres]')),
                pw.Text('CIP N° ${v('[instructor.cip]')}'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(thickness: 0.5),

          // ── SECCIÓN "ENTERADO" ────────────────────────────────
          pw.Text('ENTERADO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 25),
          pw.Text('Firma: ________________________   (Impresión Digital)'),
        ],
      ), includeFoliation, initialFolio)));
    
  
  }

  static Future<Uint8List> generateNotificacionPolicialPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addNotificacionPolicialPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA 15: ACTA DE INFORMACIÓN DE DERECHOS DE LA VÍCTIMA (F-09)
  // Autogenerada cuando hay un agraviado en la sesión.
  // Erradica el incumplimiento al Art. 95° del CPP.
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addDerechosVictimaPages(pw.Document pdf, 
      Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    // Detectar si el agraviado negó firmar
    final seNego = (tags['[firma.se_nego_imputado]'] ?? 'NO').toUpperCase();
    final hayNegativa = seNego == 'SI' || seNego == 'SÍ';

    pdf.addPage(pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
      
      
      build: (ctx) {
        final elements = <pw.Widget>[];

        // ── ENCABEZADO ──────────────────────────────────────────
        elements.add(pw.Center(child: pw.Column(children: [
          pw.Text('POLICÍA NACIONAL DEL PERÚ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.SizedBox(height: 4),
          pw.Text('ACTA DE INFORMACIÓN DE DERECHOS DE LA VÍCTIMA / AGRAVIADO',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  decoration: pw.TextDecoration.underline),
              textAlign: pw.TextAlign.center),
        ])));
        elements.add(pw.SizedBox(height: 18));

        // ── INTRO ────────────────────────────────────────────────
        elements.add(pw.Text(
            '--- En ${v('[lugar.distrito]')}, siendo las ${v('[tiempo.acta_hora_inicio]')} '
            'horas, del ${v('[tiempo.fecha_hecho]')}; presentes en ${v('[acta.lugar_redaccion]')}, '
            'el instructor ${v('[instructor.grado_nombres]')} procede a dar lectura de sus '
            'derechos constitucionales y procesales a la víctima / agraviado(a):',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 10));
        elements.add(pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Nombres y Apellidos: ${v('[agraviado.nombres_apellidos]')}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('DNI N°: ${v('[agraviado.dni]')} | Domicilio: ${v('[agraviado.domicilio]')}'),
          ]),
        ));
        elements.add(pw.SizedBox(height: 16));

        // ── DERECHOS (Art. 95° CPP) ───────────────────────────
        elements.add(pw.Text('DERECHOS QUE LE ASISTEN (Art. 95° CPP):',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 8));

        const derechos = [
          'A recibir un trato digno y respetuoso por parte de las autoridades competentes.',
          'A la protección de su integridad, incluyendo la de su familia.',
          'A ser informado sobre el resultado de las investigaciones.',
          'A ser escuchado antes de cada decisión que implique la extinción o suspensión de la acción penal.',
          'A recibir asistencia médica y psicológica.',
        ];

        for (var i = 0; i < derechos.length; i++) {
          elements.add(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 22,
                  child: pw.Text('${i + 1}.',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                    child: pw.Text(derechos[i],
                        textAlign: pw.TextAlign.justify)),
              ],
            ),
          ));
        }

        elements.add(pw.SizedBox(height: 14));
        elements.add(pw.Text(
            'El agraviado(a) manifiesta haber comprendido los derechos que le asisten '
            'y se le hace entrega de una copia del presente documento.',
            textAlign: pw.TextAlign.justify));

        // Motivo de negativa (condicional)
        if (hayNegativa) {
          elements.add(pw.SizedBox(height: 8));
          elements.add(pw.Text(v('[firma.motivo_negativa]'),
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              textAlign: pw.TextAlign.justify));
        }

        elements.add(pw.SizedBox(height: 14));
        elements.add(pw.Text(
            '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas del mismo día, '
            'se levanta la presente acta, firmando en señal de conformidad.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 50));

        // ── FIRMAS ───────────────────────────────────────────────
        elements.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Text('_________________________'),
              pw.Text('EL INSTRUCTOR PNP',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[instructor.grado_nombres]'),
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text('CIP N° ${v('[instructor.cip]')}',
                  style: const pw.TextStyle(fontSize: 9)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Text('_________________________'),
              pw.Text('EL AGRAVIADO / VÍCTIMA',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(v('[agraviado.nombres_apellidos]'),
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text('DNI N° ${v('[agraviado.dni]')}',
                  style: const pw.TextStyle(fontSize: 9)),
            ]),
          ],
        ));

        return elements;
      },
    ));
  }

  static Future<Uint8List> generateDerechosVictimaPdf(
      Map<String, String> tags) async {
    final pdf = pw.Document();
    await addDerechosVictimaPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA BASE: ACTA DE INTERVENCIÓN POLICIAL (F-12)
  // Acta troncal de la intervención con blindaje del Art. 67° CPP.
  // ═══════════════════════════════════════════════════════════════

  static String _toRoman(int number) {
    const romanNumerals = {
      1: 'I',
      2: 'II',
      3: 'III',
      4: 'IV',
      5: 'V',
      6: 'VI',
      7: 'VII',
      8: 'VIII',
      9: 'IX',
      10: 'X'
    };
    return romanNumerals[number] ?? number.toString();
  }

  static Future<void> addActaIntervencionPages(pw.Document pdf, 
      Map<String, String> tags, String tipificacion, List<String> documentosGenerados, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    String v(String t) => tags[t] ?? '_______________';

    pdf.addPage(pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
      build: (ctx) {
        final elements = <pw.Widget>[];

        // ── ENCABEZADO ──────────────────────────────────────────
        elements.add(pw.Center(child: pw.Column(children: [
          pw.Text('ACTA DE INTERVENCIÓN',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  decoration: pw.TextDecoration.underline),
              textAlign: pw.TextAlign.center),
        ])));
        elements.add(pw.SizedBox(height: 18));

        final String acompananteGrado = (tags['[acompanante.grado]'] ?? '').trim();
        final String acompananteNom = (tags['[acompanante.apellidos_nombres]'] ?? '').trim();
        final String acompananteCip = (tags['[acompanante.cip]'] ?? '').trim();
        final bool hasAcompanante = acompananteNom.isNotEmpty && acompananteNom != '_______________';

        final String acompananteInfo = hasAcompanante
            ? ' en compañía del efectivo policial $acompananteGrado $acompananteNom, identificado con CIP N° $acompananteCip; proceden '
            : '; procede ';

        // ── PÁRRAFO INTRODUCTORIO ─────────────────────────────────
        elements.add(pw.Text(
            '--- En la ciudad de ${v('[lugar.provincia]')}, Distrito de ${v('[lugar.distrito]')}, '
            'siendo las ${v('[tiempo.acta_hora_inicio]')} horas del día ${v('[tiempo.fecha_hecho]')}, '
            'en el lugar ubicado en ${v('[acta.lugar_redaccion]')}, el instructor PNP '
            '${v('[instructor.grado_nombres]')}, identificado con CIP N° ${v('[instructor.cip]')}$acompananteInfo'
            'a formular la presente Acta de Intervención Policial, bajo los siguientes términos:',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 16));

        // ── BLOQUE CONDICIONAL: IDENTIFICACIÓN DE PARTICIPANTES ──
        final imputadoNom = (tags['[imputado.nombres_apellidos]'] ?? '').trim();
        final agraviadoNom = (tags['[agraviado.nombres_apellidos]'] ?? '').trim();
        final testigoNom = (tags['[testigo.nombres_apellidos]'] ?? '').trim();

        final conDetenidoTag = tags['[intervencion.con_detenido]'] ?? 'SI';
        final esConDetenido = conDetenidoTag == 'SI';

        final hasImputado = esConDetenido && imputadoNom.isNotEmpty && imputadoNom != '_______________';
        final hasAgraviado = agraviadoNom.isNotEmpty && agraviadoNom != '_______________';
        final hasTestigo = testigoNom.isNotEmpty && testigoNom != '_______________';

        final tieneParticipantes = hasImputado || hasAgraviado || hasTestigo;

        int numeroBloque = 1;

        if (tieneParticipantes) {
          elements.add(pw.Text('${_toRoman(numeroBloque)}. IDENTIFICACIÓN DE PARTICIPANTES:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
          numeroBloque++;
          elements.add(pw.SizedBox(height: 6));
          elements.add(pw.Text(
              'Se deja constancia de la presencia e identificación de las siguientes personas vinculadas a la intervención:',
              textAlign: pw.TextAlign.justify));
          elements.add(pw.SizedBox(height: 6));

          if (hasImputado) {
            elements.add(pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• Condición: Intervenido', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                  pw.Text('  Nombres y Apellidos: ${v('[imputado.nombres_apellidos]')}', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('  DNI: ${v('[imputado.dni]')} | Edad: ${v('[imputado.edad]')} | Celular: ${v('[imputado.telefono]')}', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('  Domicilio: ${v('[imputado.domicilio]')}', style: const pw.TextStyle(fontSize: 9.5)),
                ],
              ),
            ));
          }
          if (hasAgraviado) {
            elements.add(pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• Condición: Agraviado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                  pw.Text('  Nombres y Apellidos: ${v('[agraviado.nombres_apellidos]')}', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('  DNI: ${v('[agraviado.dni]')} | Edad: ${tags['[agraviado.edad]'] ?? '___'} | Celular: ${tags['[agraviado.telefono]'] ?? '___'}', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('  Domicilio: ${v('[agraviado.domicilio]')}', style: const pw.TextStyle(fontSize: 9.5)),
                ],
              ),
            ));
          }
          if (hasTestigo) {
            elements.add(pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• Condición: Testigo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                  pw.Text('  Nombres y Apellidos: ${v('[testigo.nombres_apellidos]')}', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('  DNI: ${v('[testigo.dni]')} | Edad: ${tags['[testigo.edad]'] ?? '___'} | Celular: ${v('[testigo.telefono]')}', style: const pw.TextStyle(fontSize: 9.5)),
                  pw.Text('  Domicilio: ${v('[testigo.domicilio]')}', style: const pw.TextStyle(fontSize: 9.5)),
                ],
              ),
            ));
          }

          if (hasImputado) {
            elements.add(pw.Text(
                '(A los intervenidos se les informó expresamente el motivo de su detención y se procedió a la lectura de sus derechos constitucionales).',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9.5),
                textAlign: pw.TextAlign.justify));
            elements.add(pw.SizedBox(height: 16));
          }
        }

        // ── BLOQUE II: MOTIVACIÓN Y CIRCUNSTANCIAS DE LA INTERVENCIÓN (Obligatorio) ──
        elements.add(pw.Text('${_toRoman(numeroBloque)}. MOTIVACIÓN Y CIRCUNSTANCIAS DE LA INTERVENCIÓN:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 8));
        elements.add(pw.Text(v('[narrativa.hechos]'), textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 16));
        numeroBloque++;

        // ── BLOQUE III: COMUNICACIÓN AL MINISTERIO PÚBLICO (Condicional) ──
        final requiereFiscal = tags['[intervencion.requiere_fiscal]'] != 'NO';
        
        elements.add(pw.Text('${_toRoman(numeroBloque)}. COMUNICACIÓN AL MINISTERIO PÚBLICO (Art. 67° CPP):',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 8));
        
        if (requiereFiscal) {
          elements.add(pw.Text(
              'Se comunicó del hecho al Representante del Ministerio Público a las ${v('[fiscal.hora_comunicacion]')} horas, '
              'mediante el equipo celular N° ${v('[fiscal.telefono_usado]')}, contestando el fiscal ${v('[fiscal.grado_nombres]')}, '
              'de la ${v('[fiscal.fiscalia]')}, quien dispuso lo siguiente: ${v('[fiscal.resultado_comunicacion]')}.',
              textAlign: pw.TextAlign.justify));
        } else {
          elements.add(pw.Text(
              'Se deja constancia que no fue posible la comunicación inmediata con el Representante del Ministerio Público debido a: ${v('[fiscal.motivo_no_comunicacion]')}.',
              textAlign: pw.TextAlign.justify));
        }
        elements.add(pw.SizedBox(height: 16));
        numeroBloque++;

        // ── BLOQUE IV: DILIGENCIAS EFECTUADAS Y ACTAS ANEXAS ───────────
        elements.add(pw.Text('${_toRoman(numeroBloque)}. DILIGENCIAS EFECTUADAS Y ACTAS ANEXAS:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 8));
        elements.add(pw.Text(
            'Para perennizar la presente actuación policial in situ, se anexan los siguientes documentos:',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 8));

        for (var doc in documentosGenerados) {
          if (!doc.contains('Acta de Intervención') && !doc.contains('Parte Policial')) {
            elements.add(pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
              child: pw.Text('- $doc'),
            ));
          }
        }
        elements.add(pw.SizedBox(height: 16));
        numeroBloque++;

        // ── BLOQUE V: CONSTANCIA DE FIRMA ───────────
        elements.add(pw.Text('${_toRoman(numeroBloque)}. CONSTANCIA DE FIRMA:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        elements.add(pw.SizedBox(height: 8));
        elements.add(pw.Text('"De ser el caso" Indicar la razón por la que el intervenido/participante no puede o no quiere firmar el acta:',
            style: const pw.TextStyle(fontSize: 10)));
        elements.add(pw.SizedBox(height: 4));
        elements.add(pw.Text(v('[firma.motivo_negativa]'),
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 14));

        // ── CIERRE ────────────────────────────────────────────────
        elements.add(pw.Text(
            '--- Siendo las ${v('[tiempo.acta_hora_cierre]')} horas del mismo día, '
            'previa lectura, se dio por concluida la presente diligencia, firmando los intervinientes '
            'en señal de conformidad.',
            textAlign: pw.TextAlign.justify));
        elements.add(pw.SizedBox(height: 50));

        // ── FIRMAS ───────────────────────────────────────────────
        pw.Widget rightSignWidget;

        if (tieneParticipantes) {
          String cond = 'PARTICIPANTE';
          String nombre = '_______________';
          String dni = '_______________';

          if (hasImputado) {
            cond = 'EL INTERVENIDO';
            nombre = v('[imputado.nombres_apellidos]');
            dni = v('[imputado.dni]');
          } else if (hasAgraviado) {
            cond = 'EL AGRAVIADO';
            nombre = v('[agraviado.nombres_apellidos]');
            dni = v('[agraviado.dni]');
          } else if (hasTestigo) {
            cond = 'EL TESTIGO';
            nombre = v('[testigo.nombres_apellidos]');
            dni = v('[testigo.dni]');
          }

          rightSignWidget = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text(cond, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(nombre, style: const pw.TextStyle(fontSize: 9)),
              pw.Text('DNI N° $dni', style: const pw.TextStyle(fontSize: 9)),
            ],
          );
        } else {
          // Si no hay participantes, se dibuja un bloque de firma en blanco para el intervenido
          rightSignWidget = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('_________________________'),
              pw.Text('EL INTERVENIDO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text('_______________', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('DNI N° _______________', style: const pw.TextStyle(fontSize: 9)),
            ],
          );
        }

        elements.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('_________________________'),
                pw.Text('EL INSTRUCTOR PNP',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Text(v('[instructor.grado_nombres]'),
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('CIP N° ${v('[instructor.cip]')}',
                    style: const pw.TextStyle(fontSize: 9)),
                if (hasAcompanante) ...[
                  pw.SizedBox(height: 30),
                  pw.Text('_________________________'),
                  pw.Text('EFECTIVO PNP INTERVINIENTE',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text('$acompananteGrado $acompananteNom',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('CIP N° $acompananteCip',
                      style: const pw.TextStyle(fontSize: 9)),
                ]
              ],
            ),
            rightSignWidget,
          ],
        ));

        return elements;
      },
    ));
  }

  static Future<Uint8List> generateActaIntervencionPdf(
      Map<String, String> tags, String tipificacion, List<String> documentosGenerados) async {
    final pdf = pw.Document();
    await addActaIntervencionPages(pdf, tags, tipificacion, documentosGenerados, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ─── HELPER: renderiza una fila de checkbox para citaciones ───
  static pw.Widget _checkboxRow(String texto) {
    return pw.Text(texto,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold));
  }

  // ─── PLANTILLA 13: HOJA DE DATOS DE IDENTIFICACIÓN (Formato 38) ───
  
  static Future<void> addHojaIdentificacionPages(pw.Document pdf, Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    pdf.addPage(pw.Page(
      pageFormat: _pnpPageFormat,
      margin: _pnpPageMargin,
      build: (pw.Context context) {
        return _wrapWithFoliation(context, pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(v('[acta.dependencia_policial]').toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 15),
                  pw.Text('HOJA DE DATOS DE IDENTIFICACIÓN N° ${v('[documento.numero_correlativo]')} - ${v('[documento.siglas_unidad]')}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, decoration: pw.TextDecoration.underline)),
                ],
              ),
            ),
            pw.SizedBox(height: 25),
            pw.Text('APELLIDOS                 : ${v('[imputado.apellidos]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('NOMBRES                   : ${v('[imputado.nombres]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('EDAD                      : ${v('[imputado.edad]')} AÑOS', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('NACIONALIDAD              : ${v('[imputado.nacionalidad]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('PROFESIÓN U OCUPACIÓN     : ${v('[imputado.ocupacion]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('DNI – PASAPORTE U OTROS\nDOCUMENTOS DE IDENTIDAD   : ${v('[imputado.dni]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('DIRECCIÓN DOMICILIARIA    : ${v('[imputado.domicilio]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('CENTRO DE TRABAJO         : ${v('[imputado.lugar_trabajo]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('DIRECCIÓN                 : ${v('[imputado.direccion_trabajo]').toUpperCase()}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('MOTIVO DE LA INTERVENCIÓN : ${v('[intervencion.motivo]')}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('DOCUMENTO REDACTADO       : ${v('[intervencion.documento_redactado]')}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('SEÑAS PARTICULARES        : ${v('[imputado.senas_particulares]')}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('OBSERVACIONES             : ${v('[intervencion.observaciones]')}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 25),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text('${v('[lugar.distrito]')}, ${v('[tiempo.fecha_hecho]')}', style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('_________________________'),
                  pw.Text('INSTRUCTOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text(v('[instructor.grado_nombres]'), style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('CIP N° ${v('[instructor.cip]')}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ],
        ), includeFoliation, initialFolio);
      }));

    
  
  }

  static Future<Uint8List> generateHojaIdentificacionPdf(Map<String, String> tags) async {
    final pdf = pw.Document();
    await addHojaIdentificacionPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ─── PLANTILLA 14: HOJA BÁSICA DE REQUISITORIA (Formato 37) ───
  
  static Future<void> addHojaRequisitoriaPages(pw.Document pdf, Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    
    String v(String t) => tags[t] ?? '_______________';

    pdf.addPage(pw.Page(
      pageFormat: _pnpPageFormat,
      margin: _pnpPageMargin,
      build: (pw.Context context) {
        return _wrapWithFoliation(context, pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(v('[acta.dependencia_policial]').toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 15),
                  pw.Text('HOJA BÁSICA DE REQUISITORIA Nº ${v('[documento.numero_correlativo]')} - ${v('[documento.siglas_unidad]')}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, decoration: pw.TextDecoration.underline)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('1. DATOS PERSONALES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text('Apellidos y Nombres : ${v('[imputado.apellidos]').toUpperCase()} ${v('[imputado.nombres]').toUpperCase()}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text('Fecha de Nacimiento : ${v('[imputado.fecha_nacimiento]')} | Lugar: ${v('[imputado.lugar_nacimiento]')}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text('DNI (Pasaporte, Carné de Extranjería u otros) Nº: ${v('[imputado.dni]')}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text('Hijo de             : ${v('[imputado.nombre_padre]')} y de ${v('[imputado.nombre_madre]')}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text('Grado de Instrucción: ${v('[imputado.grado_instruccion]')}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text('Profesión           : ${v('[imputado.profesion]')} | Ocupación actual: ${v('[imputado.ocupacion]')}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text('Domicilio           : ${v('[imputado.domicilio]')}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 15),
            pw.Text('2. CARACTERÍSTICAS FÍSICAS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text(v('[imputado.caracteristicas_fisicas]'), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 25),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text('Lugar y Fecha: ${v('[lugar.distrito]')}, ${v('[tiempo.fecha_hecho]')}', style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.SizedBox(height: 35),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('ES CONFORME', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('_________________________'),
                    pw.Text('EL INSTRUCTOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(v('[instructor.grado_nombres]'), style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('CIP N° ${v('[instructor.cip]')}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ],
        ), includeFoliation, initialFolio);
      }));

    
  
  }

  static Future<Uint8List> generateHojaRequisitoriaPdf(Map<String, String> tags) async {
    final pdf = pw.Document();
    await addHojaRequisitoriaPages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  // ═══════════════════════════════════════════════════════════════
  // PLANTILLA A-6: RÓTULO DE INDICIOS / EVIDENCIAS / ELEMENTOS RECOGIDOS
  // Cadena de Custodia del Ministerio Público
  // ═══════════════════════════════════════════════════════════════
  
  static Future<void> addRotuloA6Pages(pw.Document pdf, Map<String, String> tags, {bool includeFoliation = false, int initialFolio = 1, String? piePagina}) async {

    

    final List<RotuloBien> bienes = _parseBienesParaRotulo(
      tags['[registro.bienes_detalle]'] ?? '',
      tags['[registro.descripcion_bien_buscado]'] ?? '',
      tags['[registro.bienes_hallados]'] ?? '',
      tags['[registro.bienes_recepcionados]'] ?? '',
      tags['[registro.bienes_hallados_vehiculo]'] ?? '',
    );

    pdf.addPage(
      pw.MultiPage(pageTheme: _getPnpPageTheme(), header: includeFoliation ? _buildFoliationHeader(initialFolio) : null,
        footer: (piePagina != null && piePagina.trim().isNotEmpty) ? _buildFooter(piePagina) : null, 
        
        
        build: (pw.Context context) {
          List<pw.Widget> elements = [];

          for (var bien in bienes) {
            elements.add(_buildRotuloCard(bien, tags));
            elements.add(pw.SizedBox(height: 15));
          }

          return elements;
        },
      ),
    );

    
  
  }

  static Future<Uint8List> generateRotuloA6Pdf(Map<String, String> tags) async {
    final pdf = pw.Document();
    await addRotuloA6Pages(pdf, tags, includeFoliation: false, initialFolio: 1, piePagina: null);
    return pdf.save();
  }


  static pw.Widget _buildRotuloCard(RotuloBien bien, Map<String, String> tags) {
    String v(String tag) => tags[tag] ?? '_______________';

    return pw.Container(
      width: 480,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Encabezado
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'MINISTERIO PÚBLICO - FISCALÍA DE LA NACIÓN',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.Text(
                  'FORMATO A - 6',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
                pw.Text(
                  'RÓTULO DE INDICIOS / EVIDENCIAS / ELEMENTOS RECOGIDOS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                ),
                pw.Text(
                  '(EN CADENA DE CUSTODIA)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                ),
              ],
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.black),
          pw.SizedBox(height: 5),

          // Datos del indicio
          pw.Text(
            'NÚMERO DE HALLAZGO: ${bien.numero}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text(
                'CANTIDAD: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
              pw.Text(
                bien.cantidad,
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(width: 25),
              pw.Text(
                'UNIDAD DE MEDIDA: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
              pw.Text(
                bien.unidad,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'DESCRIPCIÓN DEL BIEN:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.Text(
            bien.descripcion,
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),

          // Servidor
          pw.Text(
            'SERVIDOR QUE RECOLECTA EL BIEN:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'NOMBRE COMPLETO: ${v('[instructor.grado_nombres]')}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'DNI / CIP Nº: ${v('[instructor.cip]')}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'CARGO: INSTRUCTOR PNP',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'FIRMA: ____________________________________',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 6),

          // Datos de control de tiempo
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'FECHA DE EMBALAJE: ${v('[tiempo.fecha_hecho]')}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'HORA (0-24): ${v('[tiempo.acta_hora_cierre]')}',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<RotuloBien> _parseBienesParaRotulo(
    String rawBienes,
    String bienBuscado,
    String bienesHallados,
    String bienesRecepcionados,
    String bienesVehiculo,
  ) {
    List<RotuloBien> list = [];
    String dataToParse = rawBienes.trim();
    if (dataToParse.isEmpty || dataToParse == '_______________') {
      dataToParse = bienesHallados.trim();
    }
    if (dataToParse.isEmpty || dataToParse == '_______________') {
      dataToParse = bienesRecepcionados.trim();
    }
    if (dataToParse.isEmpty || dataToParse == '_______________') {
      dataToParse = bienesVehiculo.trim();
    }
    if (dataToParse.isEmpty || dataToParse == '_______________') {
      dataToParse = bienBuscado.trim();
    }

    if (dataToParse.isEmpty || dataToParse == '_______________') {
      list.add(RotuloBien(
        numero: '01',
        cantidad: '_______________',
        unidad: '_______________',
        descripcion: '_______________',
      ));
      return list;
    }

    final lines = dataToParse.split(RegExp(r'[\n\r]+'));
    int index = 1;
    for (var line in lines) {
      var trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Clean leading bullet and number indicators
      trimmed = trimmed.replaceFirst(RegExp(r'^[-*•●■]\s*'), '');
      trimmed = trimmed.replaceFirst(RegExp(r'^\d+\s*[\.\)]\s*'), '');
      trimmed = trimmed.trim();

      if (trimmed.isEmpty) continue;

      // Regex parser for quantity and unit
      final match = RegExp(
        r'^(\d+)\s+(gramos|g|kg|kilos|unidades|und|paquetes|bolsas|bolsa|sobres|sobre|envoltorios|ketes|kete|unid|unidades|celulares|celular|botellas|botella|teléfonos|teléfono|telefono|telefonos|equipos|equipo|paquete|bolsitas|bolsita)\s*(?:de\s+)?(.*)$',
        caseSensitive: false,
      ).firstMatch(trimmed);

      String cantidad = '1';
      String unidad = 'UNIDAD';
      String descripcion = trimmed;

      if (match != null) {
        cantidad = match.group(1) ?? '1';
        final rawUnidad = match.group(2);
        if (rawUnidad != null) {
          unidad = rawUnidad.toUpperCase();
        } else {
          unidad = 'UNIDAD';
        }
        descripcion = match.group(3) ?? '';
        if (descripcion.isEmpty) {
          descripcion = trimmed;
        }
      } else {
        // Text-based word parser for word numbers: un, una, dos, etc.
        final wordMatch = RegExp(
          r'^(un|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez)\s+(gramos|g|kg|kilos|unidades|und|paquetes|bolsas|bolsa|sobres|sobre|envoltorios|ketes|kete|unid|unidades|celulares|celular|botellas|botella|teléfonos|teléfono|telefono|telefonos|equipos|equipo|paquete|bolsitas|bolsita)\s*(?:de\s+)?(.*)$',
          caseSensitive: false,
        ).firstMatch(trimmed);
        if (wordMatch != null) {
          var wordNum = wordMatch.group(1)?.toLowerCase() ?? '1';
          final wordMap = {
            'un': '1', 'una': '1', 'dos': '2', 'tres': '3', 'cuatro': '4',
            'cinco': '5', 'seis': '6', 'siete': '7', 'ocho': '8', 'nueve': '9', 'diez': '10'
          };
          cantidad = wordMap[wordNum] ?? wordNum;
          final rawUnidad = wordMatch.group(2);
          if (rawUnidad != null) {
            unidad = rawUnidad.toUpperCase();
          } else {
            unidad = 'UNIDAD';
          }
          descripcion = wordMatch.group(3) ?? '';
          if (descripcion.isEmpty) {
            descripcion = trimmed;
          }
        } else {
          // Simple number fallback
          final simpleNumMatch = RegExp(r'^(\d+)\s+(.*)$').firstMatch(trimmed);
          if (simpleNumMatch != null) {
            cantidad = simpleNumMatch.group(1) ?? '1';
            unidad = 'UNIDAD';
            descripcion = simpleNumMatch.group(2) ?? '';
          } else {
            cantidad = '1';
            unidad = 'UNIDAD';
            descripcion = trimmed;
          }
        }
      }

      list.add(RotuloBien(
        numero: index.toString().padLeft(2, '0'),
        cantidad: cantidad,
        unidad: unidad,
        descripcion: descripcion,
      ));
      index++;
    }

    return list;
  }
}

class RotuloBien {
  final String numero;
  final String cantidad;
  final String unidad;
  final String descripcion;

  RotuloBien({
    required this.numero,
    required this.cantidad,
    required this.unidad,
    required this.descripcion,
  });
}

