import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'crypto_service.dart';
import 'pdf_service.dart';
import '../widgets/export_config_dialog.dart';

/// Modelo ligero que representa un acta lista para empaquetar.
/// Contiene los bytes del PDF individual generado, el título del documento
/// y la hora de inicio (para ordenamiento cronológico).
class ActaParaEmpaquetar {
  final Uint8List pdfBytes;
  final String titulo;
  final String horaInicio; // Formato "HH:MM" para comparación lexicográfica

  const ActaParaEmpaquetar({
    required this.pdfBytes,
    required this.titulo,
    required this.horaInicio,
  });
}

// ════════════════════════════════════════════════════════════════════
// MÁRGENES OFICIALES — Manual de Documentación Policial PNP
//   • Izquierdo : 3.5 cm (reservado para engargolado / cosido)
//   • Derecho   : 2.0 cm
//   • Superior  : 2.5 cm
//   • Inferior  : 2.5 cm
// ════════════════════════════════════════════════════════════════════
const _margenIzq = 3.5 * PdfPageFormat.cm;
const _margenDer = 2.0 * PdfPageFormat.cm;
const _margenSup = 2.5 * PdfPageFormat.cm;
const _margenInf = 2.5 * PdfPageFormat.cm;

/// Servicio que actúa como "Oficial de Trámite Documentario Digital".
/// Toma las actas individuales generadas por [PdfService], las ordena
/// según la doctrina PNP, las fusiona en un PDF maestro con foliación
/// automática y sella el expediente con un hash SHA-256.
class EmpaquetadorService {
  // ─── CONSTANTES DE FOLIACIÓN ──────────────────────────────────────
  static const _fontSizeFolio = 11.0;
  // static const _fontSizeContenido = 10.5;
  static const _fontSizeCertificacion = 9.5;

  /// Punto de entrada principal del empaquetador.
  /// Retorna los bytes del PDF maestro sellado y listo para imprimir.
  static Future<Uint8List> empaquetarCarpetaFiscal({
    required List<ActaParaEmpaquetar> actas,
    required Map<String, String> tags,
    required String nombreIntervencion,
    ExportConfig? config,
  }) async {
    // ── PASO 1: ORDENAMIENTO DOCTRINAL ────────────────────────────
    // El Parte Policial (Folio 01) va SIEMPRE primero.
    // El resto se ordena cronológicamente por hora de inicio.
    final actasOrdenadas = List<ActaParaEmpaquetar>.from(actas);
    actasOrdenadas.sort((a, b) {
      final aEsParte = a.titulo.toLowerCase().contains('parte policial');
      final bEsParte = b.titulo.toLowerCase().contains('parte policial');
      if (aEsParte) return -1;
      if (bEsParte) return 1;
      return a.horaInicio.compareTo(b.horaInicio);
    });

    // ── PASO 2: CONSTRUCCIÓN DEL PDF MAESTRO ─────────────────────
    final pdfMaestro = pw.Document(
      title: 'Carpeta Fiscal — $nombreIntervencion',
      author: 'ACTIUM — Sistema de Gestión Policial',
      creator: 'EmpaquetadorService v1.0',
    );

    
    final isCarpeta = config?.isCarpetaFiscal ?? true;
    final includeFoliation = config != null && config.folioInicial.trim().isNotEmpty;
    final folioStr = config?.folioInicial.trim();
    int initialFolio = 1;
    if (folioStr != null && int.tryParse(folioStr) != null) {
      initialFolio = int.parse(folioStr);
    }

    // Portada del expediente
    if (isCarpeta) {
      _agregarPortada(pdfMaestro, tags, nombreIntervencion, actasOrdenadas);
    }


    // ── PASO 3: INYECCIÓN DE ACTAS REALES CON FOLIACIÓN ─────────────────
    for (final acta in actasOrdenadas) {
      await PdfService.appendDocumentPages(
        pdfMaestro,
        acta.titulo,
        tags,
        tipificacion: tags['typification'] ?? tags['[delito.tipificacion]'] ?? '',
        docTitles: actasOrdenadas.map((a) => a.titulo).toList(),
        includeFoliation: includeFoliation,
        initialFolio: initialFolio,
        piePagina: config?.piePagina,
      );
    }

    int folioActual = pdfMaestro.document.pdfPageList.pages.length + 1;

    // ── PASO 4: SERIALIZACIÓN PROVISIONAL PARA HASH ───────────────
    // Guardamos el PDF sin hash para calcular el digest.
    final bytesProvisionales = await pdfMaestro.save();

    // ── PASO 5: HASH SHA-256 DEL EXPEDIENTE COMPLETO ─────────────
    final hashRaw = CryptoService.generarHashFiscal(bytesProvisionales);
    final hashFormateado = CryptoService.formatearHash(hashRaw);

    // ── PASO 6: PÁGINA DE CERTIFICACIÓN DE INTEGRIDAD ─────────────
    if (isCarpeta) {
      _agregarCertificacionHash(
      pdfMaestro,
      hashFormateado: hashFormateado,
      folioActual: folioActual,
      tags: tags,
      nombreIntervencion: nombreIntervencion,
      totalActas: actasOrdenadas.length,
      totalFolios: folioActual,
    );
    }

    // Retornar el PDF final sellado
    return pdfMaestro.save();
  }

  // ─── PORTADA DEL EXPEDIENTE ───────────────────────────────────────
  static void _agregarPortada(
    pw.Document pdf,
    Map<String, String> tags,
    String nombreIntervencion,
    List<ActaParaEmpaquetar> actas,
  ) {
    String v(String tag) => tags[tag] ?? '_______________';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: _margenIzq,
          marginRight: _margenDer,
          marginTop: _margenSup,
          marginBottom: _margenInf,
        ),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Folio 01 en portada
              pw.Positioned(
                right: 0,
                top: 0,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                  child: pw.Text(
                    'Folio 01',
                    style: pw.TextStyle(
                      fontSize: _fontSizeFolio,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

              pw.Column(
                children: [
                  pw.SizedBox(height: 30),
                  pw.Center(
                    child: pw.Column(
                      children: [
                          pw.Text('CARPETA FISCAL',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          nombreIntervencion,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 40),
                      ],
                    ),
                  ),

                  // Datos del expediente
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey700),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _campoPortada('INTERVENIDO',
                            v('[imputado.nombres_apellidos]')),
                        _campoPortada('DNI', v('[imputado.dni]')),
                        _campoPortada('TIPIFICACIÓN',
                            tags['typification'] ?? v('[tipificacion.delito]')),
                        _campoPortada(
                            'FECHA DE INTERVENCIÓN', v('[tiempo.fecha_hecho]')),
                        _campoPortada('LUGAR', v('[lugar.distrito]')),
                        _campoPortada('INSTRUCTOR',
                            v('[instructor.grado_nombres]')),
                        _campoPortada('CIP', v('[instructor.cip]')),
                        _campoPortada('REGISTRO SIGE',
                            v('[sige.numero_registro]')),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // Índice de documentos
                  pw.Text(
                    'DOCUMENTOS QUE INTEGRAN EL EXPEDIENTE:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: List.generate(actas.length, (i) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          '${(i + 1).toString().padLeft(2, '0')}. ${actas[i].titulo}',
                          style: pw.TextStyle(fontSize: 9.5),
                        ),
                      );
                    }),
                  ),

                  pw.Spacer(),
                  pw.Divider(thickness: 0.3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ACTIUM — Sistema de Gestión Policial',
                          style: pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text('Folio 01 de ${context.pagesCount}',
                          style: pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── PÁGINA DE CERTIFICACIÓN DE HASH ─────────────────────────────
  static void _agregarCertificacionHash(
    pw.Document pdf, {
    required String hashFormateado,
    required int folioActual,
    required Map<String, String> tags,
    required String nombreIntervencion,
    required int totalActas,
    required int totalFolios,
  }) {
    String v(String tag) => tags[tag] ?? '_______________';
    final folioLabel = folioActual.toString().padLeft(2, '0');
    final ahora = DateTime.now();
    final fechaGeneracion =
        '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}';
    final horaGeneracion =
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: _margenIzq,
          marginRight: _margenDer,
          marginTop: _margenSup,
          marginBottom: _margenInf,
        ),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Folio de la última página
              pw.Positioned(
                right: 0,
                top: 0,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                  child: pw.Text(
                    'Folio $folioLabel',
                    style: pw.TextStyle(
                      fontSize: _fontSizeFolio,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 30),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'CERTIFICACIÓN DE INTEGRIDAD DOCUMENTAL',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Sistema de Sellado Criptográfico ACTIUM',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text(
                    'El presente expediente denominado "$nombreIntervencion", conformado por $totalActas actas y $totalFolios folios en total, fue generado y sellado digitalmente por el Sistema ACTIUM el día $fechaGeneracion a las $horaGeneracion horas.',
                    style: pw.TextStyle(fontSize: _fontSizeCertificacion),
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 16),

                  pw.Text(
                    'HASH SHA-256 DE LA CARPETA FISCAL:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: _fontSizeCertificacion + 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 1.0),
                      color: PdfColors.grey100,
                    ),
                    child: pw.Text(
                      hashFormateado,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  pw.Text(
                    'INSTRUCCIONES PARA VERIFICACIÓN DE INTEGRIDAD:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: _fontSizeCertificacion,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '1. El hash SHA-256 estampado en este folio es la "huella digital" única e irrepetible de este expediente.\n'
                    '2. Cualquier alteración —por mínima que sea— de cualquier acta contenida en este expediente producirá un hash diferente.\n'
                    '3. La Fiscalía o el Juzgado puede verificar la integridad del documento original procesando el archivo digital en cualquier herramienta SHA-256 estándar y comparando el resultado con el código impreso en este folio.\n'
                    '4. Si los hashes coinciden, el expediente no ha sido alterado desde su generación.',
                    style: pw.TextStyle(fontSize: _fontSizeCertificacion - 0.5),
                    textAlign: pw.TextAlign.justify,
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text(
                    'DATOS DEL EXPEDIENTE:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: _fontSizeCertificacion,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  _campoPortada('INSTRUCTOR', v('[instructor.grado_nombres]')),
                  _campoPortada('CIP N°', v('[instructor.cip]')),
                  _campoPortada('REGISTRO SIGE', v('[sige.numero_registro]')),
                  _campoPortada('PARTE N°',
                      '${v('[documento.numero_correlativo]')} - ${v('[documento.siglas_unidad]')}'),
                  _campoPortada('TOTAL DE FOLIOS', '$totalFolios'),

                  pw.Spacer(),

                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text('________________________________',
                            style: pw.TextStyle(fontSize: 10)),
                        pw.Text('FIRMA DEL INSTRUCTOR RESPONSABLE',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text(v('[instructor.grado_nombres]'),
                            style: pw.TextStyle(fontSize: 9)),
                        pw.Text('CIP N° ${v('[instructor.cip]')}' ,
                            style: pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(thickness: 0.3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ACTIUM — Sellado el $fechaGeneracion $horaGeneracion h.',
                          style: pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text('Folio $folioLabel de $totalFolios',
                          style: pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────



  /// Widget de campo de datos para portada y certificación.
  static pw.Widget _campoPortada(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              '$etiqueta:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9.5,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              valor.isEmpty ? '_______________' : valor,
              style: pw.TextStyle(fontSize: 9.5),
            ),
          ),
        ],
      ),
    );
  }
}
