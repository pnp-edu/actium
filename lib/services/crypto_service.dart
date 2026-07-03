import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Servicio criptográfico para el sellado de integridad de la Carpeta Fiscal.
/// Genera un hash SHA-256 único sobre el contenido binario del PDF maestro.
/// Este hash actúa como "sello digital" que acredita que el expediente
/// no fue alterado después de su generación.
class CryptoService {
  /// Genera el hash SHA-256 del contenido binario del PDF y retorna
  /// la huella en formato hexadecimal mayúscula (64 caracteres).
  static String generarHashFiscal(Uint8List pdfBytes) {
    final digest = sha256.convert(pdfBytes);
    return digest.toString().toUpperCase();
  }

  /// Formatea el hash en bloques de 8 caracteres para legibilidad
  /// en el acta de certificación (Ej: A1B2C3D4 E5F6A7B8 ...).
  static String formatearHash(String hashRaw) {
    final buffer = StringBuffer();
    for (var i = 0; i < hashRaw.length; i += 8) {
      if (i > 0) buffer.write(' ');
      final end = (i + 8 < hashRaw.length) ? i + 8 : hashRaw.length;
      buffer.write(hashRaw.substring(i, end));
    }
    return buffer.toString();
  }
}
