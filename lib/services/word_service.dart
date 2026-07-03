import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../models/intervention_session.dart';
import '../widgets/export_config_dialog.dart';

class WordService {
  /// Genera un documento "Word" (HTML enriquecido con extensión .doc)
  /// basándose en los documentos editados de la sesión.
  static Future<void> exportarCarpetaWord(
    InterventionSession session,
    Map<String, String> tags,
    ExportConfig? config,
  ) async {
    final isCarpeta = config?.isCarpetaFiscal ?? true;
    final buffer = StringBuffer();
    final nombreIntervencion = session.name;

    buffer.writeln('<html><head><meta charset="utf-8"></head><body style="font-family: Arial, sans-serif; font-size: 11pt; line-height: 1.5;">');

    // ── PORTADA ──
    if (isCarpeta) {
      buffer.writeln('<div style="text-align: center; margin-bottom: 50px;">');
      buffer.writeln('<h1>POLICÍA NACIONAL DEL PERÚ</h1>');
      buffer.writeln('<h2>CARPETA FISCAL</h2>');
      buffer.writeln('<h3>$nombreIntervencion</h3>');
      
      final tipificacion = tags['typification'] ?? tags['[delito.tipificacion]'] ?? 'NO ESPECIFICADO';
      buffer.writeln('<p><b>TIPIFICACIÓN:</b> $tipificacion</p>');
      
      final dt = DateTime.now();
      buffer.writeln('<p><b>FECHA DE IMPRESIÓN:</b> ${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}</p>');
      
      buffer.writeln('<p><b>ACTAS CONTENIDAS:</b></p>');
      buffer.writeln('<ul style="list-style-type: none; padding: 0;">');
      for (var act in session.documents) {
        buffer.writeln('<li>- ${act.title}</li>');
      }
      buffer.writeln('</ul>');
      buffer.writeln('</div>');
      buffer.writeln('<hr style="page-break-after: always;">');
    }

    // ── ACTAS ──
    for (int i = 0; i < session.documents.length; i++) {
      final doc = session.documents[i];
      buffer.writeln('<h3 style="text-align: center; text-decoration: underline;">${doc.title.toUpperCase()}</h3>');
      
      // Parsear contenido de Quill Delta a Texto Plano
      String plainText = '';
      if (doc.content.isNotEmpty) {
        try {
          final deltaJson = jsonDecode(doc.content);
          final document = quill.Document.fromJson(deltaJson);
          plainText = document.toPlainText();
        } catch (e) {
          plainText = 'Error al leer el contenido del documento.';
        }
      }

      // Convertir saltos de línea en <p> o <br>
      final paragraphs = plainText.split('\n');
      for (var p in paragraphs) {
        if (p.trim().isEmpty) {
          buffer.writeln('<br>');
        } else {
          buffer.writeln('<p style="text-align: justify; margin-bottom: 8px;">${_escapeHtml(p)}</p>');
        }
      }

      if (i < session.documents.length - 1) {
        buffer.writeln('<hr style="page-break-after: always;">');
      }
    }

    buffer.writeln('</body></html>');

    // Convertir String HTML a bytes
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));

    final ts = DateTime.now().millisecondsSinceEpoch;
    final name = session.name.replaceAll(' ', '_');
    final fileName = 'Carpeta_Fiscal_${name}_$ts.doc';

    // Imprimir o Compartir usando el plugin Printing (funciona con cualquier archivo)
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static String _escapeHtml(String text) {
    return text.replaceAll('&', '&amp;')
               .replaceAll('<', '&lt;')
               .replaceAll('>', '&gt;')
               .replaceAll('"', '&quot;')
               .replaceAll("'", '&#39;');
  }
}
